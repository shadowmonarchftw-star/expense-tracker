import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../services/auth_service.dart';

import '../widgets/app_drawer.dart'; // Import drawer
import '../widgets/transaction_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final isNepali = provider.isNepaliDate;
          final currentYear = isNepali ? NepaliDateTime.now().year : DateTime.now().year;
          final currentMonth = isNepali ? NepaliDateTime.now().month : DateTime.now().month;
          
          final monthTransactions = provider.transactions.where((t) {
            if (isNepali) {
              final nDt = NepaliDateTime.fromDateTime(t.timestamp);
              return nDt.year == currentYear && nDt.month == currentMonth;
            }
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
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
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
                    // Top Row: Menu and Profile/Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                             provider.isNepaliDate 
                               ? NepaliDateFormat.yMMMd().format(NepaliDateTime.now())
                               : DateFormat.yMMMd().format(DateTime.now()),
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Greeting Section
                    // Greeting Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${AuthService().currentUser?.displayName?.split(' ').first ?? 'User'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text("Save Up", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.savings, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Balance Section
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0, 
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Chart Section
                    TransactionChart(transactions: provider.transactions),

                    // Income/Expense Cards
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Income',
                            amount: currencyFormat.format(totalIncome),
                            color: const Color(0xFF4CAF50),
                            icon: Icons.arrow_downward,
                            bgColor: const Color(0xFF4CAF50), // Pass base color for opacity handling inside widget
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Expenses',
                            amount: currencyFormat.format(variableExpenses),
                            color: const Color(0xFFFF6B6B),
                            icon: Icons.arrow_upward,
                            bgColor: const Color(0xFFFF6B6B), // Pass base color for opacity handling inside widget
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // New Row: Goal Contribution & Fixed Expenses
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Goal Contribution',
                            amount: currencyFormat.format(
                              monthTransactions.where((t) => t.subCategory == 'Savings').fold(0.0, (sum, t) => sum + t.amount)
                            ),
                            color: const Color(0xFF00C4B4),
                            icon: Icons.savings,
                            bgColor: const Color(0xFF00C4B4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Fixed Expenses',
                            amount: currencyFormat.format(fixedExpenses),
                            color: Colors.orange,
                            icon: Icons.receipt_long,
                            bgColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
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
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                                color: (isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF4CAF50)).withOpacity(0.1),
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
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    provider.isNepaliDate
                                      ? NepaliDateFormat.MMMd().format(NepaliDateTime.fromDateTime(t.timestamp))
                                      : DateFormat.MMMd().format(t.timestamp),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat.format(t.amount),
                              style: TextStyle(
                                color: isExpense ? Theme.of(context).colorScheme.onSurface : const Color(0xFF4CAF50),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: bgColor.withOpacity(0.1), // Dynamic opacity
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
