import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auth/auth.dart';
import 'package:inventory/inventory.dart';
import 'package:data/data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isLoggedIn = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await ref.read(authRepositoryProvider).getToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
        _checkingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    return MaterialApp(
      title: 'Asset Cheetah',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isLoggedIn 
        ? const ScanScreen() 
        : LoginScreen(onLoginSuccess: () {
            setState(() => _isLoggedIn = true);
          }),
    );
  }
}
