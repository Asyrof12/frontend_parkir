import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaksi_model.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';

class PetugasHistoryScreen extends StatefulWidget {
  const PetugasHistoryScreen({super.key});

  @override
  State<PetugasHistoryScreen> createState() => _PetugasHistoryScreenState();
}


class _PetugasHistoryScreenState extends State<PetugasHistoryScreen> {
  List<TransaksiModel> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await TransaksiService.getTransaksi();

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _history = (result['data'] as List?)
            ?.map((json) => TransaksiModel.fromJson(json))
            .where((t) => !t.isActive) // Hanya yang sudah keluar
            .toList() ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat riwayat transaksi...')
          : _error != null
              ? ErrorDisplayWidget(message: _error ?? 'Terjadi kesalahan', onRetry: _loadHistory)
              : _history.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.history_rounded,
                      title: 'Belum Ada Riwayat',
                      message: 'Riwayat transaksi yang sudah selesai akan muncul di sini',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final transaksi = _history[index];
                          final duration = (transaksi.waktuKeluar != null)
                              ? transaksi.waktuKeluar!.difference(transaksi.waktuMasuk)
                              : Duration.zero;
                          final hours = duration.inHours;
                          final minutes = duration.inMinutes % 60;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.success.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaksi.platNomor ?? 'Kendaraan #${transaksi.idParkir}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Area: ${transaksi.namaArea ?? '-'}', style: const TextStyle(fontSize: 13)),
                                        Text('Durasi: ${hours}j ${minutes}m', style: const TextStyle(fontSize: 13)),
                                        if (transaksi.biayaTotal != null)
                                          Text(
                                            'Biaya: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transaksi.biayaTotal)}',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (transaksi.waktuKeluar != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd MMM\\nHH:mm').format(transaksi.waktuKeluar ?? DateTime.now()),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
