import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_settings.dart';
import '../models/fixed_expense.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
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
                    'Settings',
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
                  child: const Icon(Icons.settings, color: Colors.white),
                ),
              ],
            ),
          ),

          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                final currencyFormat = NumberFormat.currency(symbol: provider.settings.currency);
                
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [

                    if (AuthService().currentUser != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE0F7FA),
                                image: AuthService().currentUser?.photoURL != null
                                    ? DecorationImage(
                                        image: NetworkImage(AuthService().currentUser!.photoURL!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: AuthService().currentUser?.photoURL == null
                                  ? const Icon(Icons.person, size: 30, color: Color(0xFF00C4B4))
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AuthService().currentUser?.displayName ?? 'User',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AuthService().currentUser?.email ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _buildSettingsSection('General'),
                    _buildSettingsCard(
                      context,
                      icon: Icons.monetization_on,
                      title: 'Monthly Salary',
                      subtitle: currencyFormat.format(provider.settings.salary),
                      onTap: () => _showEditSalaryDialog(context, provider),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsCard(
                      context,
                      icon: Icons.currency_exchange,
                      title: 'Currency',
                      subtitle: provider.settings.currency,
                      onTap: () => _showCurrencyDialog(context, provider),
                    ),

                    const SizedBox(height: 30),
                    _buildSettingsCard(
                      context,
                      icon: Icons.calendar_today,
                      title: 'Calendar System',
                      subtitle: provider.settings.calendarSystem == 'BS' ? 'Nepali (BS)' : 'English (AD)',
                      onTap: () => _showCalendarDialog(context, provider),
                    ),
                    
                    const SizedBox(height: 30),
                    _buildSettingsSection('Fixed Expenses'),
                    
                    ...provider.fixedExpenses.map((expense) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt, color: Color(0xFFFF6B6B)),
                        ),
                        title: Text(expense.name, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        trailing: Text(currencyFormat.format(expense.amount), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        onTap: () => _showEditFixedExpenseDialog(context, provider, expense),
                      ),
                    )),
                    
                    GestureDetector(
                      onTap: () => _showAddFixedExpenseDialog(context, provider),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FFF4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Color(0xFF4CAF50)),
                            SizedBox(width: 8),
                            Text("Add Fixed Expense", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                          ],
                        ),
                      ),
                    ),

                    
                    const SizedBox(height: 30),
                    _buildSettingsSection('Account'),
                    _buildSettingsCard(
                      context,
                      icon: Icons.logout,
                      title: 'Log Out',
                      subtitle: 'Sign out of your account',
                      onTap: () async {
                        await AuthService().signOut();
                        // Navigation is handled by the StreamBuilder in main.dart
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFC).withOpacity(0.1), // Dynamic opacity
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF00C4B4)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        trailing: const Icon(Icons.edit, color: Colors.grey, size: 20),
        onTap: onTap,
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
                  currency: provider.settings.currency,
                  isDarkMode: provider.settings.isDarkMode,
                  isBiometricEnabled: provider.settings.isBiometricEnabled,
                  calendarSystem: provider.settings.calendarSystem,
                  id: provider.settings.id
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

  void _showCalendarDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Calendar System'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English (AD)'),
              leading: Radio<String>(
                value: 'AD',
                groupValue: provider.settings.calendarSystem,
                onChanged: (val) {
                  provider.toggleCalendar('AD');
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                provider.toggleCalendar('AD');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Nepali (BS)'),
              leading: Radio<String>(
                value: 'BS',
                groupValue: provider.settings.calendarSystem,
                onChanged: (val) {
                  provider.toggleCalendar('BS');
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                provider.toggleCalendar('BS');
                Navigator.pop(context);
              },
            ),
          ],
        ),
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
                currency: currency,
                isDarkMode: provider.settings.isDarkMode,
                isBiometricEnabled: provider.settings.isBiometricEnabled,
                calendarSystem: provider.settings.calendarSystem,
                id: provider.settings.id
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

  void _showEditFixedExpenseDialog(BuildContext context, AppProvider provider, FixedExpense expense) {
    String name = expense.name;
    String amountText = expense.amount.toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Fixed Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              controller: TextEditingController(text: name),
              onChanged: (value) => name = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: amountText),
              onChanged: (value) => amountText = value,
            ),
          ],
        ),
        actions: [
          TextButton(
             onPressed: () {
               // Only delete if user confirms? Or just add a delete button here?
               // The request was to EDIT. But users might want to delete too.
               // Existing UI didn't seem to have delete button visible in previous code?
               // Wait, previous code map didn't show delete.
               // Let's stick to update to be safe, maybe add delete if needed.
               // Actually user said "i was not able to edit it".
               Navigator.pop(context);
             },
             child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(amountText);
              if (amount != null && amount > 0 && name.isNotEmpty) {
                provider.updateFixedExpense(FixedExpense(
                  id: expense.id,
                  name: name,
                  amount: amount.toDouble()
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
          TextButton(
             onPressed: () {
                // Keep delete functionality
                if (expense.id != null) {
                   provider.deleteFixedExpense(expense.id!);
                   Navigator.pop(context);
                }
             },
             child: const Text('Delete', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
}
