import '../models/prediction_result.dart';
import '../models/debitur_history.dart';
import 'api_client.dart';

class PredictionService {
  PredictionService._();
  static final PredictionService instance = PredictionService._();

  Future<PredictionResult> predict({
    required String nama,
    required int usia,
    required String pekerjaan,
    required double pendapatan,
    required int jumlahTanggungan,
    required double jumlahPinjaman,
    required double tabungan,
    required int durasiHari,
    required String durasiLabel,
  }) async {
    final response = await ApiClient.instance.post('/predict', {
      'nama': nama,
      'usia': usia,
      'pekerjaan': pekerjaan,
      'pendapatan': pendapatan,
      'jumlah_tanggungan': jumlahTanggungan,
      'jumlah_pinjaman': jumlahPinjaman,
      'tabungan': tabungan,
      'durasi_hari': durasiHari,
      'durasi_label': durasiLabel,
    });

    final data = response as Map<String, dynamic>;
    final kategori = Map<String, dynamic>.from(data['kategori'] as Map);
    final probabilitiesRaw = Map<String, dynamic>.from(data['probabilities'] as Map);
    final probabilities = probabilitiesRaw.map((key, value) => MapEntry(key, (value as num).toDouble()));

    return PredictionResult(
      status: data['status'] as String,
      confidence: (data['confidence'] as num).toDouble(),
      analyzedAt: DateTime.now(),
      debiturName: nama,
      summaryFactors: {
        'Pekerjaan': kategori['Pekerjaan']?.toString() ?? '-',
        'Kategori Usia': kategori['usia_kategori']?.toString() ?? '-',
        'Kategori Pendapatan': kategori['pendapatan_kategori']?.toString() ?? '-',
        'Kategori Durasi': kategori['durasi_kategori']?.toString() ?? '-',
        'Kategori Pinjaman': kategori['pinjaman_kategori']?.toString() ?? '-',
        'Kategori Tabungan': kategori['tabungan_kategori']?.toString() ?? '-',
      },
      probabilities: probabilities,
    );
  }

  Future<List<DebiturHistory>> fetchHistory() async {
    final response = await ApiClient.instance.get('/history');
    final list = response as List<dynamic>;

    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return DebiturHistory(
        id: map['id'] as String,
        nama: map['nama'] as String,
        pekerjaan: map['pekerjaan'] as String,
        tanggal: DateTime.parse(map['tanggal'] as String),
        status: map['status'] as String,
        pendapatan: (map['pendapatan'] as num).toDouble(),
        usia: map['usia'] as int,
        jumlahTanggungan: map['jumlahTanggungan'] as int,
        jumlahPinjaman: (map['jumlahPinjaman'] as num).toDouble(),
        tabungan: (map['tabungan'] as num?)?.toDouble() ?? 0,
        jangkaWaktu: map['jangkaWaktu'] as String,
        confidence: (map['confidence'] as num).toDouble(),
        namaAnalis: map['namaAnalis'] as String? ?? '-',
      );
    }).toList();
  }

  Future<Map<String, dynamic>> fetchSummary() async {
    final response = await ApiClient.instance.get('/summary');
    return response as Map<String, dynamic>;
  }
}