import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/prediction_service.dart';
import '../../services/api_client.dart';
import '../../widgets/app_card.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/result_dialog.dart';
import '../../widgets/staggered_fade_slide.dart';

class AnalisFormTab extends StatefulWidget {
  const AnalisFormTab({super.key});

  @override
  State<AnalisFormTab> createState() => _AnalisFormTabState();
}

class _AnalisFormTabState extends State<AnalisFormTab> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usiaController = TextEditingController();
  final TextEditingController _pendapatanController = TextEditingController();
  final TextEditingController _jumlahPinjamanController = TextEditingController();
  final TextEditingController _tabunganController = TextEditingController();
  final TextEditingController _durasiController = TextEditingController();

  String? _pekerjaan;
  int? _jumlahTanggungan;
  String _satuanWaktu = 'Hari';

  bool _isAnalyzing = false;

  final List<String> _pekerjaanOptions = const [
    'PNS', 'Buruh', 'IRT', 'Karyawan', 'Petani', 'Wiraswasta', 'Wirausaha',
  ];

  final List<int> _tanggunganOptions = const [0, 1, 2, 3, 4, 5];

  final List<String> _satuanWaktuOptions = const ['Hari', 'Bulan', 'Tahun'];

    String _formatPekerjaanLabel(String value) {
    if (value == 'IRT') return 'Ibu Rumah Tangga';
    return value;
  }

  int _convertToHari(int nilai, String satuan) {
    switch (satuan) {
      case 'Bulan':
        return nilai * 30;
      case 'Tahun':
        return nilai * 365;
      default:
        return nilai;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usiaController.dispose();
    _pendapatanController.dispose();
    _jumlahPinjamanController.dispose();
    _tabunganController.dispose();
    _durasiController.dispose();
    super.dispose();
  }

  Future<void> _handleAnalisis() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_pekerjaan == null || _jumlahTanggungan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi seluruh data terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    showDialog(context: context, barrierDismissible: false, builder: (context) => const _LoadingDialog());

    try {
      final nilaiDurasi = int.parse(_durasiController.text);
      final durasiHari = _convertToHari(nilaiDurasi, _satuanWaktu);
      final durasiLabel = '$nilaiDurasi $_satuanWaktu';

      final result = await PredictionService.instance.predict(
        nama: _namaController.text.trim(),
        usia: int.parse(_usiaController.text),
        pekerjaan: _pekerjaan!,
        pendapatan: double.parse(_pendapatanController.text),
        jumlahTanggungan: _jumlahTanggungan!,
        jumlahPinjaman: double.parse(_jumlahPinjamanController.text),
        tabungan: double.parse(_tabunganController.text),
        durasiHari: durasiHari,
        durasiLabel: durasiLabel,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _isAnalyzing = false);

      showDialog(context: context, builder: (context) => ResultDialog(result: result));
      _resetForm();
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan tak terduga. Coba lagi.')),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _namaController.clear();
    _usiaController.clear();
    _pendapatanController.clear();
    _jumlahPinjamanController.clear();
    _tabunganController.clear();
    _durasiController.clear();
    setState(() {
      _pekerjaan = null;
      _jumlahTanggungan = null;
      _satuanWaktu = 'Hari';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeSlide(
              index: 0,
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2647).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.fact_check_outlined, color: Color(0xFF0A2647), size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Historis Calon Debitur',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B2A41)),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Lengkapi 7 atribut sesuai skema model klasifikasi C4.5',
                            style: TextStyle(fontSize: 12, color: Color(0xFF5B6B79)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            StaggeredFadeSlide(
              index: 1,
              child: _buildSectionCard(
                title: 'Informasi Debitur',
                children: [
                  TextFormField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama / ID Calon Debitur',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Nama atau ID wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _usiaController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Usia',
                            suffixText: 'Thn',
                            prefixIcon: Icon(Icons.cake_outlined, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Wajib diisi';
                            final age = int.tryParse(value);
                            if (age == null) return 'Harus angka';
                            if (age < 18 || age > 80) return 'Rentang 18-80';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: CustomDropdown<int>(
                          label: 'Tanggungan',
                          icon: Icons.family_restroom_outlined,
                          value: _jumlahTanggungan,
                          items: _tanggunganOptions,
                          itemLabel: (item) => item == 5 ? '5+ Orang' : '$item Orang',
                          onChanged: (value) => setState(() => _jumlahTanggungan = value),
                          validator: (value) => value == null ? 'Wajib dipilih' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pendapatanController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Pendapatan Bulanan',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(Icons.payments_outlined, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Wajib diisi';
                      final income = double.tryParse(value);
                      if (income == null || income <= 0) return 'Nominal tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomDropdown<String>(
                    label: 'Pekerjaan',
                    icon: Icons.work_outline_rounded,
                    value: _pekerjaan,
                    items: _pekerjaanOptions,
                    itemLabel: _formatPekerjaanLabel,
                    onChanged: (value) => setState(() => _pekerjaan = value),
                    validator: (value) => value == null ? 'Wajib dipilih' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            StaggeredFadeSlide(
              index: 2,
              child: _buildSectionCard(
                title: 'Data Kredit',
                children: [
                  TextFormField(
                    controller: _jumlahPinjamanController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Pinjaman',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(Icons.request_quote_outlined, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Wajib diisi';
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) return 'Nominal tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tabunganController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Tabungan',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(Icons.savings_outlined, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Wajib diisi';
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) return 'Nominal tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _durasiController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Durasi Pinjaman',
                            prefixIcon: Icon(Icons.calendar_month_outlined, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Wajib diisi';
                            final durasi = int.tryParse(value);
                            if (durasi == null || durasi <= 0) return 'Tidak valid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: CustomDropdown<String>(
                          label: 'Satuan',
                          icon: Icons.schedule_outlined,
                          value: _satuanWaktu,
                          items: _satuanWaktuOptions,
                          itemLabel: (item) => item,
                          onChanged: (value) => setState(() => _satuanWaktu = value ?? 'Hari'),
                          validator: (value) => value == null ? 'Wajib dipilih' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _handleAnalisis,
                icon: const Icon(Icons.analytics_outlined, size: 20),
                label: const Text('Analisis Risiko'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : _resetForm,
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: const Text('Reset Formulir'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1B2A41))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(width: 46, height: 46, child: CircularProgressIndicator(strokeWidth: 3.2, color: Color(0xFF0A2647))),
            SizedBox(height: 20),
            Text(
              'Memproses Model C4.5...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1B2A41)),
            ),
            SizedBox(height: 6),
            Text(
              'Menganalisis pola data historis debitur',
              style: TextStyle(fontSize: 12, color: Color(0xFF5B6B79)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}