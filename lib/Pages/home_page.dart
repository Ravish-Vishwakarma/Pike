import 'package:flutter/material.dart';
import 'package:pike/Pages/models_page.dart';
import 'package:pike/Pages/settings_page.dart';
import 'package:pike/Widgets/bottom_nav_bar.dart';
import 'package:pike/Pages/chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  final PageController pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        children: const [ChatPage(), ModelsPage(), SettingsPage()],
      ),

      bottomNavigationBar: MyBottomNavBar(
        currentIndex: currentIndex,
        pageController: pageController,
      ),
    );
  }
}
