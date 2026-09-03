import 'package:flutter/material.dart';
import 'package:pike/Pages/home_page.dart';
import 'package:pike/Services/config.dart';
import 'package:pike/Services/db.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Utilities/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initConfig();
  final config = await loadConfig();
  print(config['selected_model']);
  await initDatabase();
  await ModelManager.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: MyColors.primary),
      ),
      home: const HomePage(),
    );
  }
}
