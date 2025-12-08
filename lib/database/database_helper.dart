import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as models;
import '../models/budget.dart';
import '../models/fixed_expense.dart';
import '../models/user_settings.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Increment version
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // Handle migration
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN subCategory TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
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
        currencyCode $textType
      )
    ''');
  }

  // Transaction CRUD
  Future<int> createTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<models.Transaction>> readAllTransactions() async {
    final db = await database;
    final result = await db.query('transactions', orderBy: 'timestamp DESC');
    return result.map((json) => models.Transaction.fromMap(json)).toList();
  }

  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Budget CRUD
  Future<int> createBudget(Budget budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<List<Budget>> readAllBudgets() async {
    final db = await database;
    final result = await db.query('budgets');
    return result.map((json) => Budget.fromMap(json)).toList();
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // Fixed Expense CRUD
  Future<int> createFixedExpense(FixedExpense expense) async {
    final db = await database;
    return await db.insert('fixed_expenses', expense.toMap());
  }

  Future<List<FixedExpense>> readAllFixedExpenses() async {
    final db = await database;
    final result = await db.query('fixed_expenses');
    return result.map((json) => FixedExpense.fromMap(json)).toList();
  }

  Future<int> deleteFixedExpense(int id) async {
    final db = await database;
    return await db.delete('fixed_expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Settings
  Future<int> createOrUpdateSettings(UserSettings settings) async {
    final db = await database;
    final existing = await db.query('settings');
    if (existing.isEmpty) {
      return await db.insert('settings', settings.toMap());
    } else {
      return await db.update('settings', settings.toMap(), where: 'id = ?', whereArgs: [existing.first['id']]);
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
