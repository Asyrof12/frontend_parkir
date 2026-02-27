import 'package:flutter/material.dart';
import '../../models/area_model.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/form_validators.dart';
import '../../utils/notifications.dart';
import '../../services/refresh_service.dart';



class AreaManagementScreen extends StatefulWidget {
  const AreaManagementScreen({super.key});

  @override
  State<AreaManagementScreen> createState() => _AreaManagementScreenState();
}

class _AreaManagementScreenState extends State<AreaManagementScreen> {
  List<AreaModel> _areas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    RefreshService.instance.addListener(_onRefreshTriggered);
  }

  void _onRefreshTriggered() {
    _loadAreas();
  }

  @override
  void dispose() {
    RefreshService.instance.removeListener(_onRefreshTriggered);
    super.dispose();
  }


  Future<void> _loadAreas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AreaService.getAreas();
      if (!mounted) return;

      if (result['success'] == true) {
        dynamic data = result['data'];

        // ✅ handle nested response
        if (data is Map && data.containsKey('data')) {
          data = data['data'];
        }

        if (data is! List) {
          throw Exception('Format data area tidak valid');
        }

        final List<AreaModel> parsedAreas = data
            .map((e) => AreaModel.fromJson(e))
            .toList();

        setState(() {
          _areas = parsedAreas; // ✅ SUDAH BENER TIPE-NYA
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

  Future<void> _deleteArea(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus area "$name"?'),
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

    final result = await AreaService.deleteArea(id);

    if (!mounted) return;

    if (result['success']) {
      AppNotification.success(context, 'Area berhasil dihapus');
      _loadAreas();
      RefreshService.instance.refreshDashboard();
    } else {

      AppNotification.error(context, result['message']);
    }

  }

  void _showAreaForm([AreaModel? area]) {
    showDialog(
      context: context,
      builder: (context) => AreaFormDialog(area: area, onSaved: _loadAreas),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Area Parkir')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAreaForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Area'),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat data area...')
          : _error != null
          ? ErrorDisplayWidget(message: _error ?? 'Terjadi kesalahan', onRetry: _loadAreas)
          : _areas.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.local_parking_outlined,
              title: 'Belum Ada Area',
              message: 'Tambahkan area parkir dengan menekan tombol + di bawah',
            )
          : RefreshIndicator(
              onRefresh: _loadAreas,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _areas.length,
                itemBuilder: (context, index) {
                  final area = _areas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: area.isFull
                            ? Colors.red
                            : AppColors.primary,
                        child: Icon(
                          area.isFull
                              ? Icons.block_rounded
                              : Icons.local_parking_rounded,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        area.namaArea,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kapasitas: ${area.kapasitas}'),
                          Text(
                            'Tersedia: ${area.tersedia}',
                            style: TextStyle(
                              color: area.isFull ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
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
                                Icon(Icons.delete_outline, color: Colors.red),
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
                            _showAreaForm(area);
                          } else if (value == 'delete') {
                            _deleteArea(area.idArea, area.namaArea);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class AreaFormDialog extends StatefulWidget {
  final AreaModel? area;
  final VoidCallback onSaved;

  const AreaFormDialog({super.key, this.area, required this.onSaved});

  @override
  State<AreaFormDialog> createState() => _AreaFormDialogState();
}

class _AreaFormDialogState extends State<AreaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _kapasitasController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.area?.namaArea ?? '');
    _kapasitasController = TextEditingController(
      text: widget.area?.kapasitas.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kapasitasController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    final data = {
      'nama_area': _namaController.text,
      'kapasitas': int.parse(_kapasitasController.text),
    };

    final result = widget.area == null
        ? await AreaService.createArea(data)
        : await AreaService.updateArea(widget.area!.idArea, data);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pop(context);
      AppNotification.success(
        context,
        widget.area == null ? 'Area berhasil ditambahkan' : 'Area berhasil diupdate',
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
      title: Text(widget.area == null ? 'Tambah Area' : 'Edit Area'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Area',
                prefixIcon: Icon(Icons.location_on_outlined),
                hintText: 'Contoh: Area A-1',
              ),
              validator: (value) => FormValidators.required(value, 'Nama area'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kapasitasController,
              decoration: const InputDecoration(
                labelText: 'Kapasitas',
                prefixIcon: Icon(Icons.numbers_rounded),
                hintText: 'Contoh: 50',
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  FormValidators.positiveNumber(value, 'Kapasitas'),
            ),
          ],
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
              : Text(widget.area == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }
}
