import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/debitur_history.dart';
import '../../services/auth_service.dart';
import '../../services/prediction_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/history_list_tile.dart';
import '../../widgets/staggered_fade_slide.dart';
import '../../widgets/summary_card.dart';
import '../detail_riwayat_screen.dart';

class AdminDashboardTab extends StatefulWidget {
  final VoidCallback onGoToRiwayat;

  const AdminDashboardTab({super.key, required this.onGoToRiwayat});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard() async {
    final summary = await PredictionService.instance.fetchSummary();
    final history = await PredictionService.instance.fetchHistory();
    return _DashboardData(summary: summary, history: history);
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
    await _dashboardFuture;
  }

  void _openDetail(DebiturHistory data) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailRiwayatScreen(data: data)));
  }

  @override
  Widget build(BuildContext context) {
    final adminName = AuthService.instance.currentUser?.nama ?? 'Admin';

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 80),
                Center(child: Text('Gagal memuat data: ${snapshot.error}', textAlign: TextAlign.center)),
              ],
            );
          }

          final summary = snapshot.data!.summary;
          final history = snapshot.data!.history;

          final total = summary['total'] ?? 0;
          final lancarPercent = (summary['lancarPercent'] ?? 0).toDouble();
          final macetPercent = (summary['macetPercent'] ?? 0).toDouble();

          final jobCounts = <String, int>{};
          for (final item in history) {
            jobCounts[item.pekerjaan] = (jobCounts[item.pekerjaan] ?? 0) + 1;
          }
          final sortedJobs = jobCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final topJobs = sortedJobs.take(5).toList();
          final maxJobCount = topJobs.isEmpty ? 1 : topJobs.first.value;

          final recentItems = history.take(5).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text('Halo, $adminName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B2A41))),
              const SizedBox(height: 4),
              Text('Ringkasan performa kredit di seluruh sistem', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 380;
                  final cardsData = [
                    SummaryCard(
                      title: 'Total Evaluasi',
                      value: '$total',
                      icon: Icons.assessment_outlined,
                      color: const Color(0xFF0A2647),
                      backgroundColor: const Color(0xFF0A2647).withOpacity(0.08),
                    ),
                    SummaryCard(
                      title: 'Kredit Lancar',
                      value: '${lancarPercent.toStringAsFixed(0)}%',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF2E7D32),
                      backgroundColor: const Color(0xFFE6F4EA),
                    ),
                    SummaryCard(
                      title: 'Kredit Macet',
                      value: '${macetPercent.toStringAsFixed(0)}%',
                      icon: Icons.trending_down_rounded,
                      color: const Color(0xFFC62828),
                      backgroundColor: const Color(0xFFFDECEA),
                    ),
                  ];
                  final cards = List.generate(cardsData.length, (i) => StaggeredFadeSlide(index: i, child: cardsData[i]));
                  if (isNarrow) {
                    return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
                  }
                  return Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList());
                },
              ),
              const SizedBox(height: 24),
              _sectionCard(
                title: 'Distribusi Status Kredit',
                child: total == 0
                    ? _emptyChartPlaceholder('Belum ada data evaluasi')
                    : SizedBox(
                        height: 180,
                        child: Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 36,
                                  sections: [
                                    PieChartSectionData(
                                      value: lancarPercent == 0 && macetPercent == 0 ? 1 : lancarPercent,
                                      title: '${lancarPercent.toStringAsFixed(0)}%',
                                      color: const Color(0xFF2E7D32),
                                      radius: 54,
                                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      value: macetPercent,
                                      title: '${macetPercent.toStringAsFixed(0)}%',
                                      color: const Color(0xFFC62828),
                                      radius: 54,
                                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _legendDot(color: const Color(0xFF2E7D32), label: 'Lancar'),
                                const SizedBox(height: 10),
                                _legendDot(color: const Color(0xFFC62828), label: 'Macet'),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              _sectionCard(
                title: 'Top 5 Pekerjaan Calon Debitur',
                child: topJobs.isEmpty
                    ? _emptyChartPlaceholder('Belum ada data evaluasi')
                    : Column(
                        children: topJobs.map((entry) {
                          final ratio = entry.value / maxJobCount;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1B2A41))),
                                    Text('${entry.value}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0A2647))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFFE4E8EE),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A2647)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Evaluasi Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B2A41))),
                  TextButton(onPressed: widget.onGoToRiwayat, child: const Text('Lihat Semua')),
                ],
              ),
              const SizedBox(height: 6),
              if (recentItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Center(child: Text('Belum ada riwayat evaluasi.', style: TextStyle(color: Colors.grey.shade500))),
                )
              else
                ...recentItems.map((item) => HistoryListTile(data: item, onTap: () => _openDetail(item))),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1B2A41))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _emptyChartPlaceholder(String message) {
    return SizedBox(
      height: 100,
      child: Center(child: Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5))),
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF1B2A41))),
      ],
    );
  }
}

class _DashboardData {
  final Map<String, dynamic> summary;
  final List<DebiturHistory> history;

  const _DashboardData({required this.summary, required this.history});
}