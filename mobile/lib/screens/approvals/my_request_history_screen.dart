import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/screens/approvals/approval_request_detail_screen.dart';
import 'package:dart_crm/services/admin_v4_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyRequestHistoryScreen extends StatefulWidget {
  const MyRequestHistoryScreen({super.key});

  @override
  State<MyRequestHistoryScreen> createState() => _MyRequestHistoryScreenState();
}

class _MyRequestHistoryScreenState extends State<MyRequestHistoryScreen> {
  List<Map<String, dynamic>> _rows = const [];
  bool _loading = true;
  String? _error;
  String _status = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await AdminV4Service.myRequestHistory(status: _status);
      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = CrmApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Request History'),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        foregroundColor: Colors.blueGrey[900],
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
            items: const ['ALL','PENDING','APPROVED','REJECTED'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) { if (value == null) return; setState(() => _status = value); _load(); },
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
                          ? ListView(children: const [SizedBox(height: 180), Center(child: Text('No requests found'))])
                          : ListView.separated(
                              padding: const EdgeInsets.all(10),
                              itemCount: _rows.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (_, index) {
                                final r = _rows[index];
                                final status = (r['status'] ?? '').toString().toUpperCase();
                                final date = DateTime.tryParse((r['created_at'] ?? '').toString());
                                return Card(
                                  child: ListTile(
                                    title: Text((r['request_number'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(_prettyModule((r['module_name'] ?? '').toString())),
                                      if (status == 'PENDING') Text('Pending with: ${r['current_approver_name'] ?? 'Unassigned'} (${r['current_approver_profile_code'] ?? ''})'),
                                      if (status != 'PENDING') Text('Last action: ${r['last_action'] ?? ''} by ${r['last_action_by'] ?? ''} (${r['last_action_profile_code'] ?? ''})'),
                                      if ((r['last_remarks'] ?? '').toString().isNotEmpty) Text('Remarks: ${r['last_remarks']}'),
                                      if (date != null) Text(DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ]),
                                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: status == 'APPROVED' ? Colors.green : status == 'REJECTED' ? Colors.red : Colors.orange)),
                                      const Icon(Icons.chevron_right),
                                    ]),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ApprovalRequestDetailScreen(
                                          approvalId: _asInt(r['approval_id']),
                                          moduleName: (r['module_name'] ?? '').toString(),
                                          title: 'Request Details',
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
        ),
      ]),
    );
  }
}

int _asInt(dynamic value) => int.tryParse((value ?? '').toString()) ?? 0;
String _prettyModule(String value) => value.toLowerCase().split('_').map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}').join(' ');
