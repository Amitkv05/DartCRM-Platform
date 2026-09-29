import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/models/approvals/approval_center_models.dart';
import 'package:dart_crm/providers/approvals/approval_center_provider.dart';
import 'package:dart_crm/screens/approvals/approval_request_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ApprovalModuleListScreen extends ConsumerWidget {
  final String moduleName;
  final String title;

  const ApprovalModuleListScreen({
    super.key,
    required this.moduleName,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalListProvider(moduleName));
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        foregroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(approvalListProvider(moduleName)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: CrmApiClient.messageFrom(error),
          onRetry: () => ref.invalidate(approvalListProvider(moduleName)),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(approvalListProvider(moduleName));
            await ref.read(approvalListProvider(moduleName).future);
          },
          child: items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 180),
                    Icon(Icons.inbox_outlined, size: 70, color: Colors.grey),
                    SizedBox(height: 12),
                    Center(child: Text('No pending requests assigned to you')),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _ApprovalCard(
                    item: items[index],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ApprovalRequestDetailScreen(
                            approvalId: items[index].approvalId,
                            moduleName: moduleName,
                            title: title,
                          ),
                        ),
                      );
                      ref.invalidate(approvalListProvider(moduleName));
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final ApprovalSummary item;
  final VoidCallback onTap;

  const _ApprovalCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = item.createdAt == null
        ? ''
        : DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt!.toLocal());
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.requestNumber,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Level ${item.currentLevel}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Requested by: ${item.requestedBy}${item.requestedByCode.isEmpty ? '' : ' (${item.requestedByCode})'}'),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Open request', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 55, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
