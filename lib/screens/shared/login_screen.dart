import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../utils/notifications.dart';
import '../main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      AppNotification.success(context, 'Login berhasil. Selamat datang!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainShell()),
        (route) => false,
      );
    } else {
      AppNotification.error(context, result['message']);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(height: 32),
                Text(
                  "Selamat\nDatang Kembali!",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                ).animate().fade().slideX(begin: -0.1),
                const SizedBox(height: 12),
                Text(
                  "Silakan masuk ke akun Anda untuk melanjutkan.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fade(delay: 200.ms),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => (value?.isEmpty ?? true) ? "Username wajib diisi" : null,
                ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ),
                  validator: (value) => (value?.length ?? 0) < 4 ? "Password minimal 4 karakter" : null,
                ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Masuk"),
                ).animate().fade(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
