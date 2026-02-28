import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/transaksi_model.dart';
import '../../models/kendaraan_model.dart';
import '../../models/tarif_model.dart';
import '../../models/area_model.dart';
import '../../services/api_service.dart';
import '../../services/struk_service.dart';
import '../../utils/colors.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/notifications.dart';
import '../../services/refresh_service.dart';



class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Parkir'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Kendaraan Masuk', icon: Icon(Icons.login_rounded)),
            Tab(text: 'Kendaraan Keluar', icon: Icon(Icons.logout_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [TransaksiMasukTab(), TransaksiKeluarTab()],
      ),
    );
  }
}

// ==================== TAB KENDARAAN MASUK ====================

class TransaksiMasukTab extends StatefulWidget {
  const TransaksiMasukTab({super.key});

  @override
  State<TransaksiMasukTab> createState() => _TransaksiMasukTabState();
}

class _TransaksiMasukTabState extends State<TransaksiMasukTab> {
  final _formKey = GlobalKey<FormState>();

  List<KendaraanModel> _kendaraanList = [];
  List<TarifModel> _tarifList = [];
  List<AreaModel> _areaList = [];

  int? _selectedKendaraan;
  int? _selectedTarif;
  int? _selectedArea;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        KendaraanService.getKendaraan(),
        TarifService.getTarif(),
        AreaService.getAreas(),
      ]);

      if (!mounted) return;

      // Debug: Print results to see structure
      print('Kendaraan result: ${results[0]}');
      print('Tarif result: ${results[1]}');
      print('Area result: ${results[2]}');

      if (results.every((r) => r != null && r['success'] == true)) {
        setState(() {
          _kendaraanList =
              (results[0]?['data'] as List?)
                  ?.map((json) => KendaraanModel.fromJson(json))
                  .toList() ??
              [];
          _tarifList =
              (results[1]?['data'] as List?)
                  ?.map((json) => TarifModel.fromJson(json))
                  .toList() ??
              [];
          _areaList =
              (results[2]?['data'] as List?)
                  ?.map((json) => AreaModel.fromJson(json))
                  .toList() ??
              [];
          _isLoading = false;
        });
      } else {
        // Find which API failed
        String errorMsg = 'Gagal memuat data: ';
        if (results[0] == null || results[0]?['success'] != true) {
          errorMsg += 'Kendaraan ';
        }
        if (results[1] == null || results[1]?['success'] != true) {
          errorMsg += 'Tarif ';
        }
        if (results[2] == null || results[2]?['success'] != true) {
          errorMsg += 'Area ';
        }

        setState(() {
          _error = errorMsg;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Koneksi gagal: $e';
        _isLoading = false;
      });
      print('Error loading data: $e');
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSubmitting = true);

    final data = {
      'id_kendaraan': _selectedKendaraan,
      'id_tarif': _selectedTarif,
      'id_area': _selectedArea,
    };

    final result = await TransaksiService.transaksiMasuk(data);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result['success']) {
      AppNotification.success(context, 'Kendaraan berhasil terdaftar masuk');
      _showStrukDialog(result['data']);
      _formKey.currentState?.reset();
      setState(() {
        _selectedKendaraan = null;
        _selectedTarif = null;
        _selectedArea = null;
      });
      // Reload data to refresh area slot counts
      _loadData();
      RefreshService.instance.refreshDashboard();

    } else {
      AppNotification.error(context, result['message']);
    }

  }

  Future<void> _showStrukDialog(Map<String, dynamic> data) async {
    try {
      final kendaraan = _kendaraanList.firstWhere(
        (k) => k.idKendaraan == _selectedKendaraan,
        orElse: () => throw Exception('Kendaraan tidak ditemukan'),
      );
      final area = _areaList.firstWhere(
        (a) => a.idArea == _selectedArea,
        orElse: () => throw Exception('Area tidak ditemukan'),
      );
      final tarif = _tarifList.firstWhere(
        (t) => t.idTarif == _selectedTarif,
        orElse: () => throw Exception('Tarif tidak ditemukan'),
      );

      // Get user info for petugas name
      final user = await AuthService.getUser();
      final namaPetugas = user?['nama_lengkap'] ?? 'Petugas';

      // CETAK OTOMATIS: Langsung panggil fungsi print tanpa nunggu klik tombol
      try {
        final pdf = await StrukService.generateStrukMasuk(
          idParkir: data['id_parkir'],
          platNomor: kendaraan.platNomor,
          jenisKendaraan: kendaraan.jenisKendaraan,
          namaArea: area.namaArea,
          tarifPerJam: '${tarif.formattedTarif}/jam',
          waktuMasuk: DateTime.now(),
          namaPetugas: namaPetugas,
        );
        await StrukService.printStruk(
          pdf,
          'Struk_Masuk_${data['id_parkir']}.pdf',
        );
      } catch (e) {
        print('Gagal cetak otomatis: $e');
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Kendaraan Masuk Berhasil')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('ID Parkir: ', style: TextStyle(fontSize: 14)),
                    Text(
                      '#${data['id_parkir']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildStrukRow('Plat Nomor', kendaraan.platNomor),
              _buildStrukRow('Jenis', kendaraan.jenisKendaraan),
              _buildStrukRow('Area', area.namaArea),
              _buildStrukRow('Tarif', '${tarif.formattedTarif}/jam'),
              const Divider(height: 24),
              _buildStrukRow(
                'Waktu Masuk',
                DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
              ),
              _buildStrukRow('Petugas', namaPetugas),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  // Generate PDF struk
                  final pdf = await StrukService.generateStrukMasuk(
                    idParkir: data['id_parkir'],
                    platNomor: kendaraan.platNomor,
                    jenisKendaraan: kendaraan.jenisKendaraan,
                    namaArea: area.namaArea,
                    tarifPerJam: '${tarif.formattedTarif}/jam',
                    waktuMasuk: DateTime.now(),
                    namaPetugas: namaPetugas,
                  );

                  // Print or preview struk
                  await StrukService.printStruk(
                    pdf,
                    'Struk_Masuk_${data['id_parkir']}.pdf',
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                  AppNotification.success(context, 'Struk berhasil dicetak');

                } catch (e) {
                  if (!mounted) return;
                  AppNotification.error(context, 'Gagal mencetak struk: $e');
                }

              },
              icon: const Icon(Icons.print_rounded),
              label: const Text('Cetak Ulang'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppNotification.error(context, 'Error menampilkan struk: $e');
    }

  }

  Widget _buildStrukRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Memuat data...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: _error ?? 'Terjadi kesalahan',
        onRetry: _loadData,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Form Kendaraan Masuk',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedKendaraan,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Kendaraan',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                      ),
                      items: _kendaraanList.map((k) {
                        return DropdownMenuItem(
                          value: k.idKendaraan,
                          child: Text(k.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedKendaraan = value);
                      },
                      validator: (value) =>
                          value == null ? 'Pilih kendaraan' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedTarif,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Tarif',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      items: _tarifList.map((t) {
                        return DropdownMenuItem(
                          value: t.idTarif,
                          child: Text(
                            '${t.jenisKendaraan} - ${t.formattedTarif}/jam',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedTarif = value);
                      },
                      validator: (value) =>
                          value == null ? 'Pilih tarif' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedArea,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Area Parkir',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: _areaList.map((a) {
                        return DropdownMenuItem(
                          value: a.idArea,
                          child: Text('${a.namaArea} (${a.tersedia} tersedia)'),
                          enabled: !a.isFull,
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedArea = value);
                      },
                      validator: (value) => value == null ? 'Pilih area' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        _isSubmitting ? 'Memproses...' : 'Proses Masuk',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TAB KENDARAAN KELUAR ====================

class TransaksiKeluarTab extends StatefulWidget {
  const TransaksiKeluarTab({super.key});

  @override
  State<TransaksiKeluarTab> createState() => _TransaksiKeluarTabState();
}

class _TransaksiKeluarTabState extends State<TransaksiKeluarTab> {
  List<TransaksiModel> _transaksiAktif = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  Future<void> _loadTransaksi() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await TransaksiService.getTransaksi();

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _transaksiAktif =
            (result['data'] as List?)
                ?.map((json) => TransaksiModel.fromJson(json))
                .where((t) => t.isActive)
                .toList() ??
            [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'] ?? 'Gagal memuat transaksi';
        _isLoading = false;
      });
    }
  }

  Future<void> _prosesKeluar(TransaksiModel transaksi) async {
    // Validate that transaksi has all required data
    if (transaksi.platNomor == null ||
        transaksi.jenisKendaraan == null ||
        transaksi.namaArea == null) {
      AppNotification.error(
        context,
        'Data transaksi tidak lengkap. Silakan hubungi admin.',
      );
      return;
    }


    final now = DateTime.now();
    final duration = now.difference(transaksi.waktuMasuk);

    // Get tarif from transaksi
    final tarifResult = await TarifService.getTarifById(transaksi.idTarif);
    if (!tarifResult['success']) {
      if (!mounted) return;
      AppNotification.error(context, 'Gagal mengambil data tarif');
      return;
    }


    if (tarifResult['data'] == null) {
      if (!mounted) return;
      AppNotification.error(context, 'Data tarif tidak ditemukan');
      return;
    }


    final tarif = TarifModel.fromJson(tarifResult['data']);
    
    int durasiMenit = duration.inMinutes;
    int jamTambahan = (durasiMenit / 60).ceil() - 1;
    if (jamTambahan < 0) jamTambahan = 0;
    
    int durasiJam = jamTambahan + 1; // Total hour representation for UI
    int biayaTotal = tarif.tarifPerJam + (jamTambahan * tarif.tarifNambah);

    // Get user info
    final user = await AuthService.getUser();
    final namaPetugas = user?['nama_lengkap'] ?? 'Petugas';

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Konfirmasi Keluar')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Plat Nomor', transaksi.platNomor ?? 'N/A'),
                  const Divider(),
                  _buildInfoRow('Jenis', transaksi.jenisKendaraan ?? 'N/A'),
                  _buildInfoRow('Area', transaksi.namaArea ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Waktu Masuk',
              DateFormat('dd/MM HH:mm').format(transaksi.waktuMasuk),
            ),
            _buildInfoRow(
              'Waktu Keluar',
              DateFormat('dd/MM HH:mm').format(now),
            ),
            _buildInfoRow('Durasi', '$durasiJam jam'),
            const Divider(height: 24),
            _buildInfoRow('Tarif Awal', 'Rp ${tarif.tarifPerJam}'),
            if (jamTambahan > 0)
              _buildInfoRow('Nambah ($jamTambahan jam)', 'Rp ${jamTambahan * tarif.tarifNambah}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL BAYAR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(biayaTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proses Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final data = {'durasi_jam': durasiJam, 'biaya_total': biayaTotal};

    final result = await TransaksiService.transaksiKeluar(
      transaksi.idParkir,
      data,
    );

    if (!mounted) return;

    if (result['success']) {
      AppNotification.success(context, 'Pembayaran berhasil diproses');
      // Show payment receipt dialog with print option
      await _showPaymentReceiptDialog(
        transaksi: transaksi,
        waktuKeluar: now,
        durasiJam: durasiJam,
        biayaTotal: biayaTotal,
        tarif: tarif,
        namaPetugas: namaPetugas,
      );

      _loadTransaksi();
      RefreshService.instance.refreshDashboard();

    } else {
      AppNotification.error(context, result['message']);
    }

  }

  Future<void> _showPaymentReceiptDialog({
    required TransaksiModel transaksi,
    required DateTime waktuKeluar,
    required int durasiJam,
    required int biayaTotal,
    required TarifModel tarif,
    required String namaPetugas,
  }) async {
    final int jamTambahan = durasiJam - 1 > 0 ? durasiJam - 1 : 0;
    
    // CETAK OTOMATIS: Langsung panggil fungsi print tanpa nunggu klik tombol
    try {
      final pdf = await StrukService.generateStrukKeluar(
        idParkir: transaksi.idParkir,
        platNomor: transaksi.platNomor ?? '-',
        jenisKendaraan: transaksi.jenisKendaraan ?? '-',
        namaArea: transaksi.namaArea ?? '-',
        tarifAwal: 'Rp ${tarif.tarifPerJam}',
        tarifNambah: 'Rp ${jamTambahan * tarif.tarifNambah}',
        waktuMasuk: transaksi.waktuMasuk,
        waktuKeluar: waktuKeluar,
        durasiJam: durasiJam,
        biayaTotal: biayaTotal,
        namaPetugas: namaPetugas,
      );
      await StrukService.printStruk(
        pdf,
        'Struk_Pembayaran_${transaksi.idParkir}.pdf',
      );
    } catch (e) {
      print('Gagal cetak otomatis: $e');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Pembayaran Berhasil')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('ID Parkir: ', style: TextStyle(fontSize: 14)),
                  Text(
                    '#${transaksi.idParkir}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Plat Nomor', transaksi.platNomor ?? 'N/A'),
            _buildInfoRow('Jenis', transaksi.jenisKendaraan ?? 'N/A'),
            _buildInfoRow('Area', transaksi.namaArea ?? 'N/A'),
            const Divider(height: 24),
            _buildInfoRow(
              'Masuk',
              DateFormat('dd/MM HH:mm').format(transaksi.waktuMasuk),
            ),
            _buildInfoRow(
              'Keluar',
              DateFormat('dd/MM HH:mm').format(waktuKeluar),
            ),
            _buildInfoRow('Durasi', '$durasiJam jam'),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL DIBAYAR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(biayaTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                // Generate PDF payment receipt
                final pdf = await StrukService.generateStrukKeluar(
                  idParkir: transaksi.idParkir,
                  platNomor: transaksi.platNomor ?? '-',
                  jenisKendaraan: transaksi.jenisKendaraan ?? '-',
                  namaArea: transaksi.namaArea ?? '-',
                  tarifAwal: 'Rp ${tarif.tarifPerJam}',
                  tarifNambah: 'Rp ${jamTambahan * tarif.tarifNambah}',
                  waktuMasuk: transaksi.waktuMasuk,
                  waktuKeluar: waktuKeluar,
                  durasiJam: durasiJam,
                  biayaTotal: biayaTotal,
                  namaPetugas: namaPetugas,
                );

                // Print or preview receipt
                await StrukService.printStruk(
                  pdf,
                  'Struk_Pembayaran_${transaksi.idParkir}.pdf',
                );

                  if (!mounted) return;
                  Navigator.pop(context);
                  AppNotification.success(context, 'Struk pembayaran berhasil dicetak');
                } catch (e) {
                  if (!mounted) return;
                  AppNotification.error(context, 'Gagal mencetak struk: $e');
                }

            },
            icon: const Icon(Icons.print_rounded),
            label: const Text('Cetak Ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Memuat transaksi aktif...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: _error ?? 'Terjadi kesalahan',
        onRetry: _loadTransaksi,
      );
    }

    if (_transaksiAktif.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.event_available_rounded,
        title: 'Tidak Ada Kendaraan',
        message: 'Belum ada kendaraan yang sedang parkir',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransaksi,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transaksiAktif.length,
        itemBuilder: (context, index) {
          final transaksi = _transaksiAktif[index];
          final duration = DateTime.now().difference(transaksi.waktuMasuk);
          final hours = duration.inHours;
          final minutes = duration.inMinutes % 60;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: const Icon(
                      Icons.local_parking_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaksi.platNomor != null && transaksi.platNomor!.isNotEmpty
                              ? transaksi.platNomor!
                              : 'Kendaraan #${transaksi.idParkir}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jenis: ${transaksi.jenisKendaraan ?? '-'}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Area: ${transaksi.namaArea ?? '-'}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Masuk: ${DateFormat('HH:mm').format(transaksi.waktuMasuk)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Durasi: ${hours}j ${minutes}m',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _prosesKeluar(transaksi),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
