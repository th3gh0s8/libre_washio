import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'theme_provider.dart';         
import 'screens/welcome_screen.dart';
// Ensure you are consistently using the VerificationScreen from lib/screens/
// import 'screens/verification_screen.dart'; 

void main() async { 
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(
    ChangeNotifierProvider( 
      create: (_) => ThemeProvider(),
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
        cardTheme: CardThemeData( // <<< CORRECTED TO CardThemeData
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
        '/verification': (context) {
          final Object? args = ModalRoute.of(context)!.settings.arguments;
          final String phoneNumber = (args is String) ? args : ""; 
          return VerificationScreenLocal(phoneNumber: phoneNumber);
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class VerificationScreenLocal extends StatelessWidget {
  final String phoneNumber;

  const VerificationScreenLocal({Key? key, required this.phoneNumber}) : super(key: key); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'), 
        actions: [
          IconButton(
            icon: const Icon(Icons.signal_cellular_4_bar), 
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.battery_full), 
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 4-digit code sent via SMS at $phoneNumber.',
              style: const TextStyle(fontSize: 18), 
            ),
            const SizedBox(height: 20),
            const Text('Changed your mobile number?'), 
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) => 
              SizedBox( 
                width: 50,
                child: const TextField( 
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Resend code by SMS'), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}
