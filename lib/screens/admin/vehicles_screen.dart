import 'package:flutter/material.dart';
import '../../models/kendaraan_model.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../services/refresh_service.dart';

import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/form_validators.dart';
import '../../utils/notifications.dart';


class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<KendaraanModel> _kendaraan = [];
  List<KendaraanModel> _filteredKendaraan = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKendaraan();
    RefreshService.instance.addListener(_onRefreshTriggered);
  }

  void _onRefreshTriggered() {
    _loadKendaraan();
  }


  @override
  void dispose() {
    _searchController.dispose();
    RefreshService.instance.removeListener(_onRefreshTriggered);
    super.dispose();
  }


  Future<void> _loadKendaraan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await KendaraanService.getKendaraan();
      if (!mounted) return;

      if (result['success'] == true) {
        dynamic data = result['data'];

        // ✅ HANDLE RESPONSE NESTED
        if (data is Map && data.containsKey('data')) {
          print('🔄 Data is NESTED! Extracting inner data...');
          data = data['data'];
        }

        if (data is! List) {
          throw Exception('Format data kendaraan tidak valid');
        }

        final kendaraanParsed = data
            .map((e) => KendaraanModel.fromJson(e))
            .toList();

        // URUTKAN BERDASARKAN PLAT NOMOR (A-Z) - Case Insensitive
        kendaraanParsed.sort((a, b) => 
            a.platNomor.toUpperCase().compareTo(b.platNomor.toUpperCase()));

        setState(() {
          _kendaraan = kendaraanParsed;
          _filteredKendaraan = kendaraanParsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterKendaraan(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredKendaraan = _kendaraan;
      } else {
        _filteredKendaraan = _kendaraan
            .where(
              (k) =>
                  k.platNomor.toLowerCase().contains(query.toLowerCase()) ||
                  k.jenisKendaraan.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _deleteKendaraan(int id, String platNomor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kendaraan "$platNomor"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await KendaraanService.deleteKendaraan(id);

    if (!mounted) return;

    if (result['success']) {
      AppNotification.success(context, 'Kendaraan berhasil dihapus');
      _loadKendaraan();
      RefreshService.instance.refreshDashboard();
    } else {

      AppNotification.error(context, result['message']);
    }

  }

  void _showKendaraanForm([KendaraanModel? kendaraan]) {
    showDialog(
      context: context,
      builder: (context) =>
          KendaraanFormDialog(kendaraan: kendaraan, onSaved: _loadKendaraan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Kendaraan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showKendaraanForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kendaraan'),  
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari plat nomor atau jenis...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterKendaraan,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Memuat data kendaraan...')
                : _error != null
                ? ErrorDisplayWidget(message: _error ?? 'Terjadi kesalahan', onRetry: _loadKendaraan)
                : _filteredKendaraan.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.directions_car_outlined,
                    title: _searchController.text.isEmpty
                        ? 'Belum Ada Kendaraan'
                        : 'Tidak Ditemukan',
                    message: _searchController.text.isEmpty
                        ? 'Tambahkan kendaraan dengan menekan tombol + di bawah'
                        : 'Tidak ada kendaraan yang sesuai dengan pencarian',
                  )
                : RefreshIndicator(
                    onRefresh: _loadKendaraan,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredKendaraan.length,
                      itemBuilder: (context, index) {
                        final kendaraan = _filteredKendaraan[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: kendaraan.jenisKendaraan.toLowerCase().contains('motor')
                                  ? Colors.orange.shade700
                                  : kendaraan.jenisKendaraan.toLowerCase().contains('mobil')
                                      ? AppColors.primary
                                      : Colors.teal,
                              child: Icon(
                                kendaraan.jenisKendaraan.toLowerCase().contains('motor')
                                    ? Icons.two_wheeler_rounded
                                    : kendaraan.jenisKendaraan.toLowerCase().contains('mobil')
                                        ? Icons.directions_car_rounded
                                        : Icons.airport_shuttle_rounded,
                                color: Colors.white,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  kendaraan.platNomor.isNotEmpty ? kendaraan.platNomor : 'Tanpa Plat',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (kendaraan.jenisKendaraan.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: kendaraan.jenisKendaraan.toLowerCase().contains('motor')
                                          ? Colors.orange.shade100
                                          : AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      kendaraan.jenisKendaraan.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: kendaraan.jenisKendaraan.toLowerCase().contains('motor')
                                            ? Colors.orange.shade800
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.color_lens_outlined, size: 13, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      kendaraan.warna.isEmpty || kendaraan.warna == '-'
                                          ? 'Warna tidak dicatat'
                                          : kendaraan.warna,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                if (kendaraan.pemilik.isNotEmpty && kendaraan.pemilik != 'Tamu')
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Pemilik: ${kendaraan.pemilik}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                if (kendaraan.namaPendaftar.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.badge_outlined, size: 13, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Didaftarkan oleh: ${kendaraan.namaPendaftar}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showKendaraanForm(kendaraan);
                                } else if (value == 'delete') {
                                  _deleteKendaraan(
                                    kendaraan.idKendaraan,
                                    kendaraan.platNomor,
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class KendaraanFormDialog extends StatefulWidget {
  final KendaraanModel? kendaraan;
  final VoidCallback onSaved;

  const KendaraanFormDialog({super.key, this.kendaraan, required this.onSaved});

  @override
  State<KendaraanFormDialog> createState() => _KendaraanFormDialogState();
}

class _KendaraanFormDialogState extends State<KendaraanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _platNomorController;
  late TextEditingController _jenisController;
  late TextEditingController _warnaController;
  late TextEditingController _pemilikController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _platNomorController = TextEditingController(
      text: widget.kendaraan?.platNomor ?? '',
    );
    _jenisController = TextEditingController(
      text: widget.kendaraan?.jenisKendaraan ?? '',
    );
    _warnaController = TextEditingController(
      text: widget.kendaraan?.warna ?? '',
    );
    _pemilikController = TextEditingController(
      text: widget.kendaraan?.pemilik ?? '',
    );
  }

  @override
  void dispose() {
    _platNomorController.dispose();
    _jenisController.dispose();
    _warnaController.dispose();
    _pemilikController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    // ✅ AMBIL USER ID SECARA OTOMATIS
    final user = await AuthService.getUser();
    final idUser = user?['id_user'];

    final data = {
      'plat_nomor': _platNomorController.text.toUpperCase(),
      'jenis_kendaraan': _jenisController.text,
      'warna': _warnaController.text,
      'pemilik': _pemilikController.text,
      if (widget.kendaraan == null && idUser != null) 'id_user': idUser,
    };

    final result = widget.kendaraan == null
        ? await KendaraanService.createKendaraan(data)
        : await KendaraanService.updateKendaraan(
            widget.kendaraan!.idKendaraan,
            data,
          );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pop(context);
      AppNotification.success(
        context,
        widget.kendaraan == null
            ? 'Kendaraan berhasil ditambahkan'
            : 'Kendaraan berhasil diupdate',
      );
      widget.onSaved();
      RefreshService.instance.refreshDashboard();
    } else {

      AppNotification.error(context, result['message']);
    }

  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.kendaraan == null ? 'Tambah Kendaraan' : 'Edit Kendaraan',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _platNomorController,
                decoration: const InputDecoration(
                  labelText: 'Plat Nomor',
                  prefixIcon: Icon(Icons.pin_outlined),
                  hintText: 'Contoh: B 1234 XYZ',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                    FormValidators.required(value, 'Plat nomor'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jenisController,
                decoration: const InputDecoration(
                  labelText: 'Jenis Kendaraan',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'Contoh: Motor, Mobil',
                ),
                validator: (value) =>
                    FormValidators.required(value, 'Jenis kendaraan'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _warnaController,
                decoration: const InputDecoration(
                  labelText: 'Warna Kendaraan',
                  prefixIcon: Icon(Icons.color_lens_outlined),
                  hintText: 'Contoh: Hitam, Merah, Putih',
                ),
                validator: (value) =>
                    FormValidators.required(value, 'Warna kendaraan'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pemilikController,
                decoration: const InputDecoration(
                  labelText: 'Pemilik (Opsional)',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  hintText: 'Nama pemilik kendaraan',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.kendaraan == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }
}
