import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './theme_provider.dart';
import './cart_provider.dart';
import './session_manager.dart';
import './app_theme.dart'; // Import the new theme file
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/cart_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Washio',
            theme: AppTheme.lightTheme, // Use the new light theme
            darkTheme: AppTheme.darkTheme, // Use the new dark theme
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const AuthChecker(), 
            routes: {
              '/cart': (context) {
                final userId = ModalRoute.of(context)?.settings.arguments as int?;
                if (userId != null) {
                  return CartScreen(userId: userId);
                } else {
                  return const Scaffold(
                    body: Center(
                      child: Text('Error: User ID not provided for cart.'),
                    ),
                  );
                }
              },
            },
          );
        },
      ),
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    Map<String, dynamic>? userData = await SessionManager.loadUserData();
    if (mounted) {
      if (userData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AppShell(userData: userData)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
