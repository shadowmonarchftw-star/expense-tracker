import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../models/goal.dart';
import '../models/goal_transaction.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:nepali_utils/nepali_utils.dart'; // For formatting if needed

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;
  final bool autoShowAddDialog;
  
  const GoalDetailScreen({super.key, required this.goal, this.autoShowAddDialog = false});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late Future<List<GoalTransaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
    
    if (widget.autoShowAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         _showAddEditTransactionDialog(context, Provider.of<AppProvider>(context, listen: false));
      });
    }
  }

  void _refreshTransactions() {
    setState(() {
      _transactionsFuture = Provider.of<AppProvider>(context, listen: false).getGoalTransactions(widget.goal.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch goal from provider to get live updates (savedAmount, lastUpdated)
    final provider = Provider.of<AppProvider>(context);
    final goal = provider.goals.firstWhere((g) => g.id == widget.goal.id, orElse: () => widget.goal);
    final currencyFormat = NumberFormat.currency(symbol: provider.settings.currency);

    final percentage = (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
    final percentString = (percentage * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditGoalDialog(context, provider, goal), 
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Chart
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                   SizedBox(
                      height: 180,
                      width: 180,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  color: Color(goal.color),
                                  value: goal.savedAmount,
                                  radius: 20,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  color: Colors.grey[200]!,
                                  value: (goal.targetAmount - goal.savedAmount).clamp(0.0, double.infinity),
                                  radius: 20,
                                  showTitle: false,
                                ),
                              ],
                              sectionsSpace: 0,
                              centerSpaceRadius: 70,
                              startDegreeOffset: -90,
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "$percentString%",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(goal.color),
                                  ),
                                ),
                                Text(
                                  "Completed",
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, "Saved", currencyFormat.format(goal.savedAmount), Color(goal.color)),
                        _buildStatItem(context, "Goal", currencyFormat.format(goal.targetAmount), Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        _buildStatItem(context, "Remaining", currencyFormat.format((goal.targetAmount - goal.savedAmount).clamp(0.0, double.infinity)), Theme.of(context).colorScheme.error),

                      ],
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                  if (goal.lastUpdated != null)
                     Text("Updated: ${DateFormat('MMM d').format(goal.lastUpdated!)}", style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            
            // Transaction List
            FutureBuilder<List<GoalTransaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text("No transactions yet.", style: TextStyle(color: Colors.grey[400])),
                  );
                }
                
                final transactions = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return Card(
                      elevation: 0,
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(goal.color).withOpacity(0.1),
                          child: Icon(Icons.arrow_upward, color: Color(goal.color), size: 16),
                        ),
                        title: Text(currencyFormat.format(tx.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                              onPressed: () => _showAddEditTransactionDialog(context, provider, transaction: tx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                              onPressed: () async {
                                 await provider.deleteGoalTransaction(goal.id!, tx.id!);
                                 _refreshTransactions();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditTransactionDialog(context, provider),
        backgroundColor: Color(goal.color),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Funds", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  void _showEditGoalDialog(BuildContext context, AppProvider provider, Goal goal) {
    final nameController = TextEditingController(text: goal.name);
    final targetController = TextEditingController(text: goal.targetAmount.toStringAsFixed(0));
    final notesController = TextEditingController(text: goal.notes);
    
    int selectedColor = goal.color;
    int selectedIcon = goal.icon;

    final List<int> colors = [0xFF00C4B4, 0xFFFF6B6B, 0xFF4CAF50, 0xFF2196F3, 0xFFFF9800, 0xFF9C27B0];
    final List<IconData> icons = [Icons.savings, Icons.directions_car, Icons.home, Icons.flight, Icons.laptop, Icons.school];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   TextField(
                     controller: nameController,
                     decoration: const InputDecoration(labelText: 'Goal Name'),
                   ),
                   const SizedBox(height: 16),
                   TextField(
                     controller: targetController,
                     decoration: const InputDecoration(labelText: 'Target Amount'),
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
              TextButton(
                onPressed: () {
                   showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: const Text("Delete Goal?"),
                      content: const Text("Are you sure you want to delete this goal?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                        TextButton(onPressed: () {
                           Navigator.pop(ctx); 
                           provider.deleteGoal(goal.id!);
                           Navigator.pop(context); // Close edit dialog
                           Navigator.pop(context); // Close detail screen
                        }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
                      ],
                   ));
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  final name = nameController.text;
                  final target = double.tryParse(targetController.text) ?? 0.0;
                  final notes = notesController.text;

                  if (name.isNotEmpty && target > 0) {
                     provider.updateGoal(goal.copyWith(
                       name: name,
                       targetAmount: target,
                       color: selectedColor,
                       icon: selectedIcon,
                       notes: notes,
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

  void _showAddEditTransactionDialog(BuildContext context, AppProvider provider, {GoalTransaction? transaction}) {
    final isEditing = transaction != null;
    double amount = transaction?.amount ?? 0.0;
    DateTime date = transaction?.date ?? DateTime.now();
    
    // Controller for initial values
    final amountController = TextEditingController(text: isEditing ? amount.toStringAsFixed(0) : '');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Transaction' : 'Add Funds'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: '+ '),
                  keyboardType: TextInputType.number,
                  // We'll parse directly from controller on save to avoid sync issues
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text("Date"),
                  subtitle: Text(DateFormat.yMMMd().format(date)),
                  trailing: const Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    if (provider.settings.calendarSystem == 'BS') {
                      final picked = await showMaterialDatePicker(
                        context: context,
                        initialDate: date.toNepaliDateTime(),
                        firstDate: NepaliDateTime(2070),
                        lastDate: NepaliDateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => date = picked.toDateTime());
                      }
                    } else {
                       final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => date = picked);
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  final text = amountController.text.trim();
                  final parsedAmount = double.tryParse(text) ?? 0.0;

                  if (parsedAmount > 0) {
                    try {
                      if (widget.goal.id == null) {
                        throw Exception("Goal ID is missing");
                      }

                      if (isEditing) {
                        final updatedTx = transaction!.copyWith(amount: parsedAmount, date: date);
                        await provider.updateGoalTransaction(updatedTx);
                      } else {
                        final newTx = GoalTransaction(
                          goalId: widget.goal.id!,
                          amount: parsedAmount,
                          date: date,
                        );
                        await provider.addGoalTransaction(newTx);
                      }
                      
                      _refreshTransactions();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
                      }
                      print("Transaction Save Error: $e");
                    }
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid amount")));
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
