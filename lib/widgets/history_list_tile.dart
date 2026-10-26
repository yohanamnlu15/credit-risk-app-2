import 'package:flutter/material.dart';
import '../models/debitur_history.dart';
import 'app_card.dart';

class HistoryListTile extends StatelessWidget {
  final DebiturHistory data;
  final VoidCallback? onTap;

  const HistoryListTile({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isLancar = data.status == 'Lancar';
    final Color statusColor = isLancar ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final Color statusBg = isLancar ? const Color(0xFFE6F4EA) : const Color(0xFFFDECEA);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Hero(
            tag: 'avatar-${data.id}',
            child: Material(
              type: MaterialType.transparency,
              child: CircleAvatar(
                backgroundColor: const Color(0xFF0A2647).withOpacity(0.1),
                child: Text(
                  data.nama.isNotEmpty ? data.nama[0].toUpperCase() : '?',
                  style: const TextStyle(color: Color(0xFF0A2647), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          title: Text(
            data.nama,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Color(0xFF1B2A41)),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${data.id} • ${data.pekerjaan} • ${_formatDate(data.tanggal)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5B6B79)),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isLancar ? Icons.check_circle : Icons.cancel, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  data.status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}