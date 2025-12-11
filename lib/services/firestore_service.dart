import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart' as models;
import '../models/budget.dart';
import '../models/fixed_expense.dart';
import '../models/user_settings.dart';
import '../models/goal.dart' as models;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService({required this.uid});

  // Collection References
  CollectionReference get _usersRef => _db.collection('users');
  DocumentReference get _userDoc => _usersRef.doc(uid);
  CollectionReference get _transactionsRef => _userDoc.collection('transactions');
  CollectionReference get _budgetsRef => _userDoc.collection('budgets');
  CollectionReference get _fixedExpensesRef => _userDoc.collection('fixed_expenses');
  CollectionReference get _settingsRef => _userDoc.collection('settings');

  // --- Transactions ---
  Stream<List<models.Transaction>> streamTransactions() {
    return _transactionsRef.orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set from doc ID
        return models.Transaction.fromMap(data);
      }).toList();
    });
  }

  Future<void> addTransaction(models.Transaction transaction) async {
    // If ID is present (migrated id), use it. Else auto-gen.
    if (transaction.id != null) {
      await _transactionsRef.doc(transaction.id).set(transaction.toMap());
    } else {
      await _transactionsRef.add(transaction.toMap());
    }
  }

  Future<void> updateTransaction(models.Transaction transaction) async {
    if (transaction.id == null) return;
    await _transactionsRef.doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsRef.doc(id).delete();
  }

  // --- Budgets ---
  Stream<List<Budget>> streamBudgets() {
    return _budgetsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Budget.fromMap(data);
      }).toList();
    });
  }

  Future<void> addBudget(Budget budget) async {
    if (budget.id != null) {
      await _budgetsRef.doc(budget.id).set(budget.toMap());
    } else {
      await _budgetsRef.add(budget.toMap());
    }
  }

  Future<void> updateBudget(Budget budget) async {
    if (budget.id == null) return;
    await _budgetsRef.doc(budget.id).update(budget.toMap());
  }

  Future<void> deleteBudget(String id) async {
    await _budgetsRef.doc(id).delete();
  }

  // --- Fixed Expenses ---
  Stream<List<FixedExpense>> streamFixedExpenses() {
    return _fixedExpensesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FixedExpense.fromMap(data);
      }).toList();
    });
  }

  Future<void> addFixedExpense(FixedExpense expense) async {
    if (expense.id != null) {
      await _fixedExpensesRef.doc(expense.id).set(expense.toMap());
    } else {
      await _fixedExpensesRef.add(expense.toMap());
    }
  }

  Future<void> updateFixedExpense(FixedExpense expense) async {
     if (expense.id == null) return;
     await _fixedExpensesRef.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteFixedExpense(String id) async {
    await _fixedExpensesRef.doc(id).delete();
  }

  // --- Settings ---
  Stream<UserSettings> streamSettings() {
    return _settingsRef.doc('config').snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserSettings.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return UserSettings(salary: 0); // Default
    });
  }

  Future<void> updateSettings(UserSettings settings) async {
    await _settingsRef.doc('config').set(settings.toMap());
  }

  // --- Goals ---
  CollectionReference get _goalsRef => _userDoc.collection('goals');

  Stream<List<models.Goal>> streamGoals() {
    return _goalsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return models.Goal.fromMap(data);
      }).toList();
    });
  }

  Future<String> addGoal(models.Goal goal) async {
    if (goal.id != null) {
      await _goalsRef.doc(goal.id).set(goal.toMap());
      return goal.id!;
    } else {
      final ref = await _goalsRef.add(goal.toMap());
      return ref.id;
    }
  }

  Future<void> updateGoal(models.Goal goal) async {
    if (goal.id == null) return;
    await _goalsRef.doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteGoal(String id) async {
    await _goalsRef.doc(id).delete();
  }

  // --- Goal Transactions ---
  CollectionReference _getGoalTransactionsRef(String goalId) {
    return _userDoc.collection('goals').doc(goalId).collection('transactions');
  }

  Stream<List<Map<String, dynamic>>> streamGoalTransactions(String goalId) {
    return _getGoalTransactionsRef(goalId).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['goalId'] = goalId; // Ensure goalId context
        return data;
      }).toList();
    });
  }

  Future<void> addGoalTransaction(Map<String, dynamic> transaction) async {
    if (transaction['id'] != null) {
      await _getGoalTransactionsRef(transaction['goalId']).doc(transaction['id']).set(transaction);
    } else {
      await _getGoalTransactionsRef(transaction['goalId']).add(transaction);
    }
  }

  Future<void> updateGoalTransaction(Map<String, dynamic> transaction) async {
    if (transaction['id'] == null) return;
    await _getGoalTransactionsRef(transaction['goalId']).doc(transaction['id']).update(transaction);
  }

  Future<void> deleteGoalTransaction(String goalId, String id) async {
    await _getGoalTransactionsRef(goalId).doc(id).delete();
  }
}
