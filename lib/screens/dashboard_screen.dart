import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

import '../widgets/app_drawer.dart'; // Import drawer

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
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
          final currencyFormat = NumberFormat.currency(symbol: provider.settings.currency);
          return Column(
            children: [
              // Gradient Header with Greeting
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 30), // Adjusted padding
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C4B4), Color(0xFF008F84)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${AuthService().currentUser?.displayName?.split(' ').first ?? 'User'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your Balance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currencyFormat.format(balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Income/Expense Cards
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Income',
                            amount: currencyFormat.format(totalIncome),
                            color: const Color(0xFF4CAF50),
                            icon: Icons.arrow_downward,
                            bgColor: const Color(0xFFF0FFF4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Expenses',
                            amount: currencyFormat.format(totalExpense),
                            color: const Color(0xFFFF6B6B),
                            icon: Icons.arrow_upward,
                            bgColor: const Color(0xFFFFF0F0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (monthTransactions.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Icon(Icons.receipt_long, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text("No recent activity", style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      ),

                    ...monthTransactions.take(5).map((t) {
                      final isExpense = t.type == 'expense';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isExpense ? const Color(0xFFFFF0F0) : const Color(0xFFF0FFF4),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                isExpense ? Icons.shopping_bag_outlined : Icons.attach_money,
                                color: isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.category,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat.MMMd().format(t.timestamp),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat.format(t.amount),
                              style: TextStyle(
                                color: isExpense ? const Color(0xFF1A1A1A) : const Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
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
  final IconData icon;
  final Color bgColor;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
