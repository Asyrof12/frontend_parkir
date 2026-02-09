class TransaksiModel {
  final int idParkir;
  final int idKendaraan;
  final int idTarif;
  final int idArea;
  final int idUser;
  final DateTime waktuMasuk;
  final DateTime? waktuKeluar;
  final int? durasiJam;
  final int? biayaTotal;
  final String status;
  
  // Additional fields from JOIN query
  final String? platNomor;
  final String? jenisKendaraan;
  final String? namaArea;
  final String? namaPetugas;

  TransaksiModel({
    required this.idParkir,
    required this.idKendaraan,
    required this.idTarif,
    required this.idArea,
    required this.idUser,
    required this.waktuMasuk,
    this.waktuKeluar,
    this.durasiJam,
    this.biayaTotal,
    required this.status,
    this.platNomor,
    this.jenisKendaraan,
    this.namaArea,
    this.namaPetugas,
  });

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    return TransaksiModel(
      idParkir: json['id_parkir'] ?? 0,
      idKendaraan: json['id_kendaraan'] ?? 0,
      idTarif: json['id_tarif'] ?? 0,
      idArea: json['id_area'] ?? 0,
      idUser: json['id_user'] ?? 0,
      waktuMasuk: DateTime.tryParse(json['waktu_masuk']?.toString() ?? '') ?? DateTime.now(),
      waktuKeluar: json['waktu_keluar'] != null 
          ? DateTime.tryParse(json['waktu_keluar'].toString()) 
          : null,
      durasiJam: json['durasi_jam'] != null 
          ? int.tryParse(json['durasi_jam'].toString()) 
          : null,
      biayaTotal: json['biaya_total'] != null 
          ? int.tryParse(json['biaya_total'].toString()) 
          : null,
      status: json['status'] ?? 'masuk',
      platNomor: json['plat_nomor'],
      jenisKendaraan: json['jenis_kendaraan'],
      namaArea: json['nama_area'],
      namaPetugas: json['nama_petugas'] ?? json['petugas_nama'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_parkir': idParkir,
      'id_kendaraan': idKendaraan,
      'id_tarif': idTarif,
      'id_area': idArea,
      'id_user': idUser,
      'waktu_masuk': waktuMasuk.toIso8601String(),
      'waktu_keluar': waktuKeluar?.toIso8601String(),
      'durasi_jam': durasiJam,
      'biaya_total': biayaTotal,
      'status': status,
    };
  }

  bool get isActive => status == 'masuk';
  
  String get formattedBiaya {
    if (biayaTotal == null) return '-';
    return 'Rp ${biayaTotal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String get formattedDurasi {
    if (durasiJam == null) return '-';
    return '$durasiJam jam';
  }
}
