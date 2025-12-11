import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as models;
import '../models/budget.dart';
import '../models/fixed_expense.dart';
import '../models/fixed_expense.dart';
import '../models/user_settings.dart';
import '../models/goal.dart' as models;
import '../models/goal.dart' as models;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const _databaseVersion = 9; // Bump version for migration fix

  static const _databaseName = 'expense_tracker.db';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase(); 
    return _database!;
  }

  Future<Database> _initDatabase() async { 
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName); 

    return await openDatabase(
      path,
      version: _databaseVersion, 
      onCreate: _onCreate, 
      onUpgrade: _onUpgrade, 
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN subCategory TEXT');
    }
    
    // New: Handle upgrade to version 3
    if (oldVersion < 3) {
      // Version 3: Add isDarkMode to settings table
      try {
        await db.execute('ALTER TABLE settings ADD COLUMN isDarkMode INTEGER DEFAULT 0');
      } catch (e) {
        print("Column isDarkMode might already exist: $e");
      }
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          targetAmount REAL NOT NULL,
          savedAmount REAL NOT NULL,
          color INTEGER NOT NULL,
          icon INTEGER NOT NULL,
          notes TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
       try {
         await db.execute('ALTER TABLE goals ADD COLUMN lastUpdated TEXT');
       } catch (_) {}
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goal_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goalId TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          notes TEXT
        )
      ''');
      
      // Migration: Create initial transaction for existing goals
      try {
        final existingGoals = await db.query('goals');
        for (var goal in existingGoals) {
          final savedAmount = (goal['savedAmount'] as num?)?.toDouble() ?? 0.0;
          if (savedAmount > 0) {
            final goalId = goal['id'].toString();
            final lastUpdated = goal['lastUpdated'] as String? ?? DateTime.now().toIso8601String();
            
            await db.insert('goal_transactions', {
              'goalId': goalId,
              'amount': savedAmount,
              'date': lastUpdated,
              'notes': 'Initial Balance'
            });
          }
        }
      } catch (e) {
        print("Migration Error: $e");
      }
    }
    if (oldVersion < 7) {
       try {
         await db.execute('ALTER TABLE goals ADD COLUMN lastAddedAmount REAL');
       } catch (_) {}
    }
    if (oldVersion < 8) {
       try {
         await db.execute('ALTER TABLE settings ADD COLUMN isDailyReminderEnabled INTEGER DEFAULT 0');
       } catch (_) {}
    }
    
    // Fix: Ensure initial transactions exist if migration failed previously
    if (oldVersion < 9) {
      try {
        final existingGoals = await db.query('goals');
        for (var goal in existingGoals) {
          final goalId = goal['id'].toString();
          final savedAmount = (goal['savedAmount'] as num?)?.toDouble() ?? 0.0;
          
          if (savedAmount > 0) {
            final txCount = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM goal_transactions WHERE goalId = ?', 
              [goalId]
            ));
            
            if ((txCount ?? 0) == 0) {
               final lastUpdated = goal['lastUpdated'] as String? ?? DateTime.now().toIso8601String();
               await db.insert('goal_transactions', {
                  'goalId': goalId,
                  'amount': savedAmount,
                  'date': lastUpdated,
                  'notes': 'Initial Balance'
               });
            }
          }
        }
      } catch (e) {
        print("Migration v9 Error: $e");
      }
    }
  }

  Future _onCreate(Database db, int version) async { // Renamed from _createDB
    // ... existing tables ...
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    
    // ... (transactions, budgets, fixed_expenses, settings) ...
    // Note: I will only show the modified parts in ReplaceFileContent to keep it efficient.
    // Wait, the tool requires contextual replacement.
    
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        timestamp $textType,
        amount $realType,
        category $textType,
        subCategory TEXT,
        type $textType,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id $idType,
        category $textType,
        amount $realType,
        month $intType,
        year $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE fixed_expenses (
        id $idType,
        name $textType,
        amount $realType
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id $idType,
        salary $realType,
        currencyCode $textType,
        isDarkMode INTEGER DEFAULT 0,
        isDailyReminderEnabled INTEGER DEFAULT 0
      )
    ''');
    
    // New Goals Table with lastUpdated
    await db.execute('''
      CREATE TABLE goals (
        id $idType,
        name $textType,
        targetAmount $realType,
        savedAmount $realType,
        color $intType,
        icon $intType,
        notes TEXT,
        lastUpdated TEXT,
        lastAddedAmount REAL
      )
    ''');

    // New Goal Transactions Table
    await db.execute('''
      CREATE TABLE goal_transactions (
        id $idType,
        goalId $textType,
        amount $realType,
        date $textType,
        notes TEXT
      )
    ''');
  }

  // Transaction CRUD
  Future<int> createTransaction(models.Transaction transaction) async {
    final db = await database;
    // Remove ID from map if it's null or we want auto-increment
    // Since we are creating in SQLite, we let SQLite generate the ID.
    // The model might have a null ID.
    final map = transaction.toMap();
    if (map['id'] == null) {
      map.remove('id');
    } else {
      // If ID is present (e.g. string "1"), parse it to Int if possible, else remove it (if it's a UUID)
      // Since this is SQLite, we can only store Int IDs in the ID column.
      // If we are syncing FROM cloud to local, and cloud has "abc", we can't store it in ID.
      // We made a decision: Local SQLite is purely for local-created data or offline cache for "legacy" data. 
      // Cloud data will NOT be saved to SQLite ID column if the ID is non-numeric.
      // For now, let's assume we are just fixing compilation for existing logic.
      try {
        map['id'] = int.parse(map['id']);
      } catch (e) {
        map.remove('id'); // Cannot save non-numeric ID to this column
      }
    }
    return await db.insert('transactions', map);
  }

  Future<List<models.Transaction>> readAllTransactions() async {
    final db = await database;
    final result = await db.query('transactions', orderBy: 'timestamp DESC');
    return result.map((json) => models.Transaction.fromMap(json)).toList();
  }

  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    if (transaction.id == null) return 0;
    try {
      final intId = int.parse(transaction.id!);
      final map = transaction.toMap();
      map['id'] = intId; // Ensure it's passed as int
      return db.update(
        'transactions',
        map,
        where: 'id = ?',
        whereArgs: [intId],
      );
    } catch (e) {
      return 0; // Cannot update item with non-numeric ID in SQLite
    }
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    try {
      final intId = int.parse(id);
      return await db.delete('transactions', where: 'id = ?', whereArgs: [intId]);
    } catch (e) {
      return 0;
    }
  }

  // Budget CRUD
  Future<int> createBudget(Budget budget) async {
    final db = await database;
    final map = budget.toMap();
    if (map['id'] == null) {
      map.remove('id');
    } else {
       try { map['id'] = int.parse(map['id']); } catch(e) { map.remove('id'); }
    }
    return await db.insert('budgets', map);
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    if (budget.id == null) return 0;
    try {
       final intId = int.parse(budget.id!);
       final map = budget.toMap();
       map['id'] = intId;
       return await db.update(
        'budgets',
        map,
        where: 'id = ?',
        whereArgs: [intId],
      );
    } catch (e) { return 0; }
  }

  Future<List<Budget>> readAllBudgets() async {
    final db = await database;
    final result = await db.query('budgets');
    return result.map((json) => Budget.fromMap(json)).toList();
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    try {
      final intId = int.parse(id);
      return await db.delete('budgets', where: 'id = ?', whereArgs: [intId]);
    } catch (e) { return 0; }
  }

  // Fixed Expense CRUD
  Future<int> createFixedExpense(FixedExpense expense) async {
    final db = await database;
     final map = expense.toMap();
    if (map['id'] == null) {
      map.remove('id');
    } else {
       try { map['id'] = int.parse(map['id']); } catch(e) { map.remove('id'); }
    }
    return await db.insert('fixed_expenses', map);
  }

  Future<List<FixedExpense>> readAllFixedExpenses() async {
    final db = await database;
    final result = await db.query('fixed_expenses');
    return result.map((json) => FixedExpense.fromMap(json)).toList();
  }

  Future<int> updateFixedExpense(FixedExpense expense) async {
    final db = await database;
    if (expense.id == null) return 0;
    try {
      final intId = int.parse(expense.id!);
      final map = expense.toMap();
      map['id'] = intId;
      return await db.update(
        'fixed_expenses',
        map,
        where: 'id = ?',
        whereArgs: [intId],
      );
    } catch (e) { return 0; }
  }

  Future<int> deleteFixedExpense(String id) async {
    final db = await database;
    try {
      final intId = int.parse(id);
      return await db.delete('fixed_expenses', where: 'id = ?', whereArgs: [intId]);
    } catch (e) { return 0; }
  }

  // Settings
  Future<int> createOrUpdateSettings(UserSettings settings) async {
    final db = await database;
    final existing = await db.query('settings');
    final map = settings.toMap();
    // Settings usually doesn't strictly need ID manipulation if we query by existence, but for safety:
    map.remove('id'); // Settings ID is auto-managed
    
    if (existing.isEmpty) {
      return await db.insert('settings', map);
    } else {
      return await db.update('settings', map, where: 'id = ?', whereArgs: [existing.first['id']]);
    }
  }

  Future<UserSettings?> readSettings() async {
    final db = await database;
    final result = await db.query('settings', limit: 1);
    if (result.isNotEmpty) {
      return UserSettings.fromMap(result.first);
    }
    return null;
  }

  // Goals CRUD
  Future<int> createGoal(models.Goal goal) async {
    final db = await database;
    final map = goal.toMap();
    if (map['id'] == null) {
      map.remove('id');
    } else {
       try { map['id'] = int.parse(map['id']); } catch(e) { map.remove('id'); }
    }
    return await db.insert('goals', map);
  }

  Future<List<models.Goal>> readAllGoals() async {
    final db = await database;
    final result = await db.query('goals', orderBy: 'lastUpdated DESC'); 
    return result.map((json) => models.Goal.fromMap(json)).toList();
  }

  // --- Goal Transactions ---
  // Using imported 'goal_transaction.dart' as goal_model for now?
  // Need to import it at top of file, but I can't edit imports easily with this tool if they are at top.
  // I will assume I need to handle Map logic here or standard CRUD.
  // Wait, I can just use Map<String, dynamic> output or add proper import later.
  // Let's rely on Map for internal helper usage or raw queries.
  
  Future<List<Map<String, dynamic>>> readGoalTransactions(String goalId) async {
    final db = await database;
    return await db.query('goal_transactions', where: 'goalId = ?', whereArgs: [goalId], orderBy: 'date DESC');
  }

  Future<int> createGoalTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    final map = Map<String, dynamic>.from(transaction); // Copy
    if (map['id'] == null) {
      map.remove('id');
    }
    return await db.insert('goal_transactions', map);
  }

  Future<int> updateGoalTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.update(
      'goal_transactions',
      transaction,
      where: 'id = ?',
      whereArgs: [transaction['id']],
    );
  }

  Future<int> deleteGoalTransaction(String id) async {
    final db = await database;
    return await db.delete('goal_transactions', where: 'id = ?', whereArgs: [id]);
  }


  Future<int> updateGoal(models.Goal goal) async {
    final db = await database;
    if (goal.id == null) return 0;
    try {
      final intId = int.parse(goal.id!);
      final map = goal.toMap();
      map['id'] = intId;
      return await db.update(
        'goals',
        map,
        where: 'id = ?',
        whereArgs: [intId],
      );
    } catch (e) { return 0; }
  }

  Future<int> deleteGoal(String id) async {
    final db = await database;
    try {
      final intId = int.parse(id);
      return await db.delete('goals', where: 'id = ?', whereArgs: [intId]);
    } catch (e) { return 0; }
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
