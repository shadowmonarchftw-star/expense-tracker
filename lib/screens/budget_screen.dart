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

          return Column(
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Budget',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pie_chart, color: Colors.white),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
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
                        children: [
                          _buildRow('Total Income', currencyFormat.format(totalIncome)),
                          const Divider(height: 24),
                          _buildRow('Fixed Expenses', currencyFormat.format(fixedExpenses), color: const Color(0xFFFF6B6B)),
                          _buildRow('Allocated', currencyFormat.format(allocated), color: Colors.orange),
                          const Divider(height: 24),
                          _buildRow('Remaining to Budget', currencyFormat.format(remaining), color: remaining >= 0 ? const Color(0xFF00C4B4) : const Color(0xFFFF6B6B), bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text('Budget Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 16),
                    
                    ...currentBudgets.map((budget) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(budget.category, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currencyFormat.format(budget.amount), 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00C4B4), fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        onTap: () => _showAddBudgetDialog(context, budget: budget),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        backgroundColor: const Color(0xFF00C4B4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF1A1A1A))),
          Text(
            value,
            style: TextStyle(
              color: color ?? const Color(0xFF1A1A1A),
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
