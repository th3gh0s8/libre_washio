import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './theme_provider.dart';
import './cart_provider.dart';
import './session_manager.dart'; // Import the session manager
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/cart_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.themeMode,
            home: const AuthChecker(), // Start with the AuthChecker
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
  const AuthChecker({Key? key}) : super(key: key);

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
    // Show a loading indicator while checking auth status
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
