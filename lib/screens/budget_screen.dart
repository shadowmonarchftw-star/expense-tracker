import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/budget.dart';
import 'package:intl/intl.dart';

import '../widgets/app_drawer.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();
          final currentMonth = now.month;
          final currentYear = now.year;
          
          final currentBudgets = provider.budgets.where((b) => b.month == currentMonth && b.year == currentYear).toList();
          
          final monthTransactions = provider.transactions.where((t) {
            return t.timestamp.month == currentMonth && t.timestamp.year == currentYear;
          }).toList();
          
          final currencyFormat = NumberFormat.currency(symbol: provider.settings.currency);
          
          final totalIncome = provider.settings.salary;
          final fixedExpenses = provider.fixedExpenses.fold(0.0, (sum, e) => sum + e.amount);
          final allocated = currentBudgets.fold(0.0, (sum, b) => sum + b.amount);
          final goalSavings = monthTransactions.where((t) => t.subCategory == 'Savings').fold(0.0, (sum, t) => sum + t.amount);
          final remaining = totalIncome - fixedExpenses - allocated - goalSavings;
          return Column(
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 24), // Adjusted padding
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
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'My Budget',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
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
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildRow(context, 'Total Income', currencyFormat.format(totalIncome)),
                          const Divider(height: 24),
                          _buildRow(context, 'Fixed Expenses', currencyFormat.format(fixedExpenses), color: const Color(0xFFFF6B6B)),
                          _buildRow(context, 'Allocated', currencyFormat.format(allocated), color: Colors.orange),
                          _buildRow(context, 'Goal Savings', currencyFormat.format(goalSavings), color: const Color(0xFF00C4B4)),
                          const Divider(height: 24),
                          _buildRow(context, 'Remaining to Budget', currencyFormat.format(remaining), color: remaining >= 0 ? const Color(0xFF00C4B4) : const Color(0xFFFF6B6B), bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text('Budget Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    
                    ...currentBudgets.map((budget) {
                      final spent = provider.getSpentAmountForCategory(budget.category);
                      final progress = (spent / budget.amount).clamp(0.0, 1.0);
                      final isOverBudget = spent > budget.amount;

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
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => _showAddBudgetDialog(context, budget: budget),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(budget.category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                                  Row(
                                    children: [
                                      Text(currencyFormat.format(budget.amount), 
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00C4B4), fontSize: 16)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  color: isOverBudget ? const Color(0xFFFF6B6B) : const Color(0xFF00C4B4),
                                  minHeight: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Spent: ${currencyFormat.format(spent)}',
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: isOverBudget ? const Color(0xFFFF6B6B) : Colors.grey,
                                      fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal
                                    )
                                  ),
                                  Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              
              const SizedBox(height: 80), // Bottom padding for FAB
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

  Widget _buildRow(BuildContext context, String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // Increased padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)), // Increased font
          Text(
            value,
            style: TextStyle(
              color: color ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500, // Make standard values a bit heavier too
              fontSize: 16, // Increased font
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
          if (isEditing)
            TextButton(
              onPressed: () {
                 showDialog(
                   context: context,
                   builder: (ctx) => AlertDialog(
                     title: const Text("Delete Budget?"),
                     content: Text("Delete budget for $category?"),
                     actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                       TextButton(onPressed: () {
                          provider.deleteBudget(budget!.id!);
                          Navigator.pop(ctx); // Close verify
                          Navigator.pop(context); // Close edit
                       }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
                     ],
                   )
                 );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
