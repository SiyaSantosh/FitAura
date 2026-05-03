import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Fitaura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF7A5B47),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    ),
  );
}
