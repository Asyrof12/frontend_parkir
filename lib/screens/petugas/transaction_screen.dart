import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

  // Mode input (Unified: bisa pilih atau ketik)
  int? _selectedKendaraan;
  KendaraanModel? _selectedKendaraanObj;
  int? _selectedTarif;
  int? _selectedArea;

  // Foto kendaraan (opsional)
  File? _selectedPhoto;         // Foto baru yang dipilih user
  String? _existingPhotoUrl;    // Foto existing dari database (ditampilkan saat pilih kendaraan)

  final TextEditingController _kendaraanInputController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _kendaraanInputController.dispose();
    super.dispose();
  }

  // Pilih foto dari file (Windows-compatible)
  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedPhoto = File(result.files.single.path!));
    }
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

    final Map<String, dynamic> data;
    
    // Cari tarif yang dipilih untuk ambil jenis kendaraannya
    final selectedTarifObj = _tarifList.firstWhere(
      (t) => t.idTarif == _selectedTarif,
      orElse: () => _tarifList.isNotEmpty ? _tarifList.first : TarifModel(idTarif: 0, jenisKendaraan: 'Tidak Diketahui', tarifPerJam: 0, tarifNambah: 0),
    );

    if (_selectedKendaraan != null) {
      // Jika memilih dari daftar
      data = {
        'id_kendaraan': _selectedKendaraan,
        'id_tarif': _selectedTarif,
        'id_area': _selectedArea,
      };
    } else {
      // Jika input manual (ketik sendiri)
      data = {
        'plat_nomor': _kendaraanInputController.text.trim().toUpperCase(),
        'jenis_kendaraan': selectedTarifObj.jenisKendaraan,
        'id_tarif': _selectedTarif,
        'id_area': _selectedArea,
      };
    }

    final result = await TransaksiService.transaksiMasuk(
      data,
      photoFile: _selectedPhoto,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result['success']) {
      AppNotification.success(context, 'Kendaraan berhasil terdaftar masuk');
      
      // Update local state for receipt display
      final dynamic receiptData = result['data'];
      _showStrukDialog(receiptData is Map<String, dynamic> ? receiptData : {});
      
      _formKey.currentState?.reset();
      setState(() {
        _selectedKendaraan = null;
        _selectedKendaraanObj = null;
        _selectedPhoto = null;
        _existingPhotoUrl = null;
        _kendaraanInputController.clear();
        _selectedTarif = null;
        _selectedArea = null;
      });
      _loadData();
      RefreshService.instance.refreshDashboard();
    } else {
      AppNotification.error(context, result['message']);
    }
  }

  Future<void> _showStrukDialog(Map<String, dynamic> data) async {
    try {
      // Coba ambil dari list; jika manual (tidak ada id_kendaraan di state), buat objek sementara
      final KendaraanModel kendaraan;
      if (_selectedKendaraan != null) {
        kendaraan = _kendaraanList.firstWhere(
          (k) => k.idKendaraan == _selectedKendaraan,
          orElse: () => KendaraanModel(
            idKendaraan: data['id_kendaraan'] ?? 0,
            platNomor: '-',
            jenisKendaraan: '-',
            warna: '-',
          ),
        );
      } else {
        final tarif = _tarifList.firstWhere(
          (t) => t.idTarif == _selectedTarif,
          orElse: () => TarifModel(idTarif: 0, jenisKendaraan: 'Manual', tarifPerJam: 0, tarifNambah: 0),
        );
        kendaraan = KendaraanModel(
          idKendaraan: data['id_kendaraan'] ?? 0,
          platNomor: _kendaraanInputController.text.trim().toUpperCase(),
          jenisKendaraan: tarif.jenisKendaraan,
          warna: '-',
        );
      }
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

  Widget _buildPhotoPicker() {
    final bool hasNewPhoto = _selectedPhoto != null;
    final bool hasExisting = _existingPhotoUrl != null && !hasNewPhoto;

    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (hasNewPhoto || hasExisting) ? AppColors.primary : Colors.grey.shade300,
            width: (hasNewPhoto || hasExisting) ? 2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: (hasNewPhoto || hasExisting)
            ? Stack(
                fit: StackFit.expand,
                children: [
                  hasNewPhoto
                      ? Image.file(_selectedPhoto!, fit: BoxFit.cover)
                      : Image.network(
                          _existingPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder(),
                        ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      child: Text(
                        hasNewPhoto ? 'Ubah Foto' : 'Foto Tersimpan · Klik untuk ganti',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                  // Tombol hapus foto baru saja dipilih
                  if (hasNewPhoto)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPhoto = null),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              )
            : _photoPlaceholder(),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 26),
        ),
        const SizedBox(height: 8),
        const Text('Tambah Foto Kendaraan (Opsional)',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13)),
        const SizedBox(height: 2),
        Text('Klik untuk pilih dari file',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
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
                    // Unified Vehicle Input (Autocomplete + Manual)
                    FormField<String>(
                      initialValue: _selectedKendaraan?.toString() ?? _kendaraanInputController.text,
                      validator: (_) {
                        if (_selectedKendaraan == null && _kendaraanInputController.text.trim().isEmpty) {
                          return 'Pilih atau ketik kendaraan';
                        }
                        return null;
                      },
                      builder: (field) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Autocomplete<KendaraanModel>(
                              displayStringForOption: (k) => k.displayName,
                              optionsBuilder: (textEditingValue) {
                                final query = textEditingValue.text.toLowerCase();
                                if (query.isEmpty) return _kendaraanList;
                                return _kendaraanList.where((k) =>
                                    k.platNomor.toLowerCase().contains(query) ||
                                    k.jenisKendaraan.toLowerCase().contains(query) ||
                                    k.pemilik.toLowerCase().contains(query));
                              },
                              onSelected: (KendaraanModel selected) {
                                setState(() {
                                  _selectedKendaraan = selected.idKendaraan;
                                  _selectedKendaraanObj = selected;
                                  _kendaraanInputController.text = selected.platNomor;
                                  // Tampilkan foto existing jika ada
                                  _selectedPhoto = null;
                                  if (selected.photoKendaraan != null && selected.photoKendaraan!.isNotEmpty) {
                                    final base = 'https://dishonestly-nondistracted-vania.ngrok-free.dev';
                                    _existingPhotoUrl = '$base${selected.photoKendaraan}';
                                  } else {
                                    _existingPhotoUrl = null;
                                  }
                                });
                                field.didChange(selected.idKendaraan.toString());
                              },
                              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                                // Sync external controller
                                controller.addListener(() {
                                  if (controller.text != _kendaraanInputController.text) {
                                    _kendaraanInputController.text = controller.text;
                                  }
                                });
                                
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    labelText: 'Pilih / Ketik Kendaraan',
                                    prefixIcon: const Icon(Icons.directions_car_outlined),
                                    suffixIcon: controller.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            onPressed: () {
                                              setState(() {
                                                _selectedKendaraan = null;
                                                _selectedKendaraanObj = null;
                                                _existingPhotoUrl = null;
                                                _selectedPhoto = null;
                                              });
                                              controller.clear();
                                              _kendaraanInputController.clear();
                                              field.didChange(null);
                                            },
                                          )
                                        : const Icon(Icons.arrow_drop_down),
                                    hintText: 'Contoh: B 1234 XY',
                                    errorText: field.errorText,
                                  ),
                                  onChanged: (val) {
                                    if (_selectedKendaraan != null) {
                                      setState(() {
                                        _selectedKendaraan = null;
                                        _selectedKendaraanObj = null;
                                      });
                                    }
                                    field.didChange(val);
                                  },
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 6,
                                    borderRadius: BorderRadius.circular(12),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxHeight: 220),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final k = options.elementAt(index);
                                          return ListTile(
                                            leading: const Icon(Icons.directions_car_outlined),
                                            title: Text(
                                              k.platNomor,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text('${k.jenisKendaraan} · ${k.pemilik}'),
                                            onTap: () => onSelected(k),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Info kendaraan terpilih (hanya jika memilih dari database)
                            if (_selectedKendaraanObj != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${_selectedKendaraanObj!.platNomor} · ${_selectedKendaraanObj!.jenisKendaraan} · ${_selectedKendaraanObj!.warna}',
                                          style: const TextStyle(fontSize: 12, color: Colors.green),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
                    const SizedBox(height: 16),
                    // ── Foto Kendaraan (Opsional) ──
                    _buildPhotoPicker(),
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

    // Gratis jika kurang dari 5 menit
    bool isGratis = durasiMenit < 5;
    int biayaTotal = isGratis ? 0 : tarif.tarifPerJam + (jamTambahan * tarif.tarifNambah);

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
            _buildInfoRow(
              'Durasi',
              '$durasiMenit menit${durasiMenit >= 60 ? " ($durasiJam jam)" : ""}',
            ),
            const Divider(height: 24),
            if (isGratis) ...
              [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PARKIR GRATIS!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Durasi kurang dari 5 menit',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Rp 0',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            else ...
              [
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
        durasiMenit: durasiMenit,
        biayaTotal: biayaTotal,
        isGratis: isGratis,
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
    required int durasiMenit,
    required int biayaTotal,
    required bool isGratis,
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
        isGratis: isGratis,
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
            _buildInfoRow(
              'Durasi',
              '$durasiMenit menit${durasiMenit >= 60 ? " ($durasiJam jam)" : ""}',
            ),
            const Divider(height: 24),
            if (isGratis)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.celebration_rounded, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PARKIR GRATIS!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    Text(
                      'Rp 0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              )
            else
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
                  isGratis: isGratis,
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
