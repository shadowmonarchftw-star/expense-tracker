import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/budget.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();
          final currentMonth = now.month;
          final currentYear = now.year;
          
          final currentBudgets = provider.budgets.where((b) => b.month == currentMonth && b.year == currentYear).toList();
          final currencyFormat = NumberFormat.currency(symbol: provider.settings.currencyCode);
          
          final totalIncome = provider.settings.salary;
          final fixedExpenses = provider.fixedExpenses.fold(0.0, (sum, e) => sum + e.amount);
          final allocated = currentBudgets.fold(0.0, (sum, b) => sum + b.amount);
          final remaining = totalIncome - fixedExpenses - allocated;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildRow('Total Income', currencyFormat.format(totalIncome)),
                      _buildRow('Fixed Expenses', currencyFormat.format(fixedExpenses), color: Colors.red),
                      _buildRow('Allocated', currencyFormat.format(allocated), color: Colors.orange),
                      const Divider(),
                      _buildRow('Remaining to Budget', currencyFormat.format(remaining), color: remaining >= 0 ? Colors.green : Colors.red, bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...currentBudgets.map((budget) => ListTile(
                title: Text(budget.category),
                trailing: Text(currencyFormat.format(budget.amount)),
                onTap: () => _showAddBudgetDialog(context, budget: budget),
              )),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, {Budget? budget}) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    String category = budget?.category ?? '';
    String amountText = budget?.amount.toStringAsFixed(0) ?? '';
    final now = DateTime.now();
    final isEditing = budget != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Budget' : 'Add Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Category'),
              controller: TextEditingController(text: category),
              onChanged: (value) => category = value,
              enabled: !isEditing, // Lock category when editing to prevent duplicates logic issues
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Amount'),
              controller: TextEditingController(text: amountText),
              keyboardType: TextInputType.number,
              onChanged: (value) => amountText = value,
            ),
          ],
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
                if (isEditing) {
                  provider.updateBudget(Budget(
                    id: budget.id,
                    category: category,
                    amount: amount.toDouble(),
                    month: budget.month,
                    year: budget.year,
                  ));
                } else {
                  provider.addBudget(Budget(
                    category: category,
                    amount: amount.toDouble(),
                    month: now.month,
                    year: now.year,
                  ));
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
