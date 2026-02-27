import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../services/refresh_service.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;
  String _userName = 'Admin';
  Timer? _refreshTimer;


  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadDashboard();
    RefreshService.instance.addListener(_onRefreshTriggered);
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadDashboard(silent: true);
      }
    });
  }


  void _onRefreshTriggered() {
    if (mounted) {
      _loadDashboard(silent: false);
    }
  }



  @override
  void dispose() {
    _refreshTimer?.cancel();
    RefreshService.instance.removeListener(_onRefreshTriggered);
    super.dispose();
  }




  Future<void> _loadUserName() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _userName = user['nama_lengkap'] ?? 'Admin';
      });
    }
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    setState(() {
      if (!silent) _isLoading = true;
      _error = null;
    });


    final result = await AdminService.getDashboardAdmin();

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _dashboardData = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat dashboard...')
          : _error != null
              ? ErrorDisplayWidget(message: _error ?? 'Terjadi kesalahan', onRetry: _loadDashboard)
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatGrid(),
                              const SizedBox(height: 32),
                              Text(
                                "Aktivitas Terakhir",
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              _buildRecentActivityList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Halo, $_userName!",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      "Kelola sistem parkir Anda",
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2);
  }

  Widget _buildStatGrid() {
    final users = _dashboardData?['users'] ?? {};
    final area = _dashboardData?['area'] ?? {};
    final kendaraan = _dashboardData?['kendaraan'] ?? {};
    final tarif = _dashboardData?['tarif'] ?? {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          "Total Users",
          users['total_users']?.toString() ?? '0',
          Icons.people_rounded,
          AppColors.primary,
        ).animate().scale(delay: 200.ms),
        _buildStatCard(
          "Area Parkir",
          area['total_area']?.toString() ?? '0',
          Icons.map_rounded,
          AppColors.success,
        ).animate().scale(delay: 400.ms),
        _buildStatCard(
          "Kendaraan",
          kendaraan['total_kendaraan']?.toString() ?? '0',
          Icons.directions_car_rounded,
          AppColors.accent,
        ).animate().scale(delay: 600.ms),
        _buildStatCard(
          "Tarif",
          tarif['total_tarif']?.toString() ?? '0',
          Icons.attach_money_rounded,
          Colors.orange,
        ).animate().scale(delay: 800.ms),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final logs = _dashboardData?['recent_logs'] as List<dynamic>? ?? [];

    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Belum ada aktivitas',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final waktu = DateTime.tryParse(log['waktu_aktivitas'] ?? '') ?? DateTime.now();
        final timeStr = DateFormat('HH:mm').format(waktu);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['nama_lengkap'] ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      log['aktivitas'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ).animate().fade(delay: (200 * index).ms).slideX(begin: 0.1);
      },
    );
  }
}
