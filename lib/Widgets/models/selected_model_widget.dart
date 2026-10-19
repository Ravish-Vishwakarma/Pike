import 'package:flutter/material.dart';

class SelectedModelWidget extends StatelessWidget {
  final String modelName;

  const SelectedModelWidget({super.key, required this.modelName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Selected Model: ',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          Text(modelName),
        ],
      ),
    );
  }
}
