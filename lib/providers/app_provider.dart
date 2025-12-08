import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/fixed_expense.dart';
import '../models/user_settings.dart';

class AppProvider with ChangeNotifier {
  final _db = DatabaseHelper.instance;
  
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<FixedExpense> _fixedExpenses = [];
  UserSettings? _settings;

  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<FixedExpense> get fixedExpenses => _fixedExpenses;
  UserSettings get settings => _settings ?? UserSettings(salary: 0);

  AppProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _transactions = await _db.readAllTransactions();
    _budgets = await _db.readAllBudgets();
    _fixedExpenses = await _db.readAllFixedExpenses();
    _settings = await _db.readSettings();
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _db.createTransaction(transaction);
    await loadData();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    await loadData();
  }

  Future<void> addBudget(Budget budget) async {
    await _db.createBudget(budget);
    await loadData();
  }

  Future<void> deleteBudget(int id) async {
    await _db.deleteBudget(id);
    await loadData();
  }

  Future<void> updateBudget(Budget budget) async {
    await _db.updateBudget(budget);
    await loadData();
  }

  Future<void> addFixedExpense(FixedExpense expense) async {
    await _db.createFixedExpense(expense);
    await loadData();
  }

  Future<void> deleteFixedExpense(int id) async {
    await _db.deleteFixedExpense(id);
    await loadData();
  }

  Future<void> updateSettings(UserSettings settings) async {
    await _db.createOrUpdateSettings(settings);
    await loadData();
  }

  double getSpentAmountForCategory(String category) {
    // Filter transactions by category and sum amounts (only expenses)
    return _transactions
        .where((t) => t.category == category && t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
