import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/api_service.dart';
import '../services/refresh_service.dart';


// Shared screens
import 'shared/profile_screen.dart';

// Admin screens
import 'admin/admin_dashboard_screen.dart';
import 'admin/user_management_screen.dart';
import 'admin/tarif_management_screen.dart';
import 'admin/area_management_screen.dart';
import 'admin/vehicles_screen.dart';
import 'admin/log_activity_screen.dart';

// Petugas screens
import 'petugas/petugas_dashboard_screen.dart';
import 'petugas/transaction_screen.dart';
import 'petugas/petugas_history_screen.dart';

// Owner screens
import 'owner/owner_dashboard_screen.dart';
import 'owner/owner_history_screen.dart';

/**
 * Cangkang Utama Aplikasi (Navigation Shell)
 * Menampilkan Bottom Navigation Bar yang berbeda-beda tergantung peran 
 * (Role) user yang sedang login (Admin, Petugas, atau Owner).
 */


class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  String _userRole = 'petugas'; // Default role
  bool _isLoading = true;



  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() {
        if (user != null) {
          _userRole = user['role'] ?? 'petugas';
        }
        _isLoading = false;
      });
    }
  }

  List<_NavItem> get _navItems {


    switch (_userRole) {
      case 'admin':
        return [
          _NavItem(Icons.dashboard_rounded, 'Dashboard', AdminDashboardScreen()),
          _NavItem(Icons.people_rounded, 'Users', UserManagementScreen()),
          _NavItem(Icons.attach_money_rounded, 'Tarif', TarifManagementScreen()),
          _NavItem(Icons.map_rounded, 'Area', AreaManagementScreen()),
          _NavItem(Icons.directions_car_rounded, 'Kendaraan', VehiclesScreen()),
          _NavItem(Icons.history_rounded, 'Log', LogActivityScreen()),
          _NavItem(Icons.person_rounded, 'Profil', ProfileScreen()),
        ];
      case 'petugas':
        return [
          _NavItem(Icons.dashboard_rounded, 'Dashboard', PetugasDashboardScreen()),
          _NavItem(Icons.local_parking_rounded, 'Transaksi', TransactionScreen()),
          _NavItem(Icons.history_rounded, 'Riwayat', PetugasHistoryScreen()),
          _NavItem(Icons.person_rounded, 'Profil', ProfileScreen()),
        ];
      case 'owner':
        return [
          _NavItem(Icons.dashboard_rounded, 'Dashboard', OwnerDashboardScreen()),
          _NavItem(Icons.assessment_rounded, 'Rekap', OwnerHistoryScreen()),
          _NavItem(Icons.person_rounded, 'Profil', ProfileScreen()),
        ];
      default:
        return [
          _NavItem(Icons.dashboard_rounded, 'Dashboard', PetugasDashboardScreen()),
          _NavItem(Icons.person_rounded, 'Profil', ProfileScreen()),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final navItems = _navItems;



    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: navItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                navItems.length,
                (index) => Expanded(
                  child: _buildNavItem(
                    index,
                    navItems[index].icon,
                    navItems[index].label,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        // Trigger refresh otomatis untuk semua halaman
        RefreshService.instance.refreshDashboard();

      },

      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;

  _NavItem(this.icon, this.label, this.screen);
}
