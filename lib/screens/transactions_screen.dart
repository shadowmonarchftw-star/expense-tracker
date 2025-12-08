import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final currencyFormat = NumberFormat.currency(symbol: provider.settings.currencyCode);
          
          return Column(
            children: [
              // Budget Summary Section
              if (provider.budgets.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.budgets.length,
                    itemBuilder: (context, index) {
                      final budget = provider.budgets[index];
                      final spent = provider.getSpentAmountForCategory(budget.category);
                      final progress = (spent / budget.amount).clamp(0.0, 1.0);
                      
                      return SizedBox(
                        width: 160,
                        child: Card(
                          margin: const EdgeInsets.only(right: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(budget.category, 
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[200],
                                  color: progress > 0.9 ? Colors.red : Colors.blue,
                                ),
                                const SizedBox(height: 8),
                                Text('${currencyFormat.format(spent)} / ${currencyFormat.format(budget.amount)}',
                                  style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              const Divider(height: 1),

              // Transaction List
              Expanded(
                child: ListView.builder(
                  itemCount: provider.transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = provider.transactions[index];
                    return Dismissible(
                      key: Key(transaction.id.toString()),
                      onDismissed: (_) => provider.deleteTransaction(transaction.id!),
                      background: Container(color: Colors.red),
                      child: ListTile(
                        title: Text(transaction.subCategory.isNotEmpty 
                            ? '${transaction.category} - ${transaction.subCategory}'
                            : transaction.category),
                        subtitle: Text(DateFormat.yMMMd().format(transaction.timestamp)),
                        trailing: Text(
                          currencyFormat.format(transaction.amount),
                          style: TextStyle(
                            color: transaction.type == 'income' ? Colors.green : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    String category = '';
    String subCategory = '';
    String amountText = '';
    String type = 'expense';
    
    // Get categories from budgets for expenses
    final budgetCategories = provider.budgets.map((b) => b.category).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Calculate progress if category is selected
          double? budgetAmount;
          double? spentAmount;
          double? progress; // 0.0 to 1.0

          if (category.isNotEmpty && type == 'expense') {
            try {
              final budget = provider.budgets.firstWhere((b) => b.category == category);
              budgetAmount = budget.amount;
              spentAmount = provider.getSpentAmountForCategory(category);
              progress = (spentAmount / budgetAmount).clamp(0.0, 1.0);
            } catch (e) {
              // Handle case where budget might be missing but category exists
            }
          }

          return AlertDialog(
            title: const Text('Add Transaction'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Expense')),
                      ButtonSegment(value: 'income', label: Text('Income')),
                    ],
                    selected: {type},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        type = newSelection.first;
                        category = ''; // Reset category on type change
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => amountText = value,
                  ),
                  const SizedBox(height: 16),
                  
                  if (type == 'expense') ...[
                    if (budgetCategories.isEmpty)
                      const Text('No budgets defined. Please create a budget first.', 
                        style: TextStyle(color: Colors.red)),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category (from Budget)'),
                      value: category.isEmpty ? null : category,
                      items: budgetCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (value) {
                        setState(() {
                          category = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Sub-category (Optional)'),
                      onChanged: (value) => subCategory = value,
                    ),
                    
                    if (category.isNotEmpty && budgetAmount != null) ...[
                      const SizedBox(height: 20),
                      Text('Budget Usage: ${((progress ?? 0) * 100).toStringAsFixed(1)}%'),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: (progress ?? 0) > 0.9 ? Colors.red : Colors.blue,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 5),
                      Text('${spentAmount!.toStringAsFixed(0)} / ${budgetAmount!.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ] else
                    TextField(
                      decoration: const InputDecoration(labelText: 'Source'),
                      onChanged: (value) => category = value,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final amount = int.tryParse(amountText);
                  if (amount != null && amount > 0 && category.isNotEmpty) {
                    provider.addTransaction(Transaction(
                      timestamp: DateTime.now(),
                      amount: amount.toDouble(),
                      category: category,
                      subCategory: subCategory,
                      type: type,
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
