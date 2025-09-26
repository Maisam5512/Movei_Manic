import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'LoginPage.dart';
import 'HomePage.dart';

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Monitor authentication state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting for auth state
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData) {
          // User is logged in, navigate to HomePage
          return HomePage();
        } else {
          // User is not logged in, navigate to LoginPage
          return LoginPage();
        }
      },
    );
  }
}
