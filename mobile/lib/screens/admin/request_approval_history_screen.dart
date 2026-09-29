import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/screens/approvals/approval_request_detail_screen.dart';
import 'package:dart_crm/services/admin_v4_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequestApprovalHistoryScreen extends StatefulWidget {
  const RequestApprovalHistoryScreen({super.key});

  @override
  State<RequestApprovalHistoryScreen> createState() => _RequestApprovalHistoryScreenState();
}

class _RequestApprovalHistoryScreenState extends State<RequestApprovalHistoryScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = const [];
  bool _loading = true;
  String? _error;
  String _status = 'ALL';
  String _module = 'ALL';
  final Set<int> _selected = {};

  static const _modules = <String>[
    'ALL',
    'CUSTOMER_CREATE',
    'CUSTOMER_UPDATE',
    'CUSTOMER_DELETE',
    'CONTACT_CREATE',
    'VISIT_BACKDATE',
    'CUSTOMER_SAMPLING',
    'SELF_STOCK',
  ];

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
      final rows = await AdminV4Service.adminHistory(status: _status, module: _module, search: _search.text);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _selected.removeWhere((id) => !_rows.any((r) => _asInt(r['history_id']) == id));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = CrmApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteOne(Map<String, dynamic> row) async {
    if ((row['status'] ?? '').toString().toUpperCase() == 'PENDING') return;
    final ok = await _confirm('Remove this history record?');
    if (!ok) return;
    try {
      final message = await AdminV4Service.deleteHistory(_asInt(row['history_id']));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(CrmApiClient.messageFrom(e)), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _bulkDelete() async {
    final completedIds = _rows
        .where((r) => _selected.contains(_asInt(r['history_id'])) && (r['status'] ?? '').toString().toUpperCase() != 'PENDING')
        .map((r) => _asInt(r['history_id']))
        .toList();
    if (completedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select completed Approved/Rejected records.')));
      return;
    }
    final ok = await _confirm('Remove ${completedIds.length} selected history record(s)?');
    if (!ok) return;
    try {
      final message = await AdminV4Service.bulkDeleteHistory(completedIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _selected.clear());
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(CrmApiClient.messageFrom(e)), backgroundColor: Colors.redAccent));
    }
  }

  Future<bool> _confirm(String message) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm'),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
          ],
        ),
      ) ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Request & Approval History'),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        foregroundColor: Colors.blueGrey[900],
        actions: [
          if (_selected.isNotEmpty) IconButton(tooltip: 'Delete selected completed history', onPressed: _bulkDelete, icon: const Icon(Icons.delete_sweep)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(labelText: 'Search request / person / code', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: const ['ALL','PENDING','APPROVED','REJECTED'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (value) { if (value == null) return; setState(() => _status = value); _load(); },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _module,
                      decoration: const InputDecoration(labelText: 'Module', border: OutlineInputBorder()),
                      items: _modules.map((e) => DropdownMenuItem(value: e, child: Text(_prettyModule(e), overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (value) { if (value == null) return; setState(() => _module = value); _load(); },
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, textAlign: TextAlign.center))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _rows.isEmpty
                            ? ListView(children: const [SizedBox(height: 180), Center(child: Text('No request history found'))])
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
                                itemCount: _rows.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (_, index) {
                                  final row = _rows[index];
                                  final id = _asInt(row['history_id']);
                                  final status = (row['status'] ?? '').toString().toUpperCase();
                                  final pending = status == 'PENDING';
                                  final created = DateTime.tryParse((row['created_at'] ?? '').toString());
                                  return Card(
                                    child: InkWell(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ApprovalRequestDetailScreen(
                                              approvalId: _asInt(row['approval_request_id']),
                                              moduleName: (row['module_name'] ?? '').toString(),
                                              title: '${_prettyModule((row['module_name'] ?? '').toString())} History',
                                            ),
                                          ),
                                        );
                                        _load();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Checkbox(
                                              value: _selected.contains(id),
                                              onChanged: pending ? null : (value) => setState(() { if (value == true) _selected.add(id); else _selected.remove(id); }),
                                            ),
                                            Expanded(
                                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                Row(children: [
                                                  Expanded(child: Text((row['request_number'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                                  _statusChip(status),
                                                ]),
                                                const SizedBox(height: 4),
                                                Text(_prettyModule((row['module_name'] ?? '').toString())),
                                                Text('Requested by: ${row['requested_by'] ?? ''} (${row['requester_profile_code'] ?? ''})'),
                                                if (pending) Text('Pending with: ${row['current_approver'] ?? 'Unassigned'} • Level ${row['current_level'] ?? ''}'),
                                                if (!pending) Text('Last action: ${row['last_action'] ?? ''} by ${row['last_action_by'] ?? ''} (${row['last_actor_profile_code'] ?? ''})'),
                                                if (created != null) Text(DateFormat('dd MMM yyyy, hh:mm a').format(created.toLocal()), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                              ]),
                                            ),
                                            if (!pending)
                                              IconButton(tooltip: 'Remove history', onPressed: () => _deleteOne(row), icon: const Icon(Icons.delete_outline)),
                                          ],
                                        ),
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

  Widget _statusChip(String status) {
    final color = status == 'APPROVED' ? Colors.green : status == 'REJECTED' ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

int _asInt(dynamic value) => int.tryParse((value ?? '').toString()) ?? 0;
String _prettyModule(String value) {
  if (value == 'ALL') return 'All Modules';
  return value.toLowerCase().split('_').map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}').join(' ');
}
