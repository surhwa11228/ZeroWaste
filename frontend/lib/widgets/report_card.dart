import 'package:flutter/material.dart';

enum ReportStatus { pending, approved, rejected }

class ReportItem {
  final String id;
  final String title;
  final String address;
  final String timeAgo;
  final ReportStatus status;
  final String? thumbnailUrl;

  ReportItem({
    required this.id,
    required this.title,
    required this.address,
    required this.timeAgo,
    required this.status,
    this.thumbnailUrl,
  });
}

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.item, this.onTap});

  final ReportItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusChip = switch (item.status) {
      ReportStatus.pending => Chip(
        label: const Text('대기'),
        avatar: const Icon(Icons.hourglass_bottom, size: 16),
        backgroundColor: Colors.amber.withValues(alpha: 0.2),
      ),
      ReportStatus.approved => Chip(
        label: const Text('승인'),
        avatar: const Icon(Icons.verified, size: 16),
        backgroundColor: Colors.green.withValues(alpha: 0.2),
      ),
      ReportStatus.rejected => Chip(
        label: const Text('거절'),
        avatar: const Icon(Icons.cancel_outlined, size: 16),
        backgroundColor: Colors.red.withValues(alpha: 0.18),
      ),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _thumbnail(),
              const SizedBox(width: 12),
              Expanded(child: _info(context, statusChip)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final placeholder = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: const Icon(Icons.photo, size: 28, color: Colors.black45),
    );

    if (item.thumbnailUrl == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        item.thumbnailUrl!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _info(BuildContext context, Widget statusChip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          item.address,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            statusChip,
            const SizedBox(width: 8),
            Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(item.timeAgo, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ],
    );
  }
}
