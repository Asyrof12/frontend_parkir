import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'package:intl/intl.dart';

class LogActivityScreen extends StatefulWidget {
  const LogActivityScreen({super.key});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await LogService.getLogs();
      if (!mounted) return;

      if (result['success'] == true) {
        dynamic data = result['data'];

        // ✅ HANDLE RESPONSE NESTED
        if (data is Map && data.containsKey('data')) {
          print('🔄 Data is NESTED! Extracting inner data...');
          data = data['data'];
        }

        if (data is! List) {
          throw Exception('Format data log tidak valid');
        }

        setState(() {
          _logs = List<Map<String, dynamic>>.from(data);
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

  IconData _getIconForActivity(String activity) {
    if (activity.contains('login') || activity.contains('Login')) {
      return Icons.login_rounded;
    } else if (activity.contains('logout') || activity.contains('Logout')) {
      return Icons.logout_rounded;
    } else if (activity.contains('tambah') || activity.contains('create')) {
      return Icons.add_circle_outline_rounded;
    } else if (activity.contains('update') || activity.contains('edit')) {
      return Icons.edit_outlined;
    } else if (activity.contains('hapus') || activity.contains('delete')) {
      return Icons.delete_outline_rounded;
    } else if (activity.contains('masuk')) {
      return Icons.arrow_downward_rounded;
    } else if (activity.contains('keluar')) {
      return Icons.arrow_upward_rounded;
    }
    return Icons.info_outline_rounded;
  }

  Color _getColorForActivity(String activity) {
    if (activity.contains('login') || activity.contains('Login')) {
      return Colors.green;
    } else if (activity.contains('logout') || activity.contains('Logout')) {
      return Colors.orange;
    } else if (activity.contains('tambah') || activity.contains('create')) {
      return Colors.blue;
    } else if (activity.contains('hapus') || activity.contains('delete')) {
      return Colors.red;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Aktifitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat log aktifitas...')
          : _error != null
          ? ErrorDisplayWidget(message: _error ?? 'Terjadi kesalahan', onRetry: _loadLogs)
          : _logs.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.history_rounded,
              title: 'Belum Ada Log',
              message: 'Log aktifitas akan muncul di sini',
            )
          : RefreshIndicator(
              onRefresh: _loadLogs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  final activity = log['aktivitas'] ?? '';
                  final username = log['username'] ?? 'Unknown';
                  final timestamp = log['waktu'] != null
                      ? DateTime.tryParse(log['waktu'])
                      : null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorForActivity(
                          activity,
                        ).withOpacity(0.1),
                        child: Icon(
                          _getIconForActivity(activity),
                          color: _getColorForActivity(activity),
                        ),
                      ),
                      title: Text(
                        activity,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                username,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          if (timestamp != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy, HH:mm',
                                  ).format(timestamp),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
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
