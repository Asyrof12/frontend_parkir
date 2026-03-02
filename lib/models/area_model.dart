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
      idArea: int.tryParse(json['id_area']?.toString() ?? '0') ?? 0,
      namaArea: json['nama_area']?.toString() ?? '',
      kapasitas: int.tryParse(json['kapasitas']?.toString() ?? '0') ?? 0,
      terisi: int.tryParse(json['terisi']?.toString() ?? '0') ?? 0,
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
