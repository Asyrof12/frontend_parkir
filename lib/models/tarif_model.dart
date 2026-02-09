class TarifModel {
  final int idTarif;
  final String jenisKendaraan;
  final int tarifPerJam;

  TarifModel({
    required this.idTarif,
    required this.jenisKendaraan,
    required this.tarifPerJam,
  });

  factory TarifModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return TarifModel(
      idTarif: parseInt(json['id_tarif'] ?? json['idTarif'] ?? json['id']),

      jenisKendaraan:
          json['jenis_kendaraan'] ??
          json['jenisKendaraan'] ??
          json['jenis'] ??
          '',

      tarifPerJam: parseInt(
        json['tarif_per_jam'] ?? json['tarifPerJam'] ?? json['tarif'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tarif': idTarif,
      'jenis_kendaraan': jenisKendaraan,
      'tarif_per_jam': tarifPerJam,
    };
  }

  String get formattedTarif {
    return 'Rp ${tarifPerJam.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}
