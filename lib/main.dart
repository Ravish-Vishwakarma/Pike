import 'package:flutter/material.dart';
import 'package:pike/Pages/home_page.dart';
import 'package:pike/Utilities/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: MyColors.primary)),
      home: HomePage(),
    );
  }
}
