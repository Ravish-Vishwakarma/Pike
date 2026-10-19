import 'package:flutter/material.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Utilities/models.dart';

class DownloadedModelList extends StatelessWidget {
  final ValueChanged<int?> onSelect;
  final List<AIModel> models;
  final int? selectedModelId;
  final ValueChanged<AIModel> onDelete;

  const DownloadedModelList({
    super.key,
    required this.onSelect,
    required this.models,
    required this.selectedModelId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<int>(
      groupValue: selectedModelId,
      onChanged: onSelect,
      child: models.isNotEmpty
          ? Column(
              children: models.map((model) {
                return RadioListTile<int>(
                  title: Text(model.name),
                  subtitle: Text('${model.parameters} - ${model.size}'),
                  value: model.id,
                  secondary: IconButton(
                    onPressed: () => onDelete(model),
                    icon: const Icon(Icons.delete),
                  ),
                );
              }).toList(),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: MyColors.surfaceLight.withAlpha(130),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'No Model Downloaded\nPlease download a model to select',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
    );
  }
}
