import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();
          final currentMonth = now.month;
          final currentYear = now.year;
          
          final monthTransactions = provider.transactions.where((t) {
            return t.timestamp.month == currentMonth && t.timestamp.year == currentYear;
          }).toList();
          
          final totalIncome = provider.settings.salary +
              monthTransactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
          
          final fixedExpenses = provider.fixedExpenses.fold(0.0, (sum, e) => sum + e.amount);
          final variableExpenses = monthTransactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);
          final totalExpense = fixedExpenses + variableExpenses;
          
          final balance = totalIncome - totalExpense;
          final currencyFormat = NumberFormat.currency(symbol: provider.settings.currencyCode);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Income',
                      amount: currencyFormat.format(totalIncome),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Expenses',
                      amount: currencyFormat.format(totalExpense),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Balance',
                amount: currencyFormat.format(balance),
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...monthTransactions.take(5).map((t) => ListTile(
                title: Text(t.category),
                subtitle: Text(DateFormat.MMMd().format(t.timestamp)),
                trailing: Text(
                  currencyFormat.format(t.amount),
                  style: TextStyle(
                    color: t.type == 'income' ? Colors.green : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
