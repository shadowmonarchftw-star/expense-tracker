import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_settings.dart';
import '../models/fixed_expense.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final currencyFormat = NumberFormat.currency(symbol: provider.settings.currencyCode);
          
          return ListView(
            children: [
              ListTile(
                title: const Text('Monthly Salary'),
                subtitle: Text(currencyFormat.format(provider.settings.salary)),
                trailing: const Icon(Icons.edit),
                onTap: () => _showEditSalaryDialog(context, provider),
              ),
              const Divider(),
              ListTile(
                title: const Text('Currency'),
                subtitle: Text(provider.settings.currencyCode),
                trailing: const Icon(Icons.edit),
                onTap: () => _showCurrencyDialog(context, provider),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Fixed Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...provider.fixedExpenses.map((expense) => ListTile(
                title: Text(expense.name),
                trailing: Text(currencyFormat.format(expense.amount)),
              )),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Fixed Expense'),
                onTap: () => _showAddFixedExpenseDialog(context, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSalaryDialog(BuildContext context, AppProvider provider) {
    String salaryText = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Salary'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Monthly Salary'),
          keyboardType: TextInputType.number,
          onChanged: (value) => salaryText = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final salary = int.tryParse(salaryText);
              if (salary != null && salary > 0) {
                provider.updateSettings(UserSettings(
                  salary: salary.toDouble(),
                  currencyCode: provider.settings.currencyCode,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, AppProvider provider) {
    final currencies = ['NPR', 'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'INR', 'CNY'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) => ListTile(
            title: Text(currency),
            onTap: () {
              provider.updateSettings(UserSettings(
                salary: provider.settings.salary,
                currencyCode: currency,
              ));
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showAddFixedExpenseDialog(BuildContext context, AppProvider provider) {
    String name = '';
    String amountText = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Fixed Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (value) => name = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              onChanged: (value) => amountText = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(amountText);
              if (amount != null && amount > 0 && name.isNotEmpty) {
                provider.addFixedExpense(FixedExpense(name: name, amount: amount.toDouble()));
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
