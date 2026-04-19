import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../services/refresh_service.dart';

class OwnerChartScreen extends StatefulWidget {
  const OwnerChartScreen({super.key});

  @override
  State<OwnerChartScreen> createState() => _OwnerChartScreenState();
}

class _OwnerChartScreenState extends State<OwnerChartScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  // Filter waktu
  String _selectedPeriod = 'today'; // today, week, month, custom
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadDashboard({bool silent = false}) async {
    setState(() {
      if (!silent) _isLoading = true;
      _error = null;
    });

    DateTime start;
    DateTime end = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'today':
        start = DateTime(end.year, end.month, end.day);
        break;
      case 'week':
        start = end.subtract(const Duration(days: 7));
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
          ? const LoadingWidget(message: 'Memuat data grafik...')
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
                              const SizedBox(height: 32),
                              _buildCharts(),
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
                      "Grafik",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      "Analisis Visual - $periodText",
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.bar_chart_rounded, color: Colors.white),
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
        const Text(
          "Pilih Periode Grafik",
          style: TextStyle(
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

  Widget _buildCharts() {
    final transactions = _stats?['transaksi'] as List<dynamic>? ?? [];
    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(32),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada data grafik untuk periode ini',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isToday = _selectedPeriod == 'today';
    
    Map<DateTime, List<num>> rawData = {};
    for (var tx in transactions) {
      final masukStr = tx['waktu_masuk'];
      if (masukStr == null) continue;
      final masuk = DateTime.tryParse(masukStr)?.toLocal() ?? DateTime.now();
      
      DateTime keyDate;
      if (isToday) {
        keyDate = DateTime(masuk.year, masuk.month, masuk.day, masuk.hour);
      } else {
        keyDate = DateTime(masuk.year, masuk.month, masuk.day);
      }
      
      final biayaStr = tx['biaya_total']?.toString() ?? '0';
      final biaya = num.tryParse(biayaStr) ?? 0;
      
      if (!rawData.containsKey(keyDate)) {
        rawData[keyDate] = [0, 0];
      }
      rawData[keyDate]![0] += 1;
      rawData[keyDate]![1] += biaya;
    }

    List<DateTime> sortedDates = rawData.keys.toList()..sort();
    
    double maxKendaraan = 0;
    double maxPendapatan = 0;
    for (var date in sortedDates) {
      if (rawData[date]![0] > maxKendaraan) maxKendaraan = rawData[date]![0].toDouble();
      if (rawData[date]![1] > maxPendapatan) maxPendapatan = rawData[date]![1].toDouble();
    }
    
    if (maxKendaraan == 0) maxKendaraan = 5;
    if (maxPendapatan == 0) maxPendapatan = 50000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Grafik Kendaraan Masuk",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        _buildBarChart(
          sortedDates, 
          rawData, 
          0, 
          maxKendaraan * 1.2,
          AppColors.primary,
          isToday
        ),
        const SizedBox(height: 32),
        Text(
          "Grafik Pendapatan",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        _buildBarChart(
          sortedDates, 
          rawData, 
          1, 
          maxPendapatan * 1.2,
          AppColors.success,
          isToday,
          isCurrency: true
        ),
      ],
    );
  }

  Widget _buildBarChart(List<DateTime> sortedDates, Map<DateTime, List<num>> rawData, int dataIndex, double maxY, Color color, bool isToday, {bool isCurrency = false}) {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
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
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 final val = rod.toY;
                 String text = isCurrency 
                   ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(val)
                   : val.toInt().toString();
                 return BarTooltipItem(
                   text,
                   const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                 );
              }
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value < 0 || value >= sortedDates.length) return const SizedBox.shrink();
                  final date = sortedDates[value.toInt()];
                  String text = isToday ? DateFormat('HH:mm').format(date) : DateFormat('dd MMM').format(date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(text, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value == maxY || value == 0) return const SizedBox.shrink();
                  String text = isCurrency 
                    ? NumberFormat.compact(locale: 'id_ID').format(value)
                    : value.toInt().toString();
                  return Text(text, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                },
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(sortedDates.length, (index) {
            final date = sortedDates[index];
            final val = rawData[date]![dataIndex].toDouble();
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: color,
                  width: 16,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                )
              ],
            );
          }),
        ),
      ),
    );
  }
}
