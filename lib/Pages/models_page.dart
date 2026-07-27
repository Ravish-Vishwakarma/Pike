import 'package:flutter/material.dart';
import 'package:pike/Utilities/colors.dart';

class ModelsPage extends StatelessWidget {
  const ModelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: Text("MODELS", style: TextStyle(color: MyColors.textLight)),
        backgroundColor: MyColors.primary,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.add, color: MyColors.textLight),
          ),
        ],
      ),
      body: Column(
        children: [
          Text("SOme Teext"),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return ModelsTile(
                  id: 1,
                  name: 'Kimi k2.5',
                  size: '100GB',
                  isDownloaded: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ModelsTile extends StatelessWidget {
  final int id;
  final String name;
  final String size;
  final bool isDownloaded;
  const ModelsTile({
    super.key,
    required this.id,
    required this.name,
    required this.size,
    required this.isDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () {},
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 0.0,
        ),
        title: Text(name),
        subtitle: Text(size),
        trailing: isDownloaded
            ? IconButton(onPressed: () {}, icon: Icon(Icons.delete_rounded))
            : IconButton(onPressed: () {}, icon: Icon(Icons.download_rounded)),
      ),
    );
  }
}
