import 'package:flutter/material.dart';

class ModelsSectionHeader extends StatelessWidget {
  final String title;

  const ModelsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        spacing: 4,
        children: [
          const Expanded(child: Divider()),
          Text(title),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
