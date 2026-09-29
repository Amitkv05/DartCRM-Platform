import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/services/admin_v4_service.dart';
import 'package:flutter/material.dart';

class UserRoleFormScreen extends StatefulWidget {
  final int? executiveId;
  const UserRoleFormScreen({super.key, this.executiveId});

  @override
  State<UserRoleFormScreen> createState() => _UserRoleFormScreenState();
}

class _UserRoleFormScreenState extends State<UserRoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _password = TextEditingController();
  final _executiveCode = TextEditingController();
  final _executiveName = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _designation = TextEditingController();

  List<Map<String, dynamic>> _profiles = const [];
  List<Map<String, dynamic>> _departments = const [];
  List<Map<String, dynamic>> _managers = const [];
  List<Map<String, dynamic>> _cities = const [];
  List<Map<String, dynamic>> _territories = const [];
  List<Map<String, dynamic>> _divisions = const [];
  List<Map<String, dynamic>> _menus = const [];

  int? _profileId;
  int? _departmentId;
  int? _managerExecutiveId;
  bool _approvalEnabled = false;
  String _menuAccessMode = 'PROFILE';
  Set<int> _cityIds = {};
  Set<int> _territoryIds = {};
  Set<int> _divisionIds = {};
  Set<int> _menuIds = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.executiveId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_loginEmail, _password, _executiveCode, _executiveName, _email, _mobile, _designation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final meta = await AdminV4Service.meta();
      _profiles = _maps(meta['profiles']);
      _departments = _maps(meta['departments']);
      _managers = _maps(meta['managers']);
      _cities = _maps(meta['cities']);
      _territories = _maps(meta['territories']);
      _divisions = _maps(meta['productDivisions']);
      _menus = _maps(meta['menus']);
      if (_editing) {
        final data = await AdminV4Service.user(widget.executiveId!);
        final u = data['executive'] is Map ? Map<String, dynamic>.from(data['executive'] as Map) : <String, dynamic>{};
        _loginEmail.text = (u['login_email'] ?? '').toString();
        _executiveCode.text = (u['executive_code'] ?? '').toString();
        _executiveName.text = (u['executive_name'] ?? '').toString();
        _email.text = (u['email'] ?? '').toString();
        _mobile.text = (u['mobile'] ?? '').toString();
        _designation.text = (u['designation'] ?? '').toString();
        _profileId = _nullableInt(u['profile_id']);
        _departmentId = _nullableInt(u['department_id']);
        _managerExecutiveId = _nullableInt(u['manager_executive_id']);
        _approvalEnabled = _asBool(u['approval_enabled']);
        _menuAccessMode = (u['menu_access_mode'] ?? 'PROFILE').toString();
        _cityIds = _intSet(u['cityIds']);
        _territoryIds = _intSet(u['territoryIds']);
        _divisionIds = _intSet(u['productDivisionIds']);
        _menuIds = _intSet(u['customMenuIds']);
      } else if (_profiles.isNotEmpty) {
        _profileId = _asInt(_profiles.first['id']);
      }
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = CrmApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _selectedProfile {
    for (final p in _profiles) {
      if (_asInt(p['id']) == _profileId) return p;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = _selectedProfile;
    final isAdmin = _asBool(profile?['is_admin']);
    if (!isAdmin && _managerExecutiveId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporting manager is required.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'loginEmail': _loginEmail.text.trim(),
        if (_password.text.trim().isNotEmpty) 'password': _password.text,
        'executiveCode': _executiveCode.text.trim(),
        'executiveName': _executiveName.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'mobile': _mobile.text.trim().isEmpty ? null : _mobile.text.trim(),
        'designation': _designation.text.trim().isEmpty ? null : _designation.text.trim(),
        'departmentId': _departmentId,
        'profileId': _profileId,
        'managerExecutiveId': isAdmin ? null : _managerExecutiveId,
        'approvalEnabled': isAdmin ? true : _approvalEnabled,
        'menuAccessMode': _menuAccessMode,
        'cityIds': _cityIds.toList(),
        'territoryIds': _territoryIds.toList(),
        'productDivisionIds': _divisionIds.toList(),
        'menuIds': _menuIds.toList(),
      };
      final message = _editing
          ? await AdminV4Service.updateUser(widget.executiveId!, payload)
          : await AdminV4Service.createUser(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(CrmApiClient.messageFrom(e)), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_editing ? 'Edit Account' : 'Add Account')),
        body: Center(child: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(_error!))),
      );
    }
    final profile = _selectedProfile;
    final levelRank = _asInt(profile?['level_rank']);
    final isAdmin = _asBool(profile?['is_admin']);
    final canApprove = isAdmin || levelRank > 1;
    final managerChoices = _managers.where((m) {
      if (_editing && _asInt(m['id']) == widget.executiveId) return false;
      if (isAdmin) return false;
      return _asBool(m['is_admin']) || _asInt(m['level_rank']) > levelRank;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_editing ? 'Edit Account & Role' : 'Add Account'),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        foregroundColor: Colors.blueGrey[900],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _section('Login Account', [
              _field(_loginEmail, 'Login Email', required: true, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(_password, _editing ? 'New Password (leave blank to keep current)' : 'Password', required: !_editing, obscure: true),
            ]),
            _section('Executive Profile', [
              _field(_executiveCode, 'Executive Code', required: true),
              const SizedBox(height: 10),
              _field(_executiveName, 'Executive Name', required: true),
              const SizedBox(height: 10),
              _field(_email, 'Work Email', keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(_mobile, 'Mobile', keyboard: TextInputType.phone),
              const SizedBox(height: 10),
              _field(_designation, 'Designation'),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                value: _departmentId,
                decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('No department')),
                  ..._departments.map((d) => DropdownMenuItem<int?>(value: _asInt(d['id']), child: Text((d['name'] ?? '').toString()))),
                ],
                onChanged: (value) => setState(() => _departmentId = value),
              ),
            ]),
            _section('Role & Hierarchy', [
              DropdownButtonFormField<int>(
                value: _profileId,
                decoration: const InputDecoration(labelText: 'Profile / Level', border: OutlineInputBorder()),
                items: _profiles.map((p) => DropdownMenuItem<int>(
                  value: _asInt(p['id']),
                  child: Text('${p['code']} - ${p['name']}'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _profileId = value;
                    final selected = _selectedProfile;
                    if (_asInt(selected?['level_rank']) <= 1 && !_asBool(selected?['is_admin'])) _approvalEnabled = false;
                    if (_asBool(selected?['is_admin'])) { _approvalEnabled = true; _managerExecutiveId = null; }
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                value: isAdmin ? null : (_managerExecutiveId != null && managerChoices.any((m) => _asInt(m['id']) == _managerExecutiveId) ? _managerExecutiveId : null),
                decoration: const InputDecoration(labelText: 'Reporting Manager', border: OutlineInputBorder()),
                items: [
                  if (isAdmin) const DropdownMenuItem<int?>(value: null, child: Text('Admin - no manager')),
                  ...managerChoices.map((m) => DropdownMenuItem<int?>(
                    value: _asInt(m['id']),
                    child: Text('${m['executive_name']} (${m['profile_code']})'),
                  )),
                ],
                onChanged: isAdmin ? null : (value) => setState(() => _managerExecutiveId = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Can approve requests'),
                subtitle: Text(canApprove ? 'If disabled, approval requests skip this executive.' : 'L1 is request-only.'),
                value: canApprove ? _approvalEnabled : false,
                onChanged: canApprove && !isAdmin ? (value) => setState(() => _approvalEnabled = value) : null,
              ),
            ]),
            _section('Access', [
              _pickerTile('Cities', _cities, _cityIds, (ids) => setState(() => _cityIds = ids)),
              _pickerTile('Territories', _territories, _territoryIds, (ids) => setState(() => _territoryIds = ids)),
              _pickerTile('Product Divisions', _divisions, _divisionIds, (ids) => setState(() => _divisionIds = ids), labelBuilder: (m) => '${m['code']} - ${m['name']}'),
            ]),
            _section('Menu Access', [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'PROFILE', label: Text('Profile Default')),
                  ButtonSegment(value: 'CUSTOM', label: Text('Custom')),
                ],
                selected: {_menuAccessMode},
                onSelectionChanged: (values) => setState(() => _menuAccessMode = values.first),
              ),
              if (_menuAccessMode == 'CUSTOM') ...[
                const SizedBox(height: 8),
                _pickerTile(
                  'Allowed Menus',
                  _menus,
                  _menuIds,
                  (ids) => setState(() => _menuIds = ids),
                  labelBuilder: (m) => '${m['menu_name']} → ${m['child_menu_name']}',
                ),
              ],
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_editing ? 'Save Changes' : 'Create Account'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ]),
        ),
      );

  Widget _field(TextEditingController controller, String label, {bool required = false, bool obscure = false, TextInputType? keyboard}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (value) => required && (value == null || value.trim().isEmpty) ? '$label is required' : null,
    );
  }

  Widget _pickerTile(
    String title,
    List<Map<String, dynamic>> options,
    Set<int> selected,
    ValueChanged<Set<int>> onChanged, {
    String Function(Map<String, dynamic>)? labelBuilder,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(selected.isEmpty ? 'None selected' : '${selected.length} selected'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await _selectMany(title, options, selected, labelBuilder: labelBuilder);
        if (result != null) onChanged(result);
      },
    );
  }

  Future<Set<int>?> _selectMany(
    String title,
    List<Map<String, dynamic>> options,
    Set<int> selected, {
    String Function(Map<String, dynamic>)? labelBuilder,
  }) async {
    final working = {...selected};
    return showDialog<Set<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: ListView(
              children: options.map((item) {
                final id = _asInt(item['id']);
                final label = labelBuilder?.call(item) ?? (item['name'] ?? item['executive_name'] ?? id).toString();
                return CheckboxListTile(
                  value: working.contains(id),
                  title: Text(label),
                  onChanged: (value) => setLocal(() {
                    if (value == true) working.add(id); else working.remove(id);
                  }),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, working), child: const Text('Apply')),
          ],
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];
int _asInt(dynamic value) => int.tryParse((value ?? '').toString()) ?? 0;
int? _nullableInt(dynamic value) {
  if (value == null) return null;
  final n = int.tryParse(value.toString());
  return n == 0 ? null : n;
}
bool _asBool(dynamic value) => value == true || value == 1 || value?.toString() == '1';
Set<int> _intSet(dynamic value) => value is List ? value.map(_asInt).where((e) => e > 0).toSet() : <int>{};
