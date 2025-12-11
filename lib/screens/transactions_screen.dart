import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;
import '../utils/sms_parser.dart';

import '../widgets/app_drawer.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final currencyFormat = NumberFormat.currency(symbol: provider.settings.currency);
          
          return Column(
            children: [
              // Custom Gradient Header
              Container(
                padding: const EdgeInsets.only(top: 50, left: 16, right: 20, bottom: 20), // Adjusted padding
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
                        'Transactions',
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
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Budget Summary Section
              if (provider.budgets.isNotEmpty)
                Container(
                  height: 140, // Slightly taller for better spacing
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.budgets.length,
                    itemBuilder: (context, index) {
                      final budget = provider.budgets[index];
                      final spent = provider.getSpentAmountForCategory(budget.category);
                      final progress = (spent / budget.amount).clamp(0.0, 1.0);
                      
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(budget.category, 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                                overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  color: progress > 0.9 ? const Color(0xFFFF6B6B) : const Color(0xFF00C4B4),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text('${currencyFormat.format(spent)} / ${currencyFormat.format(budget.amount)}',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              if (provider.budgets.isEmpty) const SizedBox(height: 20),

              // Transaction List or Empty State
              Expanded(
                child: provider.transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notes, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            "No transactions yet",
                            style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: provider.transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = provider.transactions[index];
                        final isExpense = transaction.type == 'expense';
                        return Dismissible(
                          key: Key(transaction.id.toString()),
                          onDismissed: (_) => provider.deleteTransaction(transaction.id!),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: const Color(0xFFFF6B6B),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Container(
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
                                    isExpense ? Icons.shopping_bag_outlined : Icons.arrow_upward_rounded,
                                    color: isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF4CAF50),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.subCategory.isNotEmpty
                                            ? '${transaction.category} - ${transaction.subCategory}'
                                            : transaction.category,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        provider.isNepaliDate 
                                          ? NepaliDateFormat.yMMMd().format(NepaliDateTime.fromDateTime(transaction.timestamp))
                                          : DateFormat.yMMMd().format(transaction.timestamp),
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(transaction.amount),
                                  style: TextStyle(
                                    color: isExpense ? Theme.of(context).colorScheme.onSurface : const Color(0xFF4CAF50),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
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
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: const Color(0xFF00C4B4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, {Transaction? transaction}) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEditing = transaction != null;
    
    final amountController = TextEditingController(text: isEditing ? transaction!.amount.toStringAsFixed(2) : '');
    final subCategoryController = TextEditingController(text: transaction?.subCategory ?? '');
    
    DateTime selectedDate = isEditing ? transaction!.timestamp : DateTime.now();
    String type = isEditing ? transaction!.type : 'expense';
    String category = isEditing ? transaction!.category : '';
    
    // Get categories from budgets for expenses
    final budgetCategories = provider.budgets.map((b) => b.category).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Calculate progress if category is selected
          double? budgetAmount;
          double? spentAmount;
          double? progress; // 0.0 to 1.0

          if (category.isNotEmpty && type == 'expense') {
            try {
              final budget = provider.budgets.firstWhere((b) => b.category == category);
              budgetAmount = budget.amount;
              spentAmount = provider.getSpentAmountForCategory(category);
              progress = (spentAmount / budgetAmount).clamp(0.0, 1.0);
            } catch (e) {
              // Handle case where budget might be missing but category exists
            }
          }

          return AlertDialog(
            title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
            content: SingleChildScrollView(
              child: Column(
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
                        category = ''; // Reset category on type change
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Import SMS Button (Only for new transactions for simplicity)
                  if (!isEditing)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ParsedTransaction? result = await _showSmsImportDialog(context);
                      if (result != null) {
                        setState(() {
                          amountController.text = result.amount.toString();
                          selectedDate = result.date;
                        });
                        
                        if (provider.isNepaliDate) {
                           final bsDate = NepaliDateTime.fromDateTime(result.date);
                           final formatted = NepaliDateFormat.yMMMd().format(bsDate);
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text("Date converted to BS: $formatted")),
                           );
                        }
                      }
                    },
                    icon: const Icon(Icons.sms),
                    label: const Text("Import from SMS"),
                  ),
                  if (!isEditing) const SizedBox(height: 16),

                  TextField(
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    controller: amountController,
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Picker
                  InkWell(
                    onTap: () async {
                      if (provider.isNepaliDate) {
                        final NepaliDateTime? picked = await picker.showMaterialDatePicker(
                          context: context,
                          initialDate: NepaliDateTime.fromDateTime(selectedDate),
                          firstDate: NepaliDateTime(2070),
                          lastDate: NepaliDateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked.toDateTime();
                          });
                        }
                      } else {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(provider.isNepaliDate 
                            ? NepaliDateFormat.yMMMd().format(NepaliDateTime.fromDateTime(selectedDate))
                            : DateFormat.yMMMd().format(selectedDate)
                          ),
                          const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (type == 'expense') ...[
                    if (budgetCategories.isEmpty)
                      const Text('No budgets defined. Please create a budget first.', 
                        style: TextStyle(color: Colors.red)),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category (from Budget)'),
                      value: category.isEmpty ? null : category,
                      items: budgetCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (value) {
                        setState(() {
                          category = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Sub-category (Optional)'),
                      controller: subCategoryController,
                    ),
                    
                    if (category.isNotEmpty && budgetAmount != null) ...[
                      const SizedBox(height: 20),
                      Text('Budget Usage: ${((progress ?? 0) * 100).toStringAsFixed(1)}%'),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: (progress ?? 0) > 0.9 ? Colors.red : Colors.blue,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 5),
                      Text('${spentAmount!.toStringAsFixed(0)} / ${budgetAmount!.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ] else
                    // For Income, just a text field for source/category
                   TextFormField(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Source'),
                      onChanged: (value) => category = value,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0 && category.isNotEmpty) {
                    if (isEditing) {
                      provider.updateTransaction(transaction!.copyWith(
                        timestamp: selectedDate,
                        amount: amount,
                        category: category,
                        subCategory: subCategoryController.text,
                        type: type,
                      ));
                    } else {
                      provider.addTransaction(Transaction(
                        timestamp: selectedDate,
                        amount: amount,
                        category: category,
                        subCategory: subCategoryController.text,
                        type: type,
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


  Future<ParsedTransaction?> _showSmsImportDialog(BuildContext context) {
    String text = '';
    return showDialog<ParsedTransaction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parse SMS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text("Paste the transaction SMS below:", style: TextStyle(fontSize: 12, color: Colors.grey)),
             const SizedBox(height: 8),
             TextField(
               maxLines: 4,
               decoration: const InputDecoration(
                 border: OutlineInputBorder(),
                 hintText: 'Your bank/wallet SMS...',
               ),
               onChanged: (val) => text = val,
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
              final parsed = SmsParser.parse(text);
              if (parsed != null) {
                Navigator.pop(context, parsed);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not parse SMS. Try manual entry.')),
                );
              }
            },
            child: const Text('Parse'),
          ),
        ],
      ),
    );
  }
}
