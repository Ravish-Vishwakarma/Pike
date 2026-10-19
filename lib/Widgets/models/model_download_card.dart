import 'package:flutter/material.dart';
import 'package:pike/Services/downloader.dart';
import 'package:pike/Utilities/models.dart';

class ModelDownloadCard extends StatelessWidget {
  final AIModel model;
  final ModelDownloadState? downloadState;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  const ModelDownloadCard({
    super.key,
    required this.model,
    required this.downloadState,
    required this.onDownload,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading =
        downloadState?.status == ModelDownloadStatus.downloading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Card(
        child: ExpansionTile(
          shape: const Border(),
          title: Text(model.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${model.parameters} parameters - ${model.size}'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 5,
                children: [
                  if (model.supportsVision) _capabilityBadge('Vision'),
                  if (model.supportsText) _capabilityBadge('Text'),
                ],
              ),
            ],
          ),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Divider(),
            ),
            Column(
              children: [
                Text('file: ${model.filename}'),
                const SizedBox(height: 8),
                if (isDownloading) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: LinearProgressIndicator(
                      value: downloadState!.progress,
                    ),
                  ),
                  Text(
                    'Downloading ${(downloadState!.progress * 100).toStringAsFixed(0)}%',
                  ),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel download'),
                  ),
                ] else ...[
                  if (downloadState?.status == ModelDownloadStatus.failed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        downloadState?.error ?? 'Download failed.',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download),
                    label: Text(
                      downloadState?.status == ModelDownloadStatus.failed
                          ? 'Retry download'
                          : 'Download model',
                    ),
                  ),
                ],
                const SizedBox(height: 5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _capabilityBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        border: Border.all(color: Colors.grey.shade400, width: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          height: 1.2,
          color: Colors.black87,
        ),
      ),
    );
  }
}
