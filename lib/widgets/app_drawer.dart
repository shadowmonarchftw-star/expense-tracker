import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart'; // Adjust path if needed
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary, // Teal
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF004D40), const Color(0xFF00251A)]
                  : [const Color(0xFF00C4B4), const Color(0xFF008F84)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              user?.displayName ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? 'No Email'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                style: TextStyle(fontSize: 24, color: theme.colorScheme.primary),
              ),
            ),
          ),
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.pie_chart),
                    title: const Text('Dashboard'),
                    selected: provider.selectedIndex == 0,
                    selectedColor: theme.colorScheme.primary,
                    onTap: () {
                      provider.setTabIndex(0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list),
                    title: const Text('Transactions'),
                    selected: provider.selectedIndex == 1,
                    selectedColor: theme.colorScheme.primary,
                    onTap: () {
                      provider.setTabIndex(1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('Budget'),
                    selected: provider.selectedIndex == 2,
                    selectedColor: theme.colorScheme.primary,
                    onTap: () {
                      provider.setTabIndex(2);
                      Navigator.pop(context);
                    },
                  ),
                   ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    selected: provider.selectedIndex == 3,
                    selectedColor: theme.colorScheme.primary,
                     onTap: () {
                      provider.setTabIndex(3);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
          
          const Divider(),
          // Dark Mode Switch
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              final isDarkMode = provider.themeMode == ThemeMode.dark || 
                                 (provider.themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
                                 
              return SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                value: provider.themeMode == ThemeMode.dark,
                onChanged: (val) {
                  provider.toggleTheme(val);
                },
              );
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text('Logout', style: TextStyle(color: Colors.grey)),
            onTap: () async {
              await AuthService().signOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
