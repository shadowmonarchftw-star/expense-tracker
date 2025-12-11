
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/goal.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';

import 'package:fl_chart/fl_chart.dart';
import 'goal_detail_screen.dart';
// ... imports ...

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final currencyFormat = NumberFormat.currency(symbol: provider.settings.currency);

          // ... gradient header ...
          return Column(
            children: [
              // Custom Gradient Header
              Container(
                padding: const EdgeInsets.only(top: 50, left: 16, right: 20, bottom: 20),
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
                        'Financial Goals',
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
                      child: const Icon(Icons.flag, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Goals List
              Expanded(
                child: provider.goals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.track_changes, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              "Set your first goal!",
                              style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: provider.goals.length,
                        itemBuilder: (context, index) {
                          final goal = provider.goals[index];
                          final percentage = (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
                          final percentString = (percentage * 100).toStringAsFixed(0);
                          final isCompleted = percentage >= 1.0;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Donut Chart
                                    SizedBox(
                                      height: 100,
                                      width: 100,
                                      child: Stack(
                                        children: [
                                          PieChart(
                                            PieChartData(
                                              sections: [
                                                PieChartSectionData(
                                                  color: Color(goal.color),
                                                  value: goal.savedAmount,
                                                  radius: 12, // Increased thickness
                                                  showTitle: false,
                                                ),
                                                PieChartSectionData(
                                                  color: Colors.grey[200]!,
                                                  value: (goal.targetAmount - goal.savedAmount).clamp(0.0, double.infinity),
                                                  radius: 12,
                                                  showTitle: false,
                                                ),
                                              ],
                                              sectionsSpace: 0,
                                              centerSpaceRadius: 35,
                                              startDegreeOffset: -90,
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              "$percentString%",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(goal.color),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    
                                    // Goal Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${currencyFormat.format(goal.savedAmount)} / ${currencyFormat.format(goal.targetAmount)}', 
                                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
                                          ),
                                          const SizedBox(height: 8),
                                          if (goal.lastUpdated != null)
                                            Text(
                                              "Last added: ${DateFormat('MMM d').format(goal.lastUpdated!)}" +
                                              (goal.lastAddedAmount != null ? " - ${currencyFormat.format(goal.lastAddedAmount)}" : ""),
                                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context, 
                                            MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal, autoShowAddDialog: true))
                                          );
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text("Add Funds"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(goal.color).withOpacity(0.1),
                                          foregroundColor: Color(goal.color),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                  ],
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
        onPressed: () => _showAddEditGoalDialog(context),
        backgroundColor: const Color(0xFF00C4B4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, AppProvider provider, Goal goal) {
    String input = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Funds to ${goal.name}'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '+ '),
          keyboardType: TextInputType.number,
          onChanged: (val) => input = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(input);
              if (amount != null && amount > 0) {
                 final newSaved = goal.savedAmount + amount;
                 
                 // Update goal using copyWith
                 final updatedGoal = goal.copyWith(
                   savedAmount: newSaved,
                   lastUpdated: DateTime.now(),
                 );
                 provider.updateGoal(updatedGoal);
                 
                 // Also create a "Transaction" or just update goal?
                 // User said "show that transaction adding amount to goal is shown" -> implies maybe just displaying "Last updated"
                 // Or actually creating a transaction record?
                 // "last updated transaction i.e. adding amount to the goal is shown"
                 // This sounds like they want to see "Last Added: 500 on Date".
                 // In implementation plan I interpreted as "Last Updated: Date".
                 // Let's stick to updating the goal for now to avoid complexity of linking transactions to goals unless explicitly asked.
                 // The "lastUpdated" field on Goal handles the "is shown" part (e.g. "Last added: Dec 12").
                 
                 Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ... existing _showAddEditGoalDialog ...


  void _showAddEditGoalDialog(BuildContext context, {Goal? goal}) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEditing = goal != null;

    final nameController = TextEditingController(text: goal?.name ?? '');
    final targetController = TextEditingController(text: goal?.targetAmount.toStringAsFixed(0) ?? '');
    final savedController = TextEditingController(text: goal?.savedAmount.toStringAsFixed(0) ?? '');
    final notesController = TextEditingController(text: goal?.notes ?? '');
    
    int selectedColor = goal?.color ?? 0xFF00C4B4;
    int selectedIcon = goal?.icon ?? Icons.savings.codePoint;

    final List<int> colors = [0xFF00C4B4, 0xFFFF6B6B, 0xFF4CAF50, 0xFF2196F3, 0xFFFF9800, 0xFF9C27B0];
    final List<IconData> icons = [Icons.savings, Icons.directions_car, Icons.home, Icons.flight, Icons.laptop, Icons.school];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Goal' : 'New Goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   TextField(
                     controller: nameController,
                     decoration: const InputDecoration(labelText: 'Goal Name', hintText: 'e.g., Vacation'),
                   ),
                   const SizedBox(height: 16),
                   TextField(
                     controller: targetController,
                     decoration: const InputDecoration(labelText: 'Target Amount'),
                     keyboardType: TextInputType.number,
                   ),
                   const SizedBox(height: 16),
                   TextField(
                     controller: savedController,
                     decoration: const InputDecoration(labelText: 'Already Saved'),
                     keyboardType: TextInputType.number,
                   ),
                   const SizedBox(height: 16),
                   TextField(
                     controller: notesController,
                     decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                     maxLines: 2,
                   ),
                   const SizedBox(height: 24),
                   const Text("Color", style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     child: Row(
                       children: colors.map((c) => Padding(
                         padding: const EdgeInsets.only(right: 8.0),
                         child: GestureDetector(
                           onTap: () => setState(() => selectedColor = c),
                           child: CircleAvatar(
                             backgroundColor: Color(c),
                             radius: 16,
                             child: selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                           ),
                         ),
                       )).toList(),
                     ),
                   ),
                   const SizedBox(height: 16),
                   const Text("Icon", style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     child: Row(
                       children: icons.map((i) => Padding(
                         padding: const EdgeInsets.only(right: 12.0),
                         child: GestureDetector(
                           onTap: () => setState(() => selectedIcon = i.codePoint),
                           child: Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: selectedIcon == i.codePoint ? Color(selectedColor).withOpacity(0.2) : Colors.transparent,
                               borderRadius: BorderRadius.circular(8),
                               border: selectedIcon == i.codePoint ? Border.all(color: Color(selectedColor)) : null,
                             ),
                             child: Icon(i, color: selectedIcon == i.codePoint ? Color(selectedColor) : Colors.grey),
                           ),
                         ),
                       )).toList(),
                     ),
                   ),
                ],
              ),
            ),
            actions: [
              if (isEditing)
                TextButton(
                  onPressed: () {
                    // Confirm Delete
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: const Text("Delete Goal?"),
                      content: const Text("Are you sure you want to delete this goal?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                        TextButton(onPressed: () {
                           Navigator.pop(ctx); // Close warning
                           provider.deleteGoal(goal!.id!);
                           Navigator.pop(context); // Close edit dialog
                        }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
                      ],
                    ));
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text;
                  final target = double.tryParse(targetController.text) ?? 0.0;
                  final saved = double.tryParse(savedController.text) ?? 0.0;
                  final notes = notesController.text;

                  if (name.isNotEmpty && target > 0) {
                     if (isEditing) {
                       provider.updateGoal(goal!.copyWith(
                         name: name,
                         targetAmount: target,
                         savedAmount: saved,
                         color: selectedColor,
                         icon: selectedIcon,
                         notes: notes,
                       ));
                     } else {
                       provider.addGoal(Goal(
                         name: name,
                         targetAmount: target,
                         savedAmount: saved,
                         color: selectedColor,
                         icon: selectedIcon,
                         notes: notes,
                       ));
                     }
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
