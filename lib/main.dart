import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'theme_provider.dart';
import 'cart_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/cart_screen.dart'; 

void main() async { 
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final Color darkPrimaryColor = Colors.blue[300]!;
    final Color darkSecondaryColor = Colors.lightBlueAccent[100]!;

    return MaterialApp(
      title: 'Washio',
      themeMode: themeProvider.themeMode,
      theme: ThemeData( 
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData( 
        brightness: Brightness.dark, 
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1A1A1A), 
          foregroundColor: Colors.white,
          elevation: 0, 
        ),
        colorScheme: ColorScheme.dark(
          primary: darkPrimaryColor, 
          secondary: darkSecondaryColor, 
          background: Colors.black,      
          surface: const Color(0xFF121212),    
          onPrimary: Colors.black,       
          onSecondary: Colors.black,     
          onBackground: Colors.white,    
          onSurface: Colors.white,       
          onError: Colors.black,         
          error: Colors.redAccent[100]!, 
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),      
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dialogBackgroundColor: Colors.black, 
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkPrimaryColor, 
            foregroundColor: Colors.black, 
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: darkPrimaryColor,
          )
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black, 
          selectedItemColor: darkPrimaryColor,
          unselectedItemColor: Colors.grey[600],
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[850]?.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: darkPrimaryColor),
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        dividerColor: Colors.grey[800], 
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/cart': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as int;
          return CartScreen(userId: userId);
        },
        // REMOVED old /verification route
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// REMOVED unnecessary VerificationScreenLocal widget
