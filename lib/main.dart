import 'package:flutter/material.dart';
// Add this import
import 'package:space_gpt/pages/home_page.dart';

void main()=>runApp(const MyApp());


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  // Add this line
      home: const HomePage(),
      theme: ThemeData(
        fontFamily: "Space Mono",
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey.shade900,
        primaryColor: Colors.pink.shade900,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: "Space Mono"),
          bodyMedium: TextStyle(fontFamily: "Space Mono"),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(fontFamily: "Space Mono"),
          labelStyle: TextStyle(fontFamily: "Space Mono"),
        ),
      ),
    );
  }
}
