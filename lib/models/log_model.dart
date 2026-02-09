class LogModel {
  final int idLog;
  final int idUser;
  final String aktivitas;
  final DateTime waktu;
  
  // Additional field from JOIN query
  final String? namaUser;

  LogModel({
    required this.idLog,
    required this.idUser,
    required this.aktivitas,
    required this.waktu,
    this.namaUser,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      idLog: json['id_log'] ?? 0,
      idUser: json['id_user'] ?? 0,
      aktivitas: json['aktivitas'] ?? '',
      waktu: DateTime.tryParse(json['waktu'] ?? '') ?? DateTime.now(),
      namaUser: json['nama_user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_log': idLog,
      'id_user': idUser,
      'aktivitas': aktivitas,
      'waktu': waktu.toIso8601String(),
    };
  }
}
