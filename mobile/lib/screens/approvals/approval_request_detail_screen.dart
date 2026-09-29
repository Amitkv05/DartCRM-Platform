import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/models/approvals/approval_center_models.dart';
import 'package:dart_crm/providers/approvals/approval_center_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ApprovalRequestDetailScreen extends ConsumerStatefulWidget {
  final int approvalId;
  final String moduleName;
  final String title;

  const ApprovalRequestDetailScreen({
    super.key,
    required this.approvalId,
    required this.moduleName,
    required this.title,
  });

  @override
  ConsumerState<ApprovalRequestDetailScreen> createState() => _ApprovalRequestDetailScreenState();
}

class _ApprovalRequestDetailScreenState extends ConsumerState<ApprovalRequestDetailScreen> {
  final TextEditingController _remarks = TextEditingController();
  final Map<int, TextEditingController> _qtyControllers = {};
  bool _sendToNext = true;
  bool _submitting = false;
  bool _initializedQuantities = false;

  @override
  void dispose() {
    _remarks.dispose();
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _ensureQuantityControllers(ApprovalDetailData data) {
    if (_initializedQuantities || !data.capabilities.supportsEditableQuantities) return;
    final items = _mapList(data.requestData['items']);
    for (final item in items) {
      final itemId = _asInt(item['item_id'] ?? item['id']);
      if (itemId <= 0) continue;
      final requested = _asNum(item['requested_qty']);
      final current = item['approved_qty'] == null ? requested : _asNum(item['approved_qty']);
      _qtyControllers[itemId] = TextEditingController(text: _prettyNumber(current));
    }
    _sendToNext = data.capabilities.canSendToNextLevel;
    _initializedQuantities = true;
  }

  Future<void> _submit(ApprovalDetailData data, String action) async {
    if (_submitting) return;
    if (action == 'REJECT' && _remarks.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remarks are required when rejecting a request.')),
      );
      return;
    }

    List<Map<String, dynamic>>? items;
    if (action == 'APPROVE' && data.capabilities.supportsEditableQuantities) {
      items = [];
      for (final item in _mapList(data.requestData['items'])) {
        final itemId = _asInt(item['item_id'] ?? item['id']);
        final requested = _asNum(item['requested_qty']);
        final approved = double.tryParse(_qtyControllers[itemId]?.text.trim() ?? '');
        if (approved == null || approved < 0 || approved > requested) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Approved quantity must be between 0 and ${_prettyNumber(requested)}.')),
          );
          return;
        }
        items.add({'itemId': itemId, 'approvedQty': approved});
      }
    }

    setState(() => _submitting = true);
    try {
      final message = await submitApprovalAction(
        approvalId: widget.approvalId,
        action: action,
        remarks: _remarks.text,
        sendToNextLevel: action == 'APPROVE' && data.capabilities.canSendToNextLevel ? _sendToNext : false,
        items: items,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      ref.invalidate(approvalDetailProvider(widget.approvalId));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(CrmApiClient.messageFrom(error)), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalDetailProvider(widget.approvalId));
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        foregroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            onPressed: () {
              _initializedQuantities = false;
              ref.invalidate(approvalDetailProvider(widget.approvalId));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 55, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(CrmApiClient.messageFrom(error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(approvalDetailProvider(widget.approvalId)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          _ensureQuantityControllers(data);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _approvalHeader(data),
                    const SizedBox(height: 10),
                    ..._moduleContent(data),
                    if (data.history.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _historyCard(data.history),
                    ],
                    if (data.capabilities.canAct) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _remarks,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Approval remarks',
                          hintText: 'Optional for approval, required for rejection',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (data.capabilities.canSendToNextLevel) ...[
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _sendToNext,
                          onChanged: _submitting ? null : (value) => setState(() => _sendToNext = value ?? false),
                          title: const Text('Approve and send to Next Level Approval'),
                          subtitle: Text(_nextLevelText(data.capabilities)),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (!_sendToNext)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'This approval will be FINAL. It will not be sent to another manager.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                      ] else ...[
                        const SizedBox(height: 10),
                        const Text('No higher approval-enabled manager is available. Approval will be final.'),
                      ],
                    ],
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              if (data.capabilities.canAct) _actionBar(data),
            ],
          );
        },
      ),
    );
  }

  Widget _approvalHeader(ApprovalDetailData data) {
    final a = data.approval;
    final created = DateTime.tryParse((a['created_at'] ?? '').toString());
    return _section(
      'Request',
      [
        _detailRow('Request No.', a['request_number']),
        _detailRow('Requested By', '${a['requested_by_name'] ?? ''} ${a['requested_by_code'] == null ? '' : '(${a['requested_by_code']})'}'),
        _detailRow('Current Level', a['current_level']),
        _detailRow('Status', a['status']),
        if (created != null) _detailRow('Submitted', DateFormat('dd MMM yyyy, hh:mm a').format(created.toLocal())),
      ],
    );
  }

  List<Widget> _moduleContent(ApprovalDetailData data) {
    switch (widget.moduleName) {
      case 'CUSTOMER_CREATE':
      case 'CUSTOMER_DELETE':
        return [_customerCard(data.requestData, widget.moduleName == 'CUSTOMER_DELETE')];
      case 'CUSTOMER_UPDATE':
        return [_customerUpdateCard(data.requestData)];
      case 'CONTACT_CREATE':
        return [_contactCard(data.requestData)];
      case 'VISIT_BACKDATE':
        return [_backdateCard(data.requestData)];
      case 'CUSTOMER_SAMPLING':
      case 'SELF_STOCK':
        return [_stockRequestCard(data)];
      default:
        return [_jsonCard('Request Data', data.requestData)];
    }
  }

  Widget _customerCard(Map<String, dynamic> data, bool deleting) {
    final c = _map(data['customer']);
    final school = _map(data['school']);
    final contacts = _mapList(data['contacts']);
    return _section(
      deleting ? 'Customer Delete Request' : 'Customer Creation Request',
      [
        _detailRow('Customer', c['customer_name']),
        _detailRow('Code', c['customer_code']),
        _detailRow('Type', c['customer_type']),
        _detailRow('Address', c['address']),
        _detailRow('City', c['city']),
        _detailRow('Pincode', c['pincode']),
        _detailRow('Mobile', c['mobile']),
        _detailRow('Email', c['email']),
        _detailRow('Validation', c['validation_status']),
        if (school.isNotEmpty) ...[
          const Divider(),
          _detailRow('Board', school['board_name']),
          _detailRow('Start Class', school['start_class']),
          _detailRow('End Class', school['end_class']),
        ],
        if (contacts.isNotEmpty) ...[
          const Divider(),
          const Text('Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
          ...contacts.map((contact) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${contact['first_name'] ?? ''} ${contact['last_name'] ?? ''}  •  ${contact['mobile'] ?? ''}'),
              )),
        ],
      ],
    );
  }

  Widget _customerUpdateCard(Map<String, dynamic> data) {
    final change = _map(data['changeRequest']);
    final original = _map(change['original_snapshot']);
    final originalCustomer = _map(original['customer']);
    final proposed = _map(change['proposed_payload']);
    return Column(
      children: [
        _section('Current Customer Data', _readableMapRows(originalCustomer)),
        const SizedBox(height: 10),
        _section('Requested Changes', _readableMapRows(proposed, highlight: true)),
      ],
    );
  }

  Widget _contactCard(Map<String, dynamic> data) {
    final c = _map(data['contact']);
    return _section('New Contact Request', [
      _detailRow('Customer', '${c['customer_name'] ?? ''} ${c['customer_code'] == null ? '' : '(${c['customer_code']})'}'),
      _detailRow('Name', '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'),
      _detailRow('Designation', c['designation']),
      _detailRow('Mobile', c['mobile']),
      _detailRow('Email', c['email']),
      _detailRow('Residential Address', c['residential_address']),
      _detailRow('Status', c['contact_status']),
    ]);
  }

  Widget _backdateCard(Map<String, dynamic> data) {
    final b = _map(data['backdateRequest']);
    return _section('Visit Backdate Request', [
      _detailRow('Executive', '${b['executive_name'] ?? ''} ${b['executive_code'] == null ? '' : '(${b['executive_code']})'}'),
      _detailRow('Requested Visit Date', b['requested_visit_date']),
      _detailRow('Reason', b['reason']),
      _detailRow('Status', b['status']),
    ]);
  }

  Widget _stockRequestCard(ApprovalDetailData data) {
    final request = _map(data.requestData['request']);
    final items = _mapList(data.requestData['items']);
    return Column(
      children: [
        _section(widget.moduleName == 'SELF_STOCK' ? 'Self-Stock Request' : 'Customer Sampling Request', [
          _detailRow('Request No.', request['request_number']),
          _detailRow('Executive', request['executive_name']),
          if (widget.moduleName == 'CUSTOMER_SAMPLING') _detailRow('Customer', request['customer_name']),
          _detailRow('Shipment Mode', request['shipment_mode']),
          _detailRow('Request Status', request['request_status']),
          _detailRow('Available Budget', request['available_budget']),
          _detailRow('Requested Budget', request['requested_budget']),
          _detailRow('Remarks', request['request_remarks']),
        ]),
        const SizedBox(height: 10),
        _section('Books / Products', [
          if (items.isEmpty) const Text('No items found'),
          ...items.map((item) => _quantityItem(data, item)),
        ]),
      ],
    );
  }

  Widget _quantityItem(ApprovalDetailData data, Map<String, dynamic> item) {
    final itemId = _asInt(item['item_id'] ?? item['id']);
    final requested = _asNum(item['requested_qty']);
    final previous = _asNum(item['approved_qty'] ?? item['previous_approved_qty']);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((item['title'] ?? 'Book').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text('Requested: ${_prettyNumber(requested)}'),
            Text('Previous/Current approval: ${_prettyNumber(previous)}'),
            if (data.capabilities.canAct && data.capabilities.supportsEditableQuantities) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _qtyControllers[itemId],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Approved Quantity',
                  helperText: 'You may increase/decrease up to requested qty ${_prettyNumber(requested)}',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _historyCard(List<Map<String, dynamic>> history) {
    return _section('Approval History', [
      ...history.map((h) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.history),
            title: Text('${h['action'] ?? ''} • ${h['action_by_name'] ?? ''}'),
            subtitle: Text('${h['remarks'] ?? ''}${h['created_at'] == null ? '' : '\n${h['created_at']}'}'),
          )),
    ]);
  }

  Widget _actionBar(ApprovalDetailData data) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _submitting ? null : () => _submit(data, 'REJECT'),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _submitting ? null : () => _submit(data, 'APPROVE'),
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: const Text('Approve'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nextLevelText(ApprovalCapabilities capabilities) {
    final next = capabilities.nextEligibleApprover;
    if (next == null) return 'No higher approval-enabled manager';
    return 'Next: ${next['executive_name'] ?? ''} (${next['profile_code'] ?? 'Level ${next['level_rank'] ?? ''}'})';
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final text = _display(value);
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 125, child: Text(label, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600))),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  List<Widget> _readableMapRows(Map<String, dynamic> map, {bool highlight = false}) {
    const ignored = {'id', 'created_at', 'updated_at', 'created_by_user_id', 'created_by_executive_id'};
    return map.entries
        .where((e) => !ignored.contains(e.key) && e.value != null)
        .map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 135, child: Text(_label(e.key), style: const TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(
                    child: Text(
                      _display(e.value),
                      style: highlight ? TextStyle(color: Colors.blueGrey[900]) : null,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  Widget _jsonCard(String title, Map<String, dynamic> map) => _section(title, _readableMapRows(map));

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static int _asInt(dynamic value) => int.tryParse((value ?? '').toString()) ?? 0;
  static double _asNum(dynamic value) => double.tryParse((value ?? '0').toString()) ?? 0;

  static String _prettyNumber(num value) => value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);

  static String _display(dynamic value) {
    if (value == null) return '';
    if (value is Map || value is List) return value.toString();
    return value.toString();
  }

  static String _label(String key) {
    final spaced = key.replaceAll('_', ' ').replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced.split(' ').where((e) => e.isNotEmpty).map((e) => '${e[0].toUpperCase()}${e.substring(1)}').join(' ');
  }
}
