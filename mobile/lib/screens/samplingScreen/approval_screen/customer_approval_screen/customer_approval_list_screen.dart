import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/providers/samplingProvider/approval/Customer_approval_provider/customer_approval_list_provider.dart';
import 'package:dart_crm/providers/samplingProvider/approval/Customer_approval_provider/customer_bulk_approval_provider.dart';
import 'package:dart_crm/screens/homeScreen/widget/userHeader.dart';
import 'package:dart_crm/screens/samplingScreen/approval_screen/customer_approval_screen/customer_approval_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_crm/providers/auth_provider.dart';

class CustomerApprovalScreen extends ConsumerStatefulWidget {
  const CustomerApprovalScreen({super.key});

  @override
  _CustomerApprovalScreenState createState() => _CustomerApprovalScreenState();
}

class _CustomerApprovalScreenState
    extends ConsumerState<CustomerApprovalScreen> {
  late List<bool> _selectedRequests;
  bool _isSelectAll = false;
  final TextEditingController _remarksController = TextEditingController();
  bool _isApproveLoading = false;
  bool _isRejectLoading = false;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedRequests = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.token != null && authState.loginResponse != null) {
        final executiveId =
            authState.loginResponse!.executiveBasicData![0].executiveId;
        ref.read(customerApprovalListProvider.notifier).fetchApprovalList(
              executiveId: executiveId,
              listFor: 'Approval',
            );
      }
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _refreshList(WidgetRef ref, int executiveId) async {
    await ref.read(customerApprovalListProvider.notifier).fetchApprovalList(
          executiveId: executiveId,
          listFor: 'Approval',
        );
    setState(() {
      _selectedRequests = List.generate(
        ref.read(customerApprovalListProvider).response?.approvalList.length ??
            0,
        (_) => false,
      );
      _isSelectAll = false;
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _isSelectAll = value ?? false;
      _selectedRequests =
          List.generate(_selectedRequests.length, (_) => _isSelectAll);
    });
  }

  bool _validateBudget(CustomerApprovalListState approvalState) {
    final samplingBudgetCheckApplied =
        AppUtils.filterSetup("SamplingBudgetCheckApplied");
    if (samplingBudgetCheckApplied?.keyValue != "Yes") {
      print("Budget check skipped: SamplingBudgetCheckApplied is not 'Yes'");
      return true; // Skip budget check
    }

    final customerSamplingApprovalOnlyWithBudget =
        AppUtils.filterSetup("CustomerSamplingApprovalOnlyWithBudget");
    final requestedBudget = approvalState.response!.approvalList[0].finalBudget;
    final availableBudget =
        approvalState.response!.approvalList[0].availableBudget;
    // bool hasBudget = availableBudget >= requestedBudget == true;
    bool hasBudget = availableBudget >= requestedBudget == true &&
        availableBudget <= 0 == false;
    print("Budget check applied: hasBudget=$hasBudget");
    print(
        "Budget check applied: availableBudget=$availableBudget & requestedBudget=$requestedBudget");

    if (customerSamplingApprovalOnlyWithBudget?.keyValue == "N") {
      print(
          "Approval allowed regardless of budget due to CustomerSamplingApprovalOnlyWithBudget='N'");
      return true; // Allow approval even without budget
    }

    if (!hasBudget) {
      print(
          "Approval blocked: No budget available and CustomerSamplingApprovalOnlyWithBudget is 'Y'");
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Approval failed: No budget available for selected requests.'),
        ),
      );
      return false; // Block approval due to no budget
    }

    return true; // Budget check passed
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final approvalState = ref.watch(customerApprovalListProvider);
    final bulkApprovalState = ref.watch(customerBulkApprovalProvider);

    if (authState.token == null || authState.loginResponse == null) {
      return _buildLoginPrompt(context);
    }

    final executiveId =
        authState.loginResponse!.executiveBasicData![0].executiveId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Userheader(),
            Expanded(
              child: _buildContent(context, approvalState, executiveId),
            ),
            _buildStatusIndicator(bulkApprovalState),
            _buildActionButtons(
                context, authState, approvalState, bulkApprovalState),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Customer Approvals',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color.fromRGBO(252, 242, 219, 1),
      foregroundColor: Colors.black,
      flexibleSpace: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(252, 242, 219, 1)),
      ),
    );
  }

  Widget _buildContent(BuildContext context,
      CustomerApprovalListState approvalState, int executiveId) {
    if (approvalState.isLoading && _selectedRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    if (approvalState.errorMessage != null) {
      return _buildErrorWidget(approvalState.errorMessage!, executiveId);
    }

    return RefreshIndicator(
      color: Colors.blue[800],
      onRefresh: () => _refreshList(ref, executiveId),
      child: approvalState.response == null ||
              approvalState.response!.approvalList.isEmpty
          ? _buildEmptyState()
          : _buildApprovalList(context, approvalState, executiveId),
    );
  }

  Widget _buildApprovalList(BuildContext context,
      CustomerApprovalListState approvalState, int executiveId) {
    if (_selectedRequests.length <
        approvalState.response!.approvalList.length) {
      _selectedRequests = List.generate(
          approvalState.response!.approvalList.length, (_) => false);
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select All',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: _isSelectAll,
                  onChanged: _toggleSelectAll,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  activeColor: Color.fromRGBO(251, 201, 85, 1),
                  checkColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
            itemCount: approvalState.response!.approvalList.length,
            itemBuilder: (context, index) {
              final item = approvalState.response!.approvalList[index];
              return _buildApprovalCard(context, item, index, executiveId);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalCard(
      BuildContext context, dynamic item, int index, int executiveId) {
    Color statusColor;
    Color statusBackground;
    switch (item.requestStatus.toLowerCase()) {
      case 'pending':
      case 'PENDING FOR LEVEL 2':
        statusColor = Colors.orange[800]!;
        statusBackground = Colors.orange[50]!;
        break;
      case 'approved':
        statusColor = Colors.green[800]!;
        statusBackground = Colors.green[50]!;
        break;
      case 'rejected':
        statusColor = Colors.red[800]!;
        statusBackground = Colors.red[50]!;
        break;
      default:
        statusColor = Colors.grey[800]!;
        statusBackground = Colors.grey[50]!;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _selectedRequests[index] ? statusBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerApprovalDetailsScreen(
                  requestId: item.requestId.toString(),
                  customerId: item.customerId.toString(),
                  customerType: item.customerType,
                ),
              ),
            );
            if (result == true) {
              await _refreshList(ref, executiveId);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Request #${item.requestNumber}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: _selectedRequests[index],
                        onChanged: (value) {
                          setState(() {
                            _selectedRequests[index] = value!;
                            _isSelectAll =
                                _selectedRequests.every((selected) => selected);
                          });
                        },
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        activeColor: Color.fromRGBO(251, 201, 85, 1),
                        checkColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.calendar_today, 'Date', item.requestDate,
                    statusColor),
                _buildInfoRow(
                    Icons.person, 'Executive', item.executiveName, statusColor),
                _buildInfoRow(Icons.business, 'Customer',
                    '${item.customerName} (${item.customerCode})', statusColor),
                _buildInfoRow(
                    Icons.category, 'Type', item.customerType, statusColor),
                _buildInfoRow(
                    Icons.location_on,
                    'Address',
                    '${item.address}, ${item.city}, ${item.state}',
                    statusColor),
                _buildStatusChip(
                    item.requestStatus, statusColor, Colors.orange[50]!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
      String status, Color statusColor, Color statusBackground) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[800]!, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.orange[800]!,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: Colors.orange[800]!,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStatusIndicator(CustomerBulkApprovalState bulkApprovalState) {
    if (bulkApprovalState.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: CircularProgressIndicator(color: Colors.blue[800]),
      );
    }
    return const SizedBox(height: 16);
  }

  Widget _buildActionButtons(
      BuildContext context,
      AuthState authState,
      CustomerApprovalListState approvalState,
      CustomerBulkApprovalState bulkApprovalState) {
    final isApprovalListEmpty = approvalState.response == null ||
        approvalState.response!.approvalList.isEmpty;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              'Approve',
              'Optional',
              Colors.green[800]!,
              authState,
              approvalState,
              bulkApprovalState,
              isApprovalListEmpty,
              _isApproveLoading,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              context,
              'Reject',
              "Required",
              Colors.red[800]!,
              authState,
              approvalState,
              bulkApprovalState,
              isApprovalListEmpty,
              _isRejectLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    String remark,
    Color color,
    AuthState authState,
    CustomerApprovalListState approvalState,
    CustomerBulkApprovalState bulkApprovalState,
    bool isApprovalListEmpty,
    bool isLoading,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      onPressed: isApprovalListEmpty ||
              bulkApprovalState.isLoading ||
              isLoading ||
              _isDialogOpen
          ? null
          : () => _showConfirmationDialog(
              context, remark, ref, label, authState, approvalState),
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Please log in to view approval requests',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage, int executiveId) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[800]),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: TextStyle(color: Colors.grey[800], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _refreshList(ref, executiveId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No approval requests found',
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context,
      String remark,
      WidgetRef ref,
      String action,
      AuthState authState,
      CustomerApprovalListState approvalState) {
    final selectedIds = _getSelectedRequestIds(approvalState);
    if (selectedIds.isEmpty) {
      if (!_isDialogOpen) {
        _isDialogOpen = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select at least one request'),
            backgroundColor: Colors.red[800],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _isDialogOpen = false;
          });
        });
      }
      return;
    }

    setState(() {
      _isDialogOpen = true;
    });

    final dialogColor =
        action == 'Approve' ? Colors.green[800]! : Colors.red[800]!;
    bool isDialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    action == 'Approve' ? Icons.check_circle : Icons.cancel,
                    color: dialogColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$action Confirmation',
                    style: TextStyle(
                      color: dialogColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to $action ${selectedIds.length} request(s)?',
                    style: TextStyle(color: Colors.grey[800], fontSize: 16),
                  ),
                  if (action.toLowerCase() == 'reject' ||
                      action == 'Approve') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _remarksController,
                      decoration: InputDecoration(
                        labelText: 'Remarks (${remark})',
                        labelStyle: TextStyle(color: dialogColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: dialogColor.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dialogColor),
                        ),
                        filled: true,
                        fillColor: dialogColor.withOpacity(0.05),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isDialogOpen = false;
                    });
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          if (action.toLowerCase() == 'reject' &&
                              _remarksController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Remarks are required for rejection'),
                                backgroundColor: Colors.red[800],
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            return;
                          }
                          // Perform budget validation for approvals
                          if (action ==
                              'Approve') if (!_validateBudget(approvalState)) {
                            Navigator.pop(context);
                            setState(() {
                              _isDialogOpen = false;
                            });
                            return;
                          }

                          setDialogState(() {
                            isDialogLoading = true;
                          });
                          setState(() {
                            if (action == 'Approve') {
                              _isApproveLoading = true;
                            } else {
                              _isRejectLoading = true;
                            }
                          });
                          await ref
                              .read(customerBulkApprovalProvider.notifier)
                              .submitBulkApproval(
                                requestIds: selectedIds.join(','),
                                approvalFor: action,
                                executiveProfile: AppUtils.getProfileCodeStr(),
                                loggedInExecutiveId: authState.loginResponse!
                                    .executiveBasicData![0].executiveId
                                    .toString(),
                                enteredBy: authState.loginResponse!
                                    .executiveBasicData![0].userId
                                    .toString(),
                                approvalRemarks: _remarksController.text,
                              );
                          setDialogState(() {
                            isDialogLoading = false;
                          });
                          Navigator.pop(context);
                          setState(() {
                            _isDialogOpen = false;
                          });
                          final bulkApprovalState =
                              ref.read(customerBulkApprovalProvider);
                          if (bulkApprovalState.errorMessage != null) {
                            _showToast(bulkApprovalState.errorMessage!,
                                Colors.red[800]!);
                          } else if (bulkApprovalState.successMessage != null) {
                            _showToast(bulkApprovalState.successMessage!,
                                Colors.green[800]!);
                            final executiveId = authState.loginResponse!
                                .executiveBasicData![0].executiveId;
                            await _refreshList(ref, executiveId);
                          }
                          setState(() {
                            _selectedRequests = List.generate(
                              approvalState.response?.approvalList.length ?? 0,
                              (_) => false,
                            );
                            _isSelectAll = false;
                            _isApproveLoading = false;
                            _isRejectLoading = false;
                          });
                          _remarksController.clear();
                        },
                  child: isDialogLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          action,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<String> _getSelectedRequestIds(CustomerApprovalListState approvalState) {
    if (approvalState.response == null) return [];
    return approvalState.response!.approvalList
        .asMap()
        .entries
        .where((entry) => _selectedRequests[entry.key])
        .map((entry) => entry.value.requestId.toString())
        .toList();
  }
}
