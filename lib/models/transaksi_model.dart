/**
 * Model Data Transaksi Parkir
 * Menangani mapping data riwayat parkir, termasuk informasi JOIN dari
 * kendaraan, area, dan tarif.
 */
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
  final int? tarifNambah;

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
    this.tarifNambah,
  });

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    return TransaksiModel(
      idParkir: int.tryParse(json['id_parkir']?.toString() ?? '0') ?? 0,
      idKendaraan: int.tryParse(json['id_kendaraan']?.toString() ?? '0') ?? 0,
      idTarif: int.tryParse(json['id_tarif']?.toString() ?? '0') ?? 0,
      idArea: int.tryParse(json['id_area']?.toString() ?? '0') ?? 0,
      idUser: int.tryParse(json['id_user']?.toString() ?? '0') ?? 0,
      waktuMasuk: DateTime.tryParse(json['waktu_masuk']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      waktuKeluar: json['waktu_keluar'] != null 
          ? DateTime.tryParse(json['waktu_keluar'].toString())?.toLocal()
          : null,
      durasiJam: json['durasi_jam'] != null 
          ? int.tryParse(json['durasi_jam'].toString()) 
          : null,
      biayaTotal: json['biaya_total'] != null 
          ? int.tryParse(json['biaya_total'].toString()) 
          : null,
      status: json['status']?.toString() ?? 'masuk',
      platNomor: json['plat_nomor']?.toString(),
      jenisKendaraan: json['jenis_kendaraan']?.toString(),
      namaArea: json['nama_area']?.toString(),
      namaPetugas: (json['nama_petugas'] ?? json['petugas_nama'])?.toString(),
      tarifNambah: json['tarif_nambah'] != null 
          ? int.tryParse(json['tarif_nambah'].toString()) 
          : null,
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
