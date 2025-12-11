import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/biometric_service.dart';

class BiometricGuard extends StatefulWidget {
  final Widget child;
  const BiometricGuard({super.key, required this.child});

  @override
  State<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends State<BiometricGuard> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometrics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime? _lastAuthTime;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isChecking) return; // Don't interrupt active check
      if (_isAuthenticated && _lastAuthTime != null && 
          DateTime.now().difference(_lastAuthTime!) < const Duration(seconds: 2)) {
          // Ignore resume if we just authenticated (likely returning from system dialog)
          return;
      }
      _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // Wait for provider to initialize
    if (provider.isLoading) {
       await Future.doWhile(() async {
         if (!mounted) return false;
         if (!provider.isLoading) return false;
         await Future.delayed(const Duration(milliseconds: 100));
         return true;
       });
    }

    if (!provider.settings.isBiometricEnabled) {
      if (mounted) setState(() => _isAuthenticated = true);
      return;
    }

    if (_isChecking) return;
    _isChecking = true;

    // Only lock if we are not authenticated or forcing a re-check
    // But for "Lock on Resume", we DO want to lock.
    if (mounted) setState(() => _isAuthenticated = false);

    // Call authentication
    final service = BiometricService();
    final canCheck = await service.isBiometricsAvailable();
    if (!canCheck) {
       // Allow access if biometrics broken/missing but enabled?
       // Or maybe disable the feature?
       // For safety given user issues, let's allow access but ideally we'd show a PIN screen.
       // Since we don't have a custom PIN screen, we must let them in or they are locked out forever.
       if (mounted) setState(() { _isAuthenticated = true; _isChecking = false; });
       return;
    }

    final authenticated = await service.authenticate();

    if (mounted) {
      setState(() {
        _isAuthenticated = authenticated;
        _isChecking = false;
        if (authenticated) {
          _lastAuthTime = DateTime.now();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.teal),
              const SizedBox(height: 16),
              const Text("App Locked", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkBiometrics,
                child: const Text("Unlock"),
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}
