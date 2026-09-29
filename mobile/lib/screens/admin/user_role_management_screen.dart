import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/screens/admin/user_role_form_screen.dart';
import 'package:dart_crm/services/admin_v4_service.dart';
import 'package:flutter/material.dart';

class UserRoleManagementScreen extends StatefulWidget {
  const UserRoleManagementScreen({super.key});

  @override
  State<UserRoleManagementScreen> createState() => _UserRoleManagementScreenState();
}

class _UserRoleManagementScreenState extends State<UserRoleManagementScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _users = const [];
  bool _loading = true;
  String? _error;
  String _status = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await AdminV4Service.users(search: _search.text, status: _status);
      if (!mounted) return;
      setState(() => _users = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = CrmApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([int? executiveId]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UserRoleFormScreen(executiveId: executiveId)),
    );
    if (changed == true) _load();
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final id = _asInt(user['executive_id']);
    final active = (user['status'] ?? '').toString().toUpperCase() == 'ACTIVE';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(active ? 'Deactivate account?' : 'Reactivate account?'),
        content: Text(active
            ? 'The account will no longer be able to log in. Historical CRM records will be preserved.'
            : 'The account will be allowed to log in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(active ? 'Deactivate' : 'Reactivate')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final message = active ? await AdminV4Service.deactivate(id) : await AdminV4Service.reactivate(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(CrmApiClient.messageFrom(e)), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('User & Role Management'),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        foregroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Account'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      labelText: 'Search name / code / login email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All')),
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _Error(message: _error!, onRetry: _load)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _users.isEmpty
                            ? ListView(children: const [SizedBox(height: 180), Center(child: Text('No accounts found'))])
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                                itemCount: _users.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final u = _users[index];
                                  final active = (u['status'] ?? '').toString().toUpperCase() == 'ACTIVE';
                                  final approval = _asBool(u['approval_enabled']);
                                  final isAdmin = _asBool(u['is_admin']);
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(child: Text((u['profile_code'] ?? '?').toString())),
                                      title: Text('${u['executive_name'] ?? ''} (${u['executive_code'] ?? ''})'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${u['profile_name'] ?? ''} • ${u['designation'] ?? ''}'),
                                          Text('Login: ${u['login_email'] ?? ''}'),
                                          Text('Manager: ${u['manager_name'] ?? 'None'}'),
                                          Text('Approval: ${approval ? 'YES' : 'NO'} • Pending: ${u['pending_approvals'] ?? 0}'),
                                          if ((u['menu_access_mode'] ?? 'PROFILE') == 'CUSTOM') const Text('Menu access: Custom'),
                                        ],
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') _openForm(_asInt(u['executive_id']));
                                          if (value == 'toggle') _toggleActive(u);
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Edit role/account')),
                                          PopupMenuItem(
                                            value: 'toggle',
                                            enabled: !isAdmin || !active,
                                            child: Text(active ? 'Deactivate' : 'Reactivate'),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _openForm(_asInt(u['executive_id'])),
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

int _asInt(dynamic value) => int.tryParse((value ?? '').toString()) ?? 0;
bool _asBool(dynamic value) => value == true || value == 1 || value?.toString() == '1';

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Error({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ]),
        ),
      );
}
