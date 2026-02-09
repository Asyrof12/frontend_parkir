class FormValidators {
  static String? required(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? minLength(String? value, int length, [String fieldName = 'Field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    if (value.length < length) {
      return '$fieldName minimal $length karakter';
    }
    return null;
  }

  static String? number(String? value, [String fieldName = 'Field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    if (int.tryParse(value) == null) {
      return '$fieldName harus berupa angka';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String fieldName = 'Field']) {
    final numberError = number(value, fieldName);
    if (numberError != null) return numberError;
    
    if (value == null || (int.tryParse(value) ?? 0) <= 0) {
      return '$fieldName harus lebih dari 0';
    }
    return null;
  }

  static String? platNomor(String? value) {
    if (value == null || value.isEmpty) {
      return 'Plat nomor wajib diisi';
    }
    // Basic validation for Indonesian plate number format
    if (value.length < 3) {
      return 'Plat nomor tidak valid';
    }
    return null;
  }
}
