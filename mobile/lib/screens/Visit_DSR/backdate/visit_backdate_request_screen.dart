import 'package:dart_crm/core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VisitBackdateRequestScreen extends StatefulWidget {
  const VisitBackdateRequestScreen({super.key});

  @override
  State<VisitBackdateRequestScreen> createState() => _VisitBackdateRequestScreenState();
}

class _VisitBackdateRequestScreenState extends State<VisitBackdateRequestScreen> {
  final TextEditingController _reason = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;
  bool _loadingHistory = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _error = null;
    });
    try {
      final response = await CrmApiClient.instance.get('/visits/backdate-requests');
      final data = Map<String, dynamic>.from(response.data as Map);
      final list = data['requests'] is List ? List<dynamic>.from(data['requests']) : const <dynamic>[];
      if (!mounted) return;
      setState(() {
        _requests = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = CrmApiClient.messageFrom(e));
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select the visit date first.')));
      return;
    }
    if (_reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reason is required.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await CrmApiClient.instance.post(
        '/visits/backdate-requests',
        data: {
          'visitDate': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'reason': _reason.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backdate request submitted for approval.')));
      _reason.clear();
      setState(() => _selectedDate = null);
      await _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(CrmApiClient.messageFrom(e)), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Visit Backdate Request'),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        foregroundColor: Colors.blueGrey[900],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Request permission for an older visit date', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _loading ? null : _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Visit Date', border: OutlineInputBorder()),
                        child: Text(_selectedDate == null ? 'Select date' : DateFormat('dd MMM yyyy').format(_selectedDate!)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reason,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send),
                        label: const Text('Submit Request'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('My Requests', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_loadingHistory) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            if (!_loadingHistory && _error == null && _requests.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No backdate requests yet.'))),
            ..._requests.map((r) => Card(
                  child: ListTile(
                    leading: Icon(_statusIcon((r['status'] ?? '').toString()), color: _statusColor((r['status'] ?? '').toString())),
                    title: Text((r['requested_visit_date'] ?? '').toString()),
                    subtitle: Text((r['reason'] ?? '').toString()),
                    trailing: Text((r['status'] ?? '').toString(), style: TextStyle(fontWeight: FontWeight.w700, color: _statusColor((r['status'] ?? '').toString()))),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Icons.check_circle_outline;
      case 'REJECTED':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }
}
