import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Import provider
import 'theme_provider.dart';         // 2. Import your ThemeProvider (ensure this path is correct)
import 'screens/welcome_screen.dart';
// If VerificationScreen here is different from lib/screens/verification_screen.dart, ensure consistent usage
// import 'screens/verification_screen.dart'; // This would be the typical import

void main() async { // 3. Make main async
  WidgetsFlutterBinding.ensureInitialized(); // 4. Ensure bindings are initialized
  runApp(
    ChangeNotifierProvider( // 5. Provide ThemeProvider
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // Removed const from MyApp to allow hot reload with provider changes if needed,
  // but can be const if child widgets handle all state.
  @override
  Widget build(BuildContext context) {
    // 6. Get ThemeProvider instance
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Washio',
      // 7. Apply theme settings from ThemeProvider
      themeMode: themeProvider.themeMode,
      theme: ThemeData( // Your Light Theme
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        // Add other light theme specific properties here
        // Example:
        // scaffoldBackgroundColor: Colors.white,
        // appBarTheme: AppBarTheme(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      ),
      darkTheme: ThemeData( // Your Dark Theme
        primarySwatch: Colors.blue, // Or a different swatch for dark mode
        brightness: Brightness.dark,
        // Add other dark theme specific properties here
        // Example:
        // scaffoldBackgroundColor: Colors.grey[900],
        // appBarTheme: AppBarTheme(backgroundColor: Colors.grey[850], foregroundColor: Colors.white),
        // elevatedButtonTheme: ElevatedButtonThemeData(
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Colors.blue[700],
        //     foregroundColor: Colors.white,
        //   ),
        // ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        // This VerificationScreen is the one defined below in this file.
        // If you have one in lib/screens/, ensure you're using the correct one.
        '/verification': (context) => VerificationScreen(
          phoneNumber: ModalRoute.of(context)!.settings.arguments as String,
        ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// This VerificationScreen is defined in your main.dart.
// If you have a more up-to-date version in lib/screens/verification_screen.dart,
// you might want to remove this one and import the other.
class VerificationScreen extends StatelessWidget {
  final String phoneNumber;

  VerificationScreen({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification'),
        actions: [
          IconButton(
            icon: Icon(Icons.signal_cellular_4_bar),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.battery_full),
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
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text('Changed your mobile number?'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) => // Assuming 4 digits for this example
              Container(
                width: 50,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                child: Text('Resend code by SMS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
