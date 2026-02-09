class AreaModel {
  final int idArea;
  final String namaArea;
  final int kapasitas;
  final int terisi;

  AreaModel({
    required this.idArea,
    required this.namaArea,
    required this.kapasitas,
    required this.terisi,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      idArea: json['id_area'] ?? 0,
      namaArea: json['nama_area'] ?? '',
      kapasitas: json['kapasitas'] ?? 0,
      terisi: json['terisi'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_area': idArea,
      'nama_area': namaArea,
      'kapasitas': kapasitas,
      'terisi': terisi,
    };
  }

  int get tersedia => kapasitas - terisi;
  
  double get persentaseTerisi {
    if (kapasitas == 0) return 0;
    return (terisi / kapasitas) * 100;
  }

  bool get isFull => terisi >= kapasitas;
}
