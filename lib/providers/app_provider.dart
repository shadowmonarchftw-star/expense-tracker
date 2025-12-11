import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Direct dependency for stream
import 'dart:async';
import '../database/database_helper.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/fixed_expense.dart';
import '../models/user_settings.dart';

class AppProvider with ChangeNotifier {
  final _db = DatabaseHelper.instance;
  FirestoreService? _firestoreService;
  StreamSubscription? _authSubscription;
  
  // Stream Subscriptions
  StreamSubscription? _transSubscription;
  StreamSubscription? _budgetSubscription;
  StreamSubscription? _expenseSubscription;
  StreamSubscription? _settingsSubscription;

  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<FixedExpense> _fixedExpenses = [];
  UserSettings? _settings;

  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<FixedExpense> get fixedExpenses => _fixedExpenses;
  UserSettings get settings => _settings ?? UserSettings(salary: 0);

  bool get isSynced => _firestoreService != null;
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  
  void setTabIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
  
  ThemeMode get themeMode {
    if (_settings == null) return ThemeMode.system;
    return _settings!.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
  
  Future<void> toggleTheme(bool isDark) async {
    final currentSettings = settings;
    final newSettings = UserSettings(
      id: currentSettings.id,
      salary: currentSettings.salary,
      currency: currentSettings.currency,
      isDarkMode: isDark,
      isBiometricEnabled: currentSettings.isBiometricEnabled,
      calendarSystem: currentSettings.calendarSystem,
    );
    await updateSettings(newSettings);
  }

  Future<void> toggleBiometric(bool isEnabled) async {
    final currentSettings = settings;
    final newSettings = UserSettings(
      id: currentSettings.id,
      salary: currentSettings.salary,
      currency: currentSettings.currency,
      isDarkMode: currentSettings.isDarkMode,
      isBiometricEnabled: isEnabled,
      calendarSystem: currentSettings.calendarSystem,
    );
    await updateSettings(newSettings);
  }

  bool get isNepaliDate => settings.calendarSystem == 'BS';

  Future<void> toggleCalendar(String system) async {
    final currentSettings = settings;
    final newSettings = UserSettings(
      id: currentSettings.id,
      salary: currentSettings.salary,
      currency: currentSettings.currency,
      isDarkMode: currentSettings.isDarkMode,
      isBiometricEnabled: currentSettings.isBiometricEnabled,
      calendarSystem: system,
    );
    await updateSettings(newSettings);
  }

  AppProvider() {
    _init();
  }

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _firestoreService = FirestoreService(uid: user.uid);
        _initFirestore(user.uid);
      } else {
        _firestoreService = null;
        _cancelSubscriptions();
        loadLocalData();
      }
    });
  }
  
  void _cancelSubscriptions() {
    _transSubscription?.cancel();
    _budgetSubscription?.cancel();
    _expenseSubscription?.cancel();
    _settingsSubscription?.cancel();
  }

  Future<void> _initFirestore(String uid) async {
    if (_firestoreService == null) return;
    
    // Listen with Error Handling
    _transSubscription = _firestoreService!.streamTransactions().listen((data) {
      _transactions = data;
      notifyListeners();
    }, onError: (e) => print("Firestore Transaction Error: $e"));

    _budgetSubscription = _firestoreService!.streamBudgets().listen((data) {
      _budgets = data;
      notifyListeners();
    }, onError: (e) => print("Firestore Budget Error: $e"));

    _expenseSubscription = _firestoreService!.streamFixedExpenses().listen((data) {
      _fixedExpenses = data;
      notifyListeners();
    }, onError: (e) => print("Firestore Expense Error: $e"));

    _settingsSubscription = _firestoreService!.streamSettings().listen((data) {
      _settings = data;
      notifyListeners();
    }, onError: (e) => print("Firestore Settings Error: $e"));

    
    _isLoading = false;
    notifyListeners();

    _checkAndMigrate();
  }
  
  Future<void> _checkAndMigrate() async {
    // Migration Logic
    // We only migrate if cloud is effectively empty (heuristic: 0 salary)
    // AND we have local transactions.
    // This is "best effort".
    try {
      final localTrans = await _db.readAllTransactions();
      if (localTrans.isEmpty) return; 

      // We wait briefly for the settings stream to potentially fire
      await Future.delayed(const Duration(seconds: 2));
      
      if (_settings == null || _settings?.salary == 0) {
         print("Starting Migration...");
         // Avoid duplicates by checking IDs
         for (var t in localTrans) {
           // Basic check: if ID doesn't exist in current loaded list (which should be empty or partial)
           if (!_transactions.any((ct) => ct.id == t.id.toString())) {
             await _firestoreService?.addTransaction(t);
           }
         }
         
         final localBudgets = await _db.readAllBudgets();
         for (var b in localBudgets) {
            if (!_budgets.any((cb) => cb.id == b.id.toString())) {
               await _firestoreService?.addBudget(b);
            }
         }
         
         final localExpenses = await _db.readAllFixedExpenses();
         for (var e in localExpenses) {
            if (!_fixedExpenses.any((ce) => ce.id == e.id.toString())) {
               await _firestoreService?.addFixedExpense(e);
            }
         }
         
         final localSettings = await _db.readSettings();
         if (localSettings != null) {
           await _firestoreService?.updateSettings(localSettings);
         }
         print("Migration Complete");
      }
    } catch (e) {
      print("Migration Failed: $e");
    }
  }

  Future<void> loadLocalData() async {
    _transactions = await _db.readAllTransactions();
    _budgets = await _db.readAllBudgets();
    _fixedExpenses = await _db.readAllFixedExpenses();
    _fixedExpenses = await _db.readAllFixedExpenses();
    _settings = await _db.readSettings();
    _isLoading = false;
    notifyListeners();
  }

  // CRUD Operations with Optimistic Updates
  // When synced, we update the local list IMMEDIATELY so the UI doesn't freeze.
  // Then we sync to cloud. If cloud fails, the stream (or error handler) deals with it.
  
  Future<void> addTransaction(Transaction transaction) async {
    if (isSynced) {
      // Optimistic Update
      _transactions.insert(0, transaction); 
      notifyListeners();
      try {
        await _firestoreService!.addTransaction(transaction);
      } catch (e) {
        print("Add Transaction Error: $e");
        // Revert (optional, or keep retry logic) - For now simplified
        // The stream will eventually correct this if it reconnects
      }
    } else {
      await _db.createTransaction(transaction);
      await loadLocalData();
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (isSynced) {
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      try {
        await _firestoreService!.deleteTransaction(id);
      } catch (e) {
        print("Delete Transaction Error: $e");
      }
    } else {
      await _db.deleteTransaction(id);
      await loadLocalData();
    }
  }

  Future<void> addBudget(Budget budget) async {
    if (isSynced) {
      _budgets.add(budget);
      notifyListeners();
      try {
        await _firestoreService!.addBudget(budget);
      } catch (e) {
        print("Add Budget Error: $e");
      }
    } else {
      await _db.createBudget(budget);
      await loadLocalData();
    }
  }

  Future<void> deleteBudget(String id) async {
    if (isSynced) {
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
      try {
        await _firestoreService!.deleteBudget(id);
      } catch (e) {
        print("Delete Budget Error: $e");
      }
    } else {
      await _db.deleteBudget(id);
      await loadLocalData();
    }
  }

  Future<void> updateBudget(Budget budget) async {
    if (isSynced) {
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        _budgets[index] = budget;
        notifyListeners();
      }
      try {
        await _firestoreService!.updateBudget(budget);
      } catch (e) {
        print("Update Budget Error: $e");
      }
    } else {
      await _db.updateBudget(budget);
      await loadLocalData();
    }
  }

  Future<void> addFixedExpense(FixedExpense expense) async {
    if (isSynced) {
       _fixedExpenses.add(expense);
       notifyListeners();
       try {
         await _firestoreService!.addFixedExpense(expense);
       } catch (e) { print("Add Expense Error: $e"); }
    } else {
      await _db.createFixedExpense(expense);
      await loadLocalData();
    }
  }

  Future<void> updateFixedExpense(FixedExpense expense) async {
    if (isSynced) {
       final index = _fixedExpenses.indexWhere((e) => e.id == expense.id);
       if (index != -1) {
         _fixedExpenses[index] = expense;
         notifyListeners();
       }
       try {
         await _firestoreService!.updateFixedExpense(expense);
       } catch (e) { print("Update Expense Error: $e"); }
    } else {
      await _db.updateFixedExpense(expense);
      await loadLocalData();
    }
  }

  Future<void> deleteFixedExpense(String id) async {
    if (isSynced) {
      _fixedExpenses.removeWhere((e) => e.id == id);
      notifyListeners();
      try {
        await _firestoreService!.deleteFixedExpense(id);
      } catch(e) { print("Delete Expense Error: $e"); }
    } else {
      await _db.deleteFixedExpense(id);
      await loadLocalData();
    }
  }

  Future<void> updateSettings(UserSettings settings) async {
    if (isSynced) {
      _settings = settings;
      notifyListeners();
      try {
        await _firestoreService!.updateSettings(settings);
      } catch (e) { print("Update Settings Error: $e"); }
    } else {
      await _db.createOrUpdateSettings(settings);
      await loadLocalData();
    }
  }

  double getSpentAmountForCategory(String category) {
    return _transactions
        .where((t) => t.category == category && t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelSubscriptions();
    super.dispose();
  }
}
