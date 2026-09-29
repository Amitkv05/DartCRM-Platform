import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/models/approvals/approval_center_models.dart';
import 'package:dart_crm/providers/approvals/approval_center_provider.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApprovalRoleManagementScreen extends ConsumerWidget {
  const ApprovalRoleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(approvalRoleListProvider);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Approval Role Management'),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        foregroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(approvalRoleListProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: roles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 55, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(CrmApiClient.messageFrom(error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(approvalRoleListProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (executives) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(approvalRoleListProvider);
            await ref.read(approvalRoleListProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: executives.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _ExecutiveApprovalRoleCard(executive: executives[index]),
          ),
        ),
      ),
    );
  }
}

class _ExecutiveApprovalRoleCard extends ConsumerStatefulWidget {
  final ApprovalRoleExecutive executive;
  const _ExecutiveApprovalRoleCard({required this.executive});

  @override
  ConsumerState<_ExecutiveApprovalRoleCard> createState() => _ExecutiveApprovalRoleCardState();
}

class _ExecutiveApprovalRoleCardState extends ConsumerState<_ExecutiveApprovalRoleCard> {
  bool _loading = false;

  Future<void> _change(bool value) async {
    if (_loading) return;
    final executive = widget.executive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(value ? 'Enable approval role?' : 'Disable approval role?'),
        content: Text(
          value
              ? '${executive.executiveName} will become eligible to receive approval requests from junior executives.'
              : '${executive.executiveName} will be skipped in the approval chain. Pending requests will be reassigned to the next eligible manager when possible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final message = await updateExecutiveApprovalRole(
        executiveId: executive.executiveId,
        approvalEnabled: value,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      ref.invalidate(approvalRoleListProvider);

      // If the admin changed their own role, refresh menus immediately.
      final currentExecutiveId = ref.read(authProvider).loginResponse?.executiveBasicData?.firstOrNull?.executiveId;
      if (currentExecutiveId == executive.executiveId) {
        await ref.read(authProvider.notifier).getMenus();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(CrmApiClient.messageFrom(error)), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.executive;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Text(e.profileCode.isEmpty ? '?' : e.profileCode),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.executiveName} (${e.executiveCode})', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${e.profileName} • ${e.designation}'),
                  if (e.managerName != null && e.managerName!.isNotEmpty) Text('Reports to: ${e.managerName}'),
                  Text('Pending approvals: ${e.pendingApprovals}'),
                  if (e.levelRank == 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'L1 is request-only. Approval rights cannot be enabled for this level.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _loading
                ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))
                : Switch(
                    value: e.levelRank <= 1 ? false : e.approvalEnabled,
                    onChanged: e.levelRank <= 1 ? null : _change,
                  ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
