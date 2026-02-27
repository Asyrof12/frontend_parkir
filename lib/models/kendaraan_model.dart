class KendaraanModel {
  final int idKendaraan;
  final String jenisKendaraan;
  final String platNomor;
  final String warna;
  final String pemilik;
  final int idUser;


  KendaraanModel({
    required this.idKendaraan,
    required this.jenisKendaraan,
    required this.platNomor,
    required this.warna,
    this.pemilik = '',
    this.idUser = 0,
  });


  factory KendaraanModel.fromJson(Map<String, dynamic> json) {
    return KendaraanModel(
      idKendaraan: json['id_kendaraan'] ?? 0,
      jenisKendaraan: json['jenis_kendaraan'] ?? '',
      platNomor: json['plat_nomor'] ?? '',
      warna: json['warna'] ?? '',
      pemilik: json['pemilik'] ?? '',
      idUser: json['id_user'] ?? 0,
    );

  }

  Map<String, dynamic> toJson() {
    return {
      'id_kendaraan': idKendaraan,
      'jenis_kendaraan': jenisKendaraan,
      'plat_nomor': platNomor,
      'warna': warna,
      'pemilik': pemilik,
      'id_user': idUser,
    };

  }

  String get displayName => '$jenisKendaraan - $platNomor';
}
