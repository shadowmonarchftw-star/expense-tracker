import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as models;
import '../models/budget.dart';
import '../models/fixed_expense.dart';
import '../models/user_settings.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const _databaseVersion = 3; // New: Database version constant
  static const _databaseName = 'expense_tracker.db'; // New: Database name constant

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase(); // Changed to _initDatabase
    return _database!;
  }

  Future<Database> _initDatabase() async { // Renamed from _initDB
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName); // Using _databaseName

    return await openDatabase(
      path,
      version: _databaseVersion, // Using _databaseVersion
      onCreate: _onCreate, // Renamed from _createDB
      onUpgrade: _onUpgrade, // Handle migration
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN subCategory TEXT');
    }
    
    // New: Handle upgrade to version 3
    if (oldVersion < 3) {
      // Version 3: Add isDarkMode to settings table
      // Check if column exists first to be safe, or just try add
      try {
        await db.execute('ALTER TABLE settings ADD COLUMN isDarkMode INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist if dev did something weird, ignore
        print("Column isDarkMode might already exist: $e");
      }
    }
  }

  Future _onCreate(Database db, int version) async { // Renamed from _createDB
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

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
        isDarkMode INTEGER DEFAULT 0 -- New: Added isDarkMode column
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

  Future close() async {
    final db = await database;
    db.close();
  }
}
