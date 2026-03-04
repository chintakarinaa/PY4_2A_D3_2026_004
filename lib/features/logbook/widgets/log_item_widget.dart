import 'package:flutter/material.dart';
import '../models/log_model.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback onEdit;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.onEdit,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Pekerjaan":
        return Colors.deepPurple;
      case "Urgent":
        return const Color(0xFF690DA7);
      default:
        return const Color(0xFF6A5AE0);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final clean = isoDate.split('.').first;
      final date = DateTime.parse(clean);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return "baru saja";
      }

      if (diff.inMinutes < 60) {
        return "${diff.inMinutes} menit yang lalu";
      }

      if (diff.inHours < 24) {
        return "${diff.inHours} jam yang lalu";
      }

      if (diff.inDays == 1) {
        return "kemarin";
      }

      return "${diff.inDays} hari yang lalu";
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(log.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                log.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    log.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.edit,
                    size: 18,
                    color: color,
                  ),
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              log.description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(log.date),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}