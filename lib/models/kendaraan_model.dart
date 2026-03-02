class KendaraanModel {
  final int idKendaraan;
  final String jenisKendaraan;
  final String platNomor;
  final String warna;
  final String pemilik;
  final int idUser;
  final String namaPendaftar;


  KendaraanModel({
    required this.idKendaraan,
    required this.jenisKendaraan,
    required this.platNomor,
    required this.warna,
    this.pemilik = '',
    this.idUser = 0,
    this.namaPendaftar = '',
  });


  factory KendaraanModel.fromJson(Map<String, dynamic> json) {
    return KendaraanModel(
      idKendaraan: int.tryParse(json['id_kendaraan']?.toString() ?? '0') ?? 0,
      jenisKendaraan: json['jenis_kendaraan']?.toString() ?? '',
      platNomor: json['plat_nomor']?.toString() ?? '',
      warna: json['warna']?.toString() ?? '',
      pemilik: json['pemilik']?.toString() ?? '',
      idUser: int.tryParse(json['id_user']?.toString() ?? '0') ?? 0,
      namaPendaftar: json['nama_pendaftar']?.toString() ?? '',
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
      'nama_pendaftar': namaPendaftar,
    };

  }

  String get displayName => '$jenisKendaraan - $platNomor';
}
