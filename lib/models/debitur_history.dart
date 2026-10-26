class DebiturHistory {
  final String id;
  final String nama;
  final String pekerjaan;
  final DateTime tanggal;
  final String status;
  final double pendapatan;
  final int usia;
  final int jumlahTanggungan;
  final double jumlahPinjaman;
  final double tabungan;
  final String jangkaWaktu;
  final double confidence;
  final String namaAnalis;

  const DebiturHistory({
    required this.id,
    required this.nama,
    required this.pekerjaan,
    required this.tanggal,
    required this.status,
    required this.pendapatan,
    required this.usia,
    required this.jumlahTanggungan,
    required this.jumlahPinjaman,
    this.tabungan = 0,
    required this.jangkaWaktu,
    required this.confidence,
    required this.namaAnalis,
  });
}