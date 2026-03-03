import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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

  void _onRefreshTriggered() => _loadKendaraan();

  @override
  void dispose() {
    _searchController.dispose();
    RefreshService.instance.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  Future<void> _loadKendaraan() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await KendaraanService.getKendaraan();
      if (!mounted) return;

      if (result['success'] == true) {
        dynamic data = result['data'];
        if (data is Map && data.containsKey('data')) data = data['data'];
        if (data is! List) throw Exception('Format data kendaraan tidak valid');

        final list = data.map((e) => KendaraanModel.fromJson(e)).toList()
          ..sort((a, b) => a.platNomor.toUpperCase().compareTo(b.platNomor.toUpperCase()));

        setState(() { _kendaraan = list; _filteredKendaraan = list; _isLoading = false; });
      } else {
        setState(() { _error = result['message']; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _filterKendaraan(String query) {
    setState(() {
      _filteredKendaraan = query.isEmpty
          ? _kendaraan
          : _kendaraan.where((k) =>
              k.platNomor.toLowerCase().contains(query.toLowerCase()) ||
              k.jenisKendaraan.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Future<void> _deleteKendaraan(int id, String platNomor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus kendaraan "$platNomor"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
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
      builder: (context) => KendaraanFormDialog(kendaraan: kendaraan, onSaved: _loadKendaraan),
    );
  }

  String _getPhotoUrl(String path) {
    // Strip /api dari baseUrl untuk URL foto statis
    final base = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$base$path';
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
                    ? ErrorDisplayWidget(message: _error!, onRetry: _loadKendaraan)
                    : _filteredKendaraan.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.directions_car_outlined,
                            title: _searchController.text.isEmpty ? 'Belum Ada Kendaraan' : 'Tidak Ditemukan',
                            message: _searchController.text.isEmpty
                                ? 'Tambahkan kendaraan dengan menekan tombol + di bawah'
                                : 'Tidak ada kendaraan yang sesuai',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadKendaraan,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredKendaraan.length,
                              itemBuilder: (context, index) {
                                final k = _filteredKendaraan[index];
                                return _buildVehicleCard(k);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(KendaraanModel k) {
    final isMotor = k.jenisKendaraan.toLowerCase().contains('motor');
    final isMobil = k.jenisKendaraan.toLowerCase().contains('mobil');
    final color = isMotor ? Colors.orange.shade700 : isMobil ? AppColors.primary : Colors.teal;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: k.photoKendaraan != null && k.photoKendaraan!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _getPhotoUrl(k.photoKendaraan!),
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildIconAvatar(color, isMotor, isMobil),
                ),
              )
            : _buildIconAvatar(color, isMotor, isMobil),
        title: Row(
          children: [
            Text(k.platNomor.isNotEmpty ? k.platNomor : 'Tanpa Plat',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 8),
            if (k.jenisKendaraan.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isMotor ? Colors.orange.shade100 : AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  k.jenisKendaraan.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isMotor ? Colors.orange.shade800 : AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.color_lens_outlined, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(k.warna.isEmpty || k.warna == '-' ? 'Warna tidak dicatat' : k.warna,
                  style: const TextStyle(fontSize: 12)),
            ]),
            if (k.pemilik.isNotEmpty && k.pemilik != 'Tamu')
              Row(children: [
                const Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Pemilik: ${k.pemilik}', style: const TextStyle(fontSize: 12)),
              ]),
            if (k.namaPendaftar.isNotEmpty)
              Row(children: [
                const Icon(Icons.badge_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Didaftarkan: ${k.namaPendaftar}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 8), Text('Edit')]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Hapus', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') _showKendaraanForm(k);
            if (value == 'delete') _deleteKendaraan(k.idKendaraan, k.platNomor);
          },
        ),
      ),
    );
  }

  Widget _buildIconAvatar(Color color, bool isMotor, bool isMobil) {
    return CircleAvatar(
      backgroundColor: color,
      child: Icon(
        isMotor
            ? Icons.two_wheeler_rounded
            : isMobil
                ? Icons.directions_car_rounded
                : Icons.airport_shuttle_rounded,
        color: Colors.white,
      ),
    );
  }
}

// ─────────────────────────── FORM DIALOG ───────────────────────────

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

  // Photo state
  File? _selectedPhoto;
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    _platNomorController = TextEditingController(text: widget.kendaraan?.platNomor ?? '');
    _jenisController     = TextEditingController(text: widget.kendaraan?.jenisKendaraan ?? '');
    _warnaController     = TextEditingController(text: widget.kendaraan?.warna ?? '');
    _pemilikController   = TextEditingController(text: widget.kendaraan?.pemilik ?? '');

    if (widget.kendaraan?.photoKendaraan != null) {
      final base = ApiConfig.baseUrl.replaceAll('/api', '');
      _existingPhotoUrl = '$base${widget.kendaraan!.photoKendaraan}';
    }
  }

  @override
  void dispose() {
    _platNomorController.dispose();
    _jenisController.dispose();
    _warnaController.dispose();
    _pemilikController.dispose();
    super.dispose();
  }

  // ── Pick from camera (mobile only) ──
  Future<void> _pickFromCamera() async {
    // Kamera tidak didukung di platform desktop (Windows/Linux/macOS)
    // Fallback ke file picker
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _pickFromFile();
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _selectedPhoto = File(picked.path));
  }

  // ── Pick from file system ──
  Future<void> _pickFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedPhoto = File(result.files.single.path!));
    }
  }

  // Apakah platform mendukung kamera?
  bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  void _showPickerOptions() {
    // Jika mobile: tampilkan pilihan kamera + galeri
    // Jika desktop: langsung buka file picker
    if (!_isMobilePlatform) {
      _pickFromFile();
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Pilih Sumber Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              ),
              title: const Text('Dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Ambil foto langsung dari kamera'),
              onTap: () { Navigator.pop(context); _pickFromCamera(); },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.folder_open_rounded, color: Colors.green),
              ),
              title: const Text('Dari File / Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Pilih gambar dari penyimpanan'),
              onTap: () { Navigator.pop(context); _pickFromFile(); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isLoading = true);

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
        ? await KendaraanService.createKendaraan(data, photoFile: _selectedPhoto)
        : await KendaraanService.updateKendaraan(
            widget.kendaraan!.idKendaraan,
            data,
            photoFile: _selectedPhoto,
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pop(context);
      AppNotification.success(
        context,
        widget.kendaraan == null ? 'Kendaraan berhasil ditambahkan' : 'Kendaraan berhasil diupdate',
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
      title: Text(widget.kendaraan == null ? 'Tambah Kendaraan' : 'Edit Kendaraan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Photo Picker ──
              _buildPhotoPicker(),
              const SizedBox(height: 20),

              TextFormField(
                controller: _platNomorController,
                decoration: const InputDecoration(
                  labelText: 'Plat Nomor',
                  prefixIcon: Icon(Icons.pin_outlined),
                  hintText: 'Contoh: B 1234 XYZ',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => FormValidators.required(v, 'Plat nomor'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jenisController,
                decoration: const InputDecoration(
                  labelText: 'Jenis Kendaraan',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'Contoh: Motor, Mobil',
                ),
                validator: (v) => FormValidators.required(v, 'Jenis kendaraan'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _warnaController,
                decoration: const InputDecoration(
                  labelText: 'Warna Kendaraan',
                  prefixIcon: Icon(Icons.color_lens_outlined),
                  hintText: 'Contoh: Hitam, Merah, Putih',
                ),
                validator: (v) => FormValidators.required(v, 'Warna kendaraan'),
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
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.kendaraan == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    final hasSelected = _selectedPhoto != null;
    final hasExisting = _existingPhotoUrl != null && !hasSelected;

    return GestureDetector(
      onTap: _showPickerOptions,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSelected ? AppColors.primary : Colors.grey.shade300,
            width: hasSelected ? 2 : 1.5,
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasSelected
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_selectedPhoto!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: const Text('Ubah Foto', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              )
            : hasExisting
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(_existingPhotoUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder()),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: const Text('Ubah Foto', style: TextStyle(color: Colors.white, fontSize: 12)),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 30),
        ),
        const SizedBox(height: 10),
        const Text('Tambah Foto Kendaraan',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(_isMobilePlatform ? 'Kamera atau pilih dari file' : 'Klik untuk pilih dari file',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}
