import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/transaksi_model.dart';
import '../../services/owner_service.dart';
import '../../services/struk_service.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';

class OwnerHistoryScreen extends StatefulWidget {
  const OwnerHistoryScreen({super.key});

  @override
  State<OwnerHistoryScreen> createState() => _OwnerHistoryScreenState();
}

class _OwnerHistoryScreenState extends State<OwnerHistoryScreen> {
  List<TransaksiModel> _transactions = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedRange = 'Hari Ini';

  @override
  void initState() {
    super.initState();
    _loadRekap();
  }

  Future<void> _loadRekap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

    final result = await OwnerService.getRekapTransaksi(startStr, endStr);

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _stats = result['data'];
        _transactions = (result['data']['transaksi'] as List)
            .map((json) => TransaksiModel.fromJson(json))
            .where((t) => t.status == 'keluar') // Rekap biasanya fokus pada yang sudah selesai
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  void _changeRange(String range) {
    setState(() {
      _selectedRange = range;
      final now = DateTime.now();
      if (range == 'Hari Ini') {
        _startDate = now;
        _endDate = now;
      } else if (range == '7 Hari Terakhir') {
        _startDate = now.subtract(const Duration(days: 6));
        _endDate = now;
      } else if (range == 'Bulan Ini') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      }
    });
    _loadRekap();
  }

  Future<void> _selectCustomDate() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedRange = 'Kustom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadRekap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Rekap Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _transactions.isEmpty ? null : _generatePdf,
            tooltip: 'Download Laporan A4',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRekap,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Memproses laporan...')
                : _error != null
                    ? ErrorDisplayWidget(message: _error!, onRetry: _loadRekap)
                    : _transactions.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.assignment_rounded,
                            title: 'Tidak Ada Data',
                            message: 'Tidak ada transaksi selesai pada periode ini',
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSummaryStats(),
                                  const SizedBox(height: 24),
                                  _buildBreakdowns(),
                                  const SizedBox(height: 32),
                                  _buildTransactionListHeader(),
                                  const SizedBox(height: 12),
                                  _buildTransactionList(),
                                ],
                              ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('Hari Ini'),
            _buildFilterChip('7 Hari Terakhir'),
            _buildFilterChip('Bulan Ini'),
            _buildFilterChip('Kustom', isAction: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isAction = false}) {
    bool isSelected = _selectedRange == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (isAction) {
            _selectCustomDate();
          } else {
            _changeRange(label);
          }
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final pendapatan = _stats['total_pendapatan'] ?? 0;
    final rataRata = _stats['rata_rata_harian'] ?? 0;
    final total = _stats['kendaraan_keluar'] ?? 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Pendapatan',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(pendapatan),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: Colors.white24,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('Rata-rata/Hari', NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ').format(rataRata)),
                  _buildMiniStat('Total Kendaraan', total.toString()),
                  _buildMiniStat('Periode', '${_stats['days'] ?? 1} Hari'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildBreakdowns() {
    final breakdownKendaraan = _stats['breakdown_kendaraan'] ?? {};
    final breakdownArea = _stats['breakdown_area'] ?? {};

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildBreakdownCard(
            'Jenis Kendaraan',
            Icons.directions_car_rounded,
            [
              _buildBreakdownRow('Motor', breakdownKendaraan['motor']?['count'] ?? 0, breakdownKendaraan['motor']?['pendapatan'] ?? 0),
              _buildBreakdownRow('Mobil', breakdownKendaraan['mobil']?['count'] ?? 0, breakdownKendaraan['mobil']?['pendapatan'] ?? 0),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBreakdownCard(
            'Per Area',
            Icons.map_rounded,
            (breakdownArea as Map).entries.map((e) {
              return _buildBreakdownRow(e.key, e.value['count'], e.value['pendapatan']);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(String title, IconData icon, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int count, dynamic revenue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(count.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(revenue),
            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (_stats['total_pendapatan'] ?? 0) > 0 
                ? (revenue / _stats['total_pendapatan']) 
                : 0,
            backgroundColor: Colors.grey[100],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.5)),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Detail Transaksi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text(
          '${_transactions.length} Selesai',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final t = _transactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.platNomor ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${t.jenisKendaraan} • ${t.namaArea}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(t.biayaTotal ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Text(
                    DateFormat('dd/MM HH:mm').format(t.waktuKeluar ?? DateTime.now()),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.print_outlined, size: 20, color: AppColors.textSecondary),
                onPressed: () => _printIndividualReceipt(t),
                tooltip: 'Cetak Struk',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _printIndividualReceipt(TransaksiModel t) async {
    try {
      // Get user info for petugas name
      final user = await AuthService.getUser();
      final namaPetugas = user?['nama_lengkap'] ?? 'Petugas';
      
      // Hitung durasi dan jam tambahan untuk struk
      final duration = (t.waktuKeluar ?? DateTime.now()).difference(t.waktuMasuk);
      int durasiMenit = duration.inMinutes;
      int durasiJam = (durasiMenit / 60).ceil();
      if (durasiJam < 1) durasiJam = 1;
      int jamTambahan = durasiJam - 1;

      final pdf = await StrukService.generateStrukKeluar(
        idParkir: t.idParkir,
        platNomor: t.platNomor ?? '-',
        jenisKendaraan: t.jenisKendaraan ?? '-',
        namaArea: t.namaArea ?? '-',
        tarifAwal: 'Rp -', // Info tarif tidak ada di rekap, pakai '-' 
        tarifNambah: 'Rp -',
        waktuMasuk: t.waktuMasuk,
        waktuKeluar: t.waktuKeluar ?? DateTime.now(),
        durasiJam: durasiJam,
        biayaTotal: t.biayaTotal ?? 0,
        namaPetugas: namaPetugas,
      );

      await StrukService.printStruk(pdf, 'Struk_${t.idParkir}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak struk: $e')),
      );
    }
  }

  Future<void> _generatePdf() async {
    final doc = pw.Document();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4, // Kunci ke format A4
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Laporan Rekap Transaksi Parkir', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Periode: ${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}'),
          pw.SizedBox(height: 20),
          
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              children: [
                _buildPdfRow('Total Pendapatan', fmt.format(_stats['total_pendapatan'] ?? 0)),
                _buildPdfRow('Total Kendaraan', (_stats['kendaraan_keluar'] ?? 0).toString()),
                _buildPdfRow('Rata-rata/Hari', fmt.format(_stats['rata_rata_harian'] ?? 0)),
              ],
            ),
          ),
          
          pw.SizedBox(height: 30),
          pw.Text('Detail Transaksi', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          
          // Table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Waktu', 'Plat Nomor', 'Jenis', 'Area', 'Biaya'],
            data: _transactions.map((t) => [
              DateFormat('dd/MM HH:mm').format(t.waktuKeluar!),
              t.platNomor ?? 'N/A',
              t.jenisKendaraan ?? '-',
              t.namaArea ?? '-',
              fmt.format(t.biayaTotal ?? 0),
            ]).toList(),
          ),
        ],
      ),
    );

    // Langsung panggil layoutPdf tanpa print preview yang ribet
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Rekap_Parkir_${DateFormat('yyyyMMdd').format(_startDate)}.pdf',
      format: PdfPageFormat.a4,
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
