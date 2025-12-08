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
          
          return ListView.builder(
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) {
              final transaction = provider.transactions[index];
              return Dismissible(
                key: Key(transaction.id.toString()),
                onDismissed: (_) => provider.deleteTransaction(transaction.id!),
                background: Container(color: Colors.red),
                child: ListTile(
                  title: Text(transaction.category),
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
    String amountText = '';
    String type = 'expense';
    
    final categories = [
      'Office Eating Out',
      'Apartment Expenses',
      'Fuel',
      'Groceries',
      'Transportation',
      'Entertainment',
      'Healthcare',
      'Shopping',
      'Utilities',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: Column(
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
              if (type == 'expense')
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (value) => category = value ?? '',
                )
              else
                TextField(
                  decoration: const InputDecoration(labelText: 'Source'),
                  onChanged: (value) => category = value,
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
                  provider.addTransaction(Transaction(
                    timestamp: DateTime.now(),
                    amount: amount.toDouble(),
                    category: category,
                    type: type,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
