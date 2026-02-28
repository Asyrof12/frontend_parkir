import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

/**
 * Entry point utama aplikasi UKK Parkir.
 * Mengatur tema global dan halaman awal (Splash Screen).
 */
import 'utils/app_theme.dart';
import 'screens/shared/splash_screen.dart';

/// Fungsi utama yang menjalankan aplikasi Flutter.
/// Memastikan inisialisasi widget Flutter dan kemudian menjalankan MyApp.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}



/// Kelas utama aplikasi Flutter.
/// Mengatur konfigurasi dasar aplikasi seperti judul, tema, dan halaman awal.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UKK Parkir',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
