import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/form_validators.dart';
import '../../utils/notifications.dart';
import '../../services/refresh_service.dart';



class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    RefreshService.instance.addListener(_onRefreshTriggered);
  }

  void _onRefreshTriggered() {
    _loadUsers();
  }

  @override
  void dispose() {
    RefreshService.instance.removeListener(_onRefreshTriggered);
    super.dispose();
  }


  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await UserService.getUsers();

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      try {
        List listUser;

        if (result['data'] is List) {
          // tanpa pagination
          listUser = result['data'];
        } else {
          // pakai pagination
          listUser = result['data']['data'] ?? [];
        }

        setState(() {
          _users = listUser.map((e) => UserModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Format data tidak valid: $e';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _error = result['message'] ?? 'Gagal memuat data user';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus user "$name"?'),
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

    final result = await UserService.deleteUser(id);

    if (!mounted) return;

    if (result['success']) {
      AppNotification.success(context, 'User berhasil dihapus');
      _loadUsers();
      RefreshService.instance.refreshDashboard();
    } else {

      AppNotification.error(context, result['message']);
    }

  }

  void _showUserForm([UserModel? user]) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user, onSaved: _loadUsers),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen User')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah User'),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat data user...')
          : _error != null
          ? ErrorDisplayWidget(
              message: _error ?? 'Terjadi kesalahan',
              onRetry: _loadUsers,
            )
          : _users.isEmpty
          ? EmptyStateWidget(
              icon: Icons.people_outline_rounded,
              title: 'Belum Ada User',
              message: 'Tambahkan user baru dengan menekan tombol + di bawah',
            )
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.isActive
                            ? AppColors.primary
                            : Colors.grey,
                        child: Text(
                          user.namaLengkap[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.namaLengkap,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('@${user.username}'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user.roleDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: user.isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user.isActive ? 'Aktif' : 'Nonaktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: user.isActive
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                            _showUserForm(user);
                          } else if (value == 'delete') {
                            _deleteUser(user.idUser, user.namaLengkap);
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

class UserFormDialog extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onSaved;

  const UserFormDialog({super.key, this.user, required this.onSaved});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  String _selectedRole = 'petugas';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.user?.namaLengkap ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.user?.username ?? '',
    );
    _passwordController = TextEditingController();
    if (widget.user != null) {
      _selectedRole = widget.user?.role ?? 'petugas';
      _isActive = widget.user?.isActive ?? true;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    final data = {
      'nama_lengkap': _namaController.text,
      'username': _usernameController.text,
      'role': _selectedRole,
      'status_aktif': _isActive ? 1 : 0,
      if (_passwordController.text.isNotEmpty)
        'password': _passwordController.text,
    };

    final result = widget.user == null
        ? await UserService.createUser(data)
        : await UserService.updateUser(widget.user!.idUser, data);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pop(context);
      AppNotification.success(
        context,
        widget.user == null ? 'User berhasil ditambahkan' : 'User berhasil diupdate',
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
      title: Text(widget.user == null ? 'Tambah User' : 'Edit User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) =>
                    FormValidators.required(value, 'Nama lengkap'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) =>
                    FormValidators.required(value, 'Username'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: widget.user == null
                      ? 'Password'
                      : 'Password (kosongkan jika tidak diubah)',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
                obscureText: true,
                validator: widget.user == null
                    ? (value) => FormValidators.minLength(value, 4, 'Password')
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Administrator'),
                  ),
                  DropdownMenuItem(value: 'petugas', child: Text('Petugas')),
                  DropdownMenuItem(value: 'owner', child: Text('Owner')),
                ],
                onChanged: (value) {
                  setState(() => _selectedRole = value ?? 'petugas');
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Status Aktif'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
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
              : Text(widget.user == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }
}
