class KendaraanModel {
  final int idKendaraan;
  final String jenisKendaraan;
  final String platNomor;
  final String warna;
  final String pemilik;

  KendaraanModel({
    required this.idKendaraan,
    required this.jenisKendaraan,
    required this.platNomor,
    required this.warna,
    this.pemilik = '',
  });

  factory KendaraanModel.fromJson(Map<String, dynamic> json) {
    return KendaraanModel(
      idKendaraan: json['id_kendaraan'] ?? 0,
      jenisKendaraan: json['jenis_kendaraan'] ?? '',
      platNomor: json['plat_nomor'] ?? '',
      warna: json['warna'] ?? '',
      pemilik: json['pemilik'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_kendaraan': idKendaraan,
      'jenis_kendaraan': jenisKendaraan,
      'plat_nomor': platNomor,
      'warna': warna,
      'pemilik': pemilik,
    };
  }

  String get displayName => '$jenisKendaraan - $platNomor';
}
