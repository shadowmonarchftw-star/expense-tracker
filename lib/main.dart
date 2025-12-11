import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'providers/app_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/biometric_guard.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    // Initialize Notifications
    await NotificationService().init();
    
    runApp(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("Error initializing app: $e", textAlign: TextAlign.center),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, ThemeMode>(
      selector: (context, provider) => provider.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Save Up',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal, 
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            iconTheme: const IconThemeData(color: Colors.white),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          themeMode: themeMode,
          home: StreamBuilder<User?>(
            stream: AuthService().user,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snapshot.hasData) {
                return const BiometricGuard(child: MainScreen());
              }
              
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const BudgetScreen(),
    const GoalsScreen(),
    const SettingsScreen(),
  ];

  @override
  @override
  Widget build(BuildContext context) {
    // Watch provider for changes
    final provider = Provider.of<AppProvider>(context);
    
    return Scaffold(
      drawer: const AppDrawer(),
      body: _screens[provider.selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: provider.selectedIndex,
        onDestinationSelected: (index) {
          provider.setTabIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pie_chart),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
