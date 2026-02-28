/**
 * Model Data User
 * Digunakan untuk mapping data profil user dari API ke objek Dart.
 */
class UserModel {
  final int idUser;
  final String namaLengkap;
  final String username;
  final String role;
  final int statusAktif;

  UserModel({
    required this.idUser,
    required this.namaLengkap,
    required this.username,
    required this.role,
    required this.statusAktif,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: json['id_user'] ?? 0,
      namaLengkap: json['nama_lengkap'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      statusAktif: json['status_aktif'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'nama_lengkap': namaLengkap,
      'username': username,
      'role': role,
      'status_aktif': statusAktif,
    };
  }

  bool get isActive => statusAktif == 1;
  
  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'petugas':
        return 'Petugas';
      case 'owner':
        return 'Owner';
      default:
        return role;
    }
  }
}
