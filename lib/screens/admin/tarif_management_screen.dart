import 'package:flutter/material.dart';
import '../../models/tarif_model.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/form_validators.dart';

class TarifManagementScreen extends StatefulWidget {
  const TarifManagementScreen({super.key});

  @override
  State<TarifManagementScreen> createState() => _TarifManagementScreenState();
}

class _TarifManagementScreenState extends State<TarifManagementScreen> {
  List<TarifModel> _tarifs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTarifs();
  }

  Future<void> _loadTarifs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await TarifService.getTarif();

      if (!mounted) return;

      if (result['success'] == true) {
        dynamic data = result['data'];
        
        // PERBAIKAN: Cek apakah data nested lagi (double-wrapped)
        // Response: {success: true, data: {success: true, data: [...]}}
        if (data is Map && data.containsKey('success') && data.containsKey('data')) {
          print('🔄 Data is NESTED! Extracting inner data...');
          data = data['data']; // Ambil data yang sebenarnya
        }
        
        List<TarifModel> tarifs = [];
        
        if (data is List) {
          tarifs = data.map((e) => TarifModel.fromJson(e as Map<String, dynamic>)).toList();
        } else if (data is Map<String, dynamic>) {
          tarifs = [TarifModel.fromJson(data)];
        } else if (data == null) {
          tarifs = [];
        } else {
          throw Exception('Unexpected data type: ${data.runtimeType}');
        }

        setState(() {
          _tarifs = tarifs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Gagal memuat tarif';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTarif(int id, String jenis) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus tarif "$jenis"?'),
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

    final result = await TarifService.deleteTarif(id);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif berhasil dihapus')),
      );
      _loadTarifs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showTarifForm([TarifModel? tarif]) {
    showDialog(
      context: context,
      builder: (context) => TarifFormDialog(tarif: tarif, onSaved: _loadTarifs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Tarif Parkir'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTarifForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Tarif'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat data tarif...')
          : _error != null
              ? ErrorDisplayWidget(message: _error ?? 'Terjadi kesalahan', onRetry: _loadTarifs)
              : _tarifs.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.local_parking_outlined,
                      title: 'Belum Ada Tarif',
                      message: 'Tambahkan tarif parkir dengan menekan tombol + di bawah',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTarifs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tarifs.length,
                        itemBuilder: (context, index) {
                          final tarif = _tarifs[index];
                          
                          // Kapitalisasi jenis kendaraan
                          String jenisKendaraan = tarif.jenisKendaraan.isEmpty
                              ? 'Unknown'
                              : tarif.jenisKendaraan[0].toUpperCase() + 
                                tarif.jenisKendaraan.substring(1).toLowerCase();
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                radius: 24,
                                child: Icon(
                                  tarif.jenisKendaraan.toLowerCase().contains('motor')
                                      ? Icons.two_wheeler_rounded
                                      : tarif.jenisKendaraan.toLowerCase().contains('mobil')
                                          ? Icons.directions_car_rounded
                                          : Icons.local_parking_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                jenisKendaraan,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Awal: ${tarif.formattedTarif}',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Nambah: Rp ${tarif.tarifNambah}/jam',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: PopupMenuButton(
                                icon: const Icon(Icons.more_vert_rounded),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 20),
                                        SizedBox(width: 12),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        SizedBox(width: 12),
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
                                    _showTarifForm(tarif);
                                  } else if (value == 'delete') {
                                    _deleteTarif(tarif.idTarif, jenisKendaraan);
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

class TarifFormDialog extends StatefulWidget {
  final TarifModel? tarif;
  final VoidCallback onSaved;

  const TarifFormDialog({super.key, this.tarif, required this.onSaved});

  @override
  State<TarifFormDialog> createState() => _TarifFormDialogState();
}

class _TarifFormDialogState extends State<TarifFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedJenis;
  late TextEditingController _tarifController;
  late TextEditingController _nambahController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _tarifController = TextEditingController(
      text: widget.tarif?.tarifPerJam.toString() ?? '',
    );
    _nambahController = TextEditingController(
      text: widget.tarif?.tarifNambah.toString() ?? '',
    );

    if (widget.tarif != null) {
      final jenisLower = (widget.tarif?.jenisKendaraan ?? '').toLowerCase();
      if (['motor', 'mobil', 'lainnya'].contains(jenisLower)) {
        _selectedJenis = jenisLower;
      } else {
        _selectedJenis = 'motor';
      }
    } else {
      _selectedJenis = 'motor';
    }
  }

  @override
  void dispose() {
    _tarifController.dispose();
    _nambahController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedJenis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis kendaraan terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'jenis_kendaraan': _selectedJenis,
      'tarif_per_jam': int.parse(_tarifController.text),
      'tarif_nambah': int.parse(_nambahController.text),
    };

    final result = widget.tarif == null
        ? await TarifService.createTarif(data)
        : await TarifService.updateTarif(widget.tarif!.idTarif, data);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.tarif == null
                ? 'Tarif berhasil ditambahkan'
                : 'Tarif berhasil diupdate',
          ),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Terjadi kesalahan'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.tarif == null ? 'Tambah Tarif' : 'Edit Tarif',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedJenis,
              decoration: InputDecoration(
                labelText: 'Jenis Kendaraan',
                prefixIcon: const Icon(Icons.directions_car_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'motor', child: Text('Motor')),
                DropdownMenuItem(value: 'mobil', child: Text('Mobil')),
                DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedJenis = value;
                });
              },
              validator: (value) =>
                  value == null ? 'Jenis kendaraan wajib dipilih' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tarifController,
              decoration: InputDecoration(
                labelText: 'Tarif Per Jam (Rp)',
                prefixIcon: const Icon(Icons.payments_outlined),
                hintText: 'Contoh: 2000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  FormValidators.positiveNumber(value, 'Tarif'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nambahController,
              decoration: InputDecoration(
                labelText: 'Tarif Nambah / Jam (Rp)',
                prefixIcon: const Icon(Icons.add_circle_outline_rounded),
                hintText: 'Contoh: 1000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  FormValidators.positiveNumber(value, 'Tarif Nambah'),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.tarif == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }
}