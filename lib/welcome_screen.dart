import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo_light.jpeg', height: 100),
            SizedBox(height: 20),
            Text(
              'Get started with Washio',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Mobile number',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                //Image.asset('assets/sri_lanka_flag.png', height: 20),
                SizedBox(width: 10),
                Text('+94'),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Mobile number',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text('Continue'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // Text color
                backgroundColor: Colors.blue, // Background color
                minimumSize: Size(double.infinity, 50), // Full width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                elevation: 5, // Shadow
                textStyle: TextStyle(
                  fontSize: 16, // Text size
                  fontWeight: FontWeight.bold, // Text weight
                ),
                padding: EdgeInsets.symmetric(vertical: 10), // Padding
              ),
            ),
            SizedBox(height: 20),
            Text('or'),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.g_mobiledata),
              label: Text('Continue with Google'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, // Text and icon color
                backgroundColor: Colors.white, // Background color
                minimumSize: Size(double.infinity, 50), // Full width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                elevation: 5, // Shadow
                textStyle: TextStyle(
                  fontSize: 16, // Text size
                  fontWeight: FontWeight.bold, // Text weight
                ),
                padding: EdgeInsets.symmetric(vertical: 10), // Padding
              ),
            ),


            /*

            SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.email),
              label: Text('Continue with email'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),

            TextButton(
              onPressed: () {},
              child: Text('Find my account'),
            ),
             */


            SizedBox(height: 20),
            Text(
              'By proceeding, you consent to receiving calls, WhatsApp or SMS/RCS messages, including by automated means, from Washio and its affiliates to the number provided.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
