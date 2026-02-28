import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../services/refresh_service.dart';
import '../../services/struk_service.dart';


class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;
  String _userName = 'Owner';
  Timer? _refreshTimer;

  
  // Filter waktu
  String _selectedPeriod = 'today'; // today, week, month, custom
  DateTime? _startDate;
  DateTime? _endDate;

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
        _userName = user['nama_lengkap'] ?? 'Owner';
      });
    }
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    setState(() {
      if (!silent) _isLoading = true;
      _error = null;
    });


    // Tentukan tanggal berdasarkan filter
    DateTime start;
    DateTime end = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'today':
        start = DateTime(end.year, end.month, end.day);
        break;
      case 'week':
        start = end.subtract(Duration(days: 7));
        break;
      case 'month':
        start = DateTime(end.year, end.month, 1);
        break;
      case 'custom':
        if (_startDate == null || _endDate == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        start = _startDate!;
        end = _endDate!;
        break;
      default:
        start = DateTime(end.year, end.month, end.day);
    }

    final result = await OwnerService.getRekapTransaksi(
      DateFormat('yyyy-MM-dd').format(start),
      DateFormat('yyyy-MM-dd').format(end),
    );

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _stats = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat rekap transaksi...')
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
                              _buildPeriodSelector(),
                              const SizedBox(height: 24),
                              _buildStatCards(),
                              const SizedBox(height: 32),
                              Text(
                                "Detail Transaksi",
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              _buildTransactionList(),
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
    String periodText = '';
    switch (_selectedPeriod) {
      case 'today':
        periodText = 'Hari Ini';
        break;
      case 'week':
        periodText = '7 Hari Terakhir';
        break;
      case 'month':
        periodText = 'Bulan Ini';
        break;
      case 'custom':
        if (_startDate != null && _endDate != null) {
          periodText = '${DateFormat('dd MMM').format(_startDate ?? DateTime.now())} - ${DateFormat('dd MMM yyyy').format(_endDate ?? DateTime.now())}';
        }
        break;
    }

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
                      "Rekap Transaksi - $periodText",
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.business_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2);
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pilih Periode",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPeriodChip('Hari Ini', 'today'),
              const SizedBox(width: 8),
              _buildPeriodChip('7 Hari', 'week'),
              const SizedBox(width: 8),
              _buildPeriodChip('Bulan Ini', 'month'),
              const SizedBox(width: 8),
              _buildCustomDateChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
          _startDate = null;
          _endDate = null;
        });
        _loadDashboard();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip() {
    final isSelected = _selectedPeriod == 'custom';
    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'Custom',
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final totalTransaksi = _stats?['total_transaksi'] ?? 0;
    final kendaraanMasuk = _stats?['kendaraan_masuk'] ?? 0;
    final kendaraanKeluar = _stats?['kendaraan_keluar'] ?? 0;
    final totalPendapatan = _stats?['total_pendapatan'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Transaksi',
                totalTransaksi.toString(),
                Icons.receipt_long_rounded,
                AppColors.primary,
              ).animate().scale(delay: 200.ms),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRevenueCard(
                'Total Pendapatan',
                totalPendapatan,
              ).animate().scale(delay: 400.ms),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Kendaraan Masuk',
                kendaraanMasuk.toString(),
                Icons.login_rounded,
                AppColors.success,
              ).animate().scale(delay: 600.ms),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Kendaraan Keluar',
                kendaraanKeluar.toString(),
                Icons.logout_rounded,
                AppColors.accent,
              ).animate().scale(delay: 800.ms),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String title, dynamic amount) {
    final revenue = num.tryParse(amount.toString()) ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.attach_money_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp',
              decimalDigits: 0,
            ).format(revenue),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = _stats?['transaksi'] as List<dynamic>? ?? [];

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada transaksi',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final waktuMasuk = DateTime.tryParse(transaction['waktu_masuk'] ?? '') ?? DateTime.now();
        final waktuKeluar = transaction['waktu_keluar'] != null
            ? DateTime.tryParse(transaction['waktu_keluar'] ?? '')
            : null;
        
        final duration = waktuKeluar != null
            ? waktuKeluar.difference(waktuMasuk)
            : Duration.zero;
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction['plat_nomor'] ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${transaction['jenis_kendaraan'] ?? ''} - ${transaction['nama_area'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (transaction['biaya_total'] != null)
                    Row(
                      children: [
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp',
                            decimalDigits: 0,
                          ).format(num.tryParse(transaction['biaya_total']?.toString() ?? '0') ?? 0),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.print_outlined, size: 18, color: AppColors.textSecondary),
                          onPressed: () => _printIndividualReceipt(transaction),
                          tooltip: 'Cetak Struk',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.login_rounded, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(waktuMasuk),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (waktuKeluar != null)
                    Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM, HH:mm').format(waktuKeluar),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  if (waktuKeluar != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${hours}h ${minutes}m',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ).animate().fade(delay: (100 * index).ms).slideX(begin: 0.1);
      },
    );
  }

  Future<void> _printIndividualReceipt(Map<String, dynamic> transaction) async {
    try {
      final user = await AuthService.getUser();
      final namaPetugas = user?['nama_lengkap'] ?? 'Petugas';
      
      final waktuMasuk = DateTime.tryParse(transaction['waktu_masuk'] ?? '') ?? DateTime.now();
      final waktuKeluar = transaction['waktu_keluar'] != null
          ? DateTime.tryParse(transaction['waktu_keluar'])
          : DateTime.now();
          
      final duration = waktuKeluar!.difference(waktuMasuk);
      int durasiJam = (duration.inMinutes / 60).ceil();
      if (durasiJam < 1) durasiJam = 1;

      final pdf = await StrukService.generateStrukKeluar(
        idParkir: transaction['id_parkir'] as int,
        platNomor: transaction['plat_nomor'] ?? '-',
        jenisKendaraan: transaction['jenis_kendaraan'] ?? '-',
        namaArea: transaction['nama_area'] ?? '-',
        tarifAwal: 'Rp -',
        tarifNambah: 'Rp -',
        waktuMasuk: waktuMasuk,
        waktuKeluar: waktuKeluar,
        durasiJam: durasiJam,
        biayaTotal: num.tryParse(transaction['biaya_total']?.toString() ?? '0')?.toInt() ?? 0,
        namaPetugas: namaPetugas,
      );

      await StrukService.printStruk(pdf, 'Struk_${transaction['id_parkir']}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak struk: $e')),
      );
    }
  }
}
