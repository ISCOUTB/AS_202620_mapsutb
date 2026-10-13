import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 

import 'features/home/presentation/home_screen.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() => runApp(const MapsUtbApp());

class MapsUtbApp extends StatelessWidget {
  const MapsUtbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAPSUTB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF093AD8)),
        useMaterial3: true,
      ),
      home: SplashScreen(siguiente: (_) => const HomeScreen()),
    );
  }
}