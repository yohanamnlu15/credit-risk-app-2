import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import '../../models/debitur_history.dart';
import '../../services/prediction_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/history_list_tile.dart';
import '../detail_riwayat_screen.dart';

class RiwayatTab extends StatefulWidget {
  final String role;

  const RiwayatTab({super.key, required this.role});

  @override
  State<RiwayatTab> createState() => _RiwayatTabState();
}

class _RiwayatTabState extends State<RiwayatTab> {
  late Future<List<DebiturHistory>> _historyFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isExporting = false;

  bool get _isAdmin => widget.role == 'Admin';

  @override
  void initState() {
    super.initState();
    _historyFuture = PredictionService.instance.fetchHistory();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = PredictionService.instance.fetchHistory();
    });
    await _historyFuture;
  }

  List<DebiturHistory> _applySearch(List<DebiturHistory> data) {
    if (_searchQuery.isEmpty) return data;
    return data.where((item) {
      return item.nama.toLowerCase().contains(_searchQuery) ||
          item.id.toLowerCase().contains(_searchQuery) ||
          item.pekerjaan.toLowerCase().contains(_searchQuery) ||
          item.namaAnalis.toLowerCase().contains(_searchQuery) ||
          item.status.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<Uint8List> _buildPdfBytes(List<DebiturHistory> data) async {
    final doc = pw.Document();
    const headers = ['ID', 'Nama', 'Pekerjaan', 'Usia', 'Pendapatan', 'Pinjaman', 'Status', 'Keyakinan', 'Analis', 'Tanggal'];
    final rows = data
        .map((d) => [
              d.id,
              d.nama,
              d.pekerjaan,
              '${d.usia}',
              AppFormatters.formatCurrency(d.pendapatan),
              AppFormatters.formatCurrency(d.jumlahPinjaman),
              d.status,
              '${d.confidence.toStringAsFixed(1)}%',
              d.namaAnalis,
              AppFormatters.formatDate(d.tanggal),
            ])
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Laporan Riwayat Klasifikasi Risiko Kredit', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Dicetak: ${AppFormatters.formatDate(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _exportPdf(List<DebiturHistory> data) async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada data untuk diekspor.')));
      return;
    }

    setState(() => _isExporting = true);
    Uint8List? bytes;
    try {
      bytes = await _buildPdfBytes(data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }

    if (bytes == null || !mounted) return;
    _showExportOptions(bytes);
  }

  void _showExportOptions(Uint8List bytes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: Color(0xFF0A2647)),
                  title: const Text('Bagikan'),
                  subtitle: const Text('Kirim lewat WhatsApp, Email, dll'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _sharePdf(bytes);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt_rounded, color: Color(0xFF0A2647)),
                  title: const Text('Simpan ke Perangkat'),
                  subtitle: const Text('Pilih lokasi penyimpanan di HP'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _savePdf(bytes);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sharePdf(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/riwayat_klasifikasi_kredit.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Riwayat Klasifikasi Risiko Kredit');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membagikan PDF: $e')));
    }
  }

  Future<void> _savePdf(Uint8List bytes) async {
    try {
      final savedPath = await FileSaver.instance.saveAs(
        name: 'riwayat_klasifikasi_kredit',
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      if (savedPath != null && savedPath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF disimpan di: $savedPath')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan PDF: $e')));
    }
  }

  void _openDetail(DebiturHistory data) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailRiwayatScreen(data: data)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<DebiturHistory>>(
        future: _historyFuture,
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
                Center(child: Text('Gagal memuat riwayat: ${snapshot.error}', textAlign: TextAlign.center)),
              ],
            );
          }

          final allData = snapshot.data ?? [];
          final data = _applySearch(allData);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isAdmin ? 'Semua Riwayat Klasifikasi' : 'Riwayat Klasifikasi Saya',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B2A41)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF0A2647).withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                    child: Text('${data.length} Data', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0A2647))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama, ID, pekerjaan, atau status...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              if (_isAdmin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isExporting ? null : () => _exportPdf(data),
                      icon: _isExporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_outlined, size: 19),
                      label: Text(_isExporting ? 'Membuat PDF...' : 'Export ke PDF (${data.length} data)'),
                    ),
                  ),
                ),
              if (data.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      _searchQuery.isEmpty ? 'Belum ada riwayat klasifikasi.' : 'Tidak ada hasil untuk "$_searchQuery".',
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...data.map((item) => HistoryListTile(data: item, onTap: () => _openDetail(item))),
            ],
          );
        },
      ),
    );
  }
}