import 'package:flutter/material.dart';
import '../models/debitur_history.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';

class DetailRiwayatScreen extends StatelessWidget {
  final DebiturHistory data;

  const DetailRiwayatScreen({super.key, required this.data});

  bool get _isLancar => data.status == 'Lancar';

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _isLancar ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final Color statusBg = _isLancar ? const Color(0xFFE6F4EA) : const Color(0xFFFDECEA);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Evaluasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'avatar-${data.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF0A2647).withOpacity(0.1),
                            child: Text(
                              data.nama.isNotEmpty ? data.nama[0].toUpperCase() : '?',
                              style: const TextStyle(color: Color(0xFF0A2647), fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A41))),
                            const SizedBox(height: 3),
                            Text(data.id, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5B6B79))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        Icon(_isLancar ? Icons.check_circle_rounded : Icons.cancel_rounded, color: statusColor, size: 30),
                        const SizedBox(height: 6),
                        Text(data.status, style: TextStyle(color: statusColor, fontSize: 19, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          'Tingkat Keyakinan Model: ${data.confidence.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF5B6B79)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildSection(
              title: 'Informasi Pribadi',
              rows: [
                _InfoItem(Icons.cake_outlined, 'Usia', '${data.usia} Tahun'),
                _InfoItem(Icons.work_outline_rounded, 'Pekerjaan', data.pekerjaan),
                _InfoItem(Icons.family_restroom_outlined, 'Jumlah Tanggungan', '${data.jumlahTanggungan} Orang'),
              ],
            ),
            const SizedBox(height: 18),
            _buildSection(
              title: 'Informasi Kredit',
              rows: [
                _InfoItem(Icons.payments_outlined, 'Pendapatan Bulanan', AppFormatters.formatCurrency(data.pendapatan)),
                _InfoItem(Icons.request_quote_outlined, 'Jumlah Pinjaman', AppFormatters.formatCurrency(data.jumlahPinjaman)),
                _InfoItem(Icons.savings_outlined, 'Tabungan', AppFormatters.formatCurrency(data.tabungan)),
                _InfoItem(Icons.calendar_month_outlined, 'Jangka Waktu', data.jangkaWaktu),
                _InfoItem(Icons.event_available_outlined, 'Tanggal Evaluasi', AppFormatters.formatDate(data.tanggal)),
              ],
            ),
            const SizedBox(height: 18),
            _buildSection(
              title: 'Informasi Analis',
              rows: [
                _InfoItem(Icons.person_outline_rounded, 'Dianalisis Oleh', data.namaAnalis),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<_InfoItem> rows}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1B2A41))),
          const SizedBox(height: 14),
          for (int i = 0; i < rows.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rows[i].icon, size: 19, color: const Color(0xFF5B6B79)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: Text(rows[i].label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5B6B79)))),
                  Expanded(flex: 3, child: Text(rows[i].value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B2A41)), textAlign: TextAlign.right)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem(this.icon, this.label, this.value);
}