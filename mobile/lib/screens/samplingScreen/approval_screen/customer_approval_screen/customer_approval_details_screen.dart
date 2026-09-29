import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/sampling_models/approval/customer_approval_models/customer_approval_details.dart'
    as customer;
import 'package:dart_crm/providers/samplingProvider/approval/Customer_approval_provider/details/customer_approval_action_provider.dart';
import 'package:dart_crm/providers/samplingProvider/approval/Customer_approval_provider/details/customer_approval_details_provider.dart';
import 'package:dart_crm/screens/homeScreen/widget/userHeader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_crm/providers/auth_provider.dart';

class CustomerApprovalDetailsScreen extends ConsumerStatefulWidget {
  final String requestId;
  final String customerId;
  final String customerType;

  const CustomerApprovalDetailsScreen({
    super.key,
    required this.requestId,
    required this.customerId,
    required this.customerType,
  });

  @override
  _CustomerApprovalDetailsScreenState createState() =>
      _CustomerApprovalDetailsScreenState();
}

class _CustomerApprovalDetailsScreenState
    extends ConsumerState<CustomerApprovalDetailsScreen>
    with SingleTickerProviderStateMixin {
  late Map<int, TextEditingController> _approvedQtyControllers;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _approvedQtyControllers = {};
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(customerApprovalDetailsProvider(widget.requestId).notifier)
          .fetchRequestDetails(
            customerId: int.parse(widget.customerId),
            customerType: widget.customerType,
            requestId: int.parse(widget.requestId),
            module: 'Approval',
          );
    });
  }

  @override
  void dispose() {
    _approvedQtyControllers.forEach((_, controller) => controller.dispose());
    _animationController.dispose();
    super.dispose();
  }

  bool _validateBudget(customer.RequestDetail requestDetail) {
    final samplingBudgetCheckApplied =
        AppUtils.filterSetup("SamplingBudgetCheckApplied");
    if (samplingBudgetCheckApplied?.keyValue != "Yes") {
      debugPrint(
          "Budget check skipped: SamplingBudgetCheckApplied is not 'Yes'");
      return true; // Skip budget check
    }

    final customerSamplingApprovalOnlyWithBudget =
        AppUtils.filterSetup("CustomerSamplingApprovalOnlyWithBudget");
    final requestedBudget = requestDetail.requestedBudget;
    final availableBudget = requestDetail.budget;
    bool hasBudget = availableBudget >= requestedBudget == true &&
        availableBudget <= 0 == false;
    debugPrint(
        "Budget check applied: hasBudget=$hasBudget, budget=${availableBudget} & requestedBudget=$requestedBudget");

    if (customerSamplingApprovalOnlyWithBudget?.keyValue == "N") {
      debugPrint(
          "Approval allowed regardless of budget due to CustomerSamplingApprovalOnlyWithBudget='N'");
      return true; // Allow approval even without budget
    }

    if (!hasBudget) {
      debugPrint(
          "Approval blocked: No budget available and CustomerSamplingApprovalOnlyWithBudget is 'Y'");
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Approval failed: No budget available for this request.'),
          // backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
      return false; // Block approval due to no budget
    }

    return true; // Budget check passed
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final detailsState =
        ref.watch(customerApprovalDetailsProvider(widget.requestId));
    final approvalActionState =
        ref.watch(customerApprovalActionProvider(widget.requestId));

    if (authState.token == null || authState.loginResponse == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: const Center(
          child: Text(
            'Please log in to continue',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Userheader(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blueGrey[50]!,
                    Colors.white,
                  ],
                ),
              ),
              child: detailsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color.fromRGBO(55, 71, 79, 1)))
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        child: detailsState.errorMessage != null
                            ? _buildErrorState(
                                context, detailsState.errorMessage!)
                            : detailsState.response == null ||
                                    detailsState
                                        .response!.requestDetails.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No request details found',
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildRequestDetailsCard(
                                          context,
                                          detailsState
                                              .response!.requestDetails[0]),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Title Details',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall!
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromRGBO(
                                                  55, 71, 79, 1),
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (detailsState
                                          .response!.titleDetails.isEmpty)
                                        const Text(
                                          'No titles found',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                              fontStyle: FontStyle.italic),
                                        )
                                      else
                                        _buildTitleDetailsList(
                                          context,
                                          ref,
                                          detailsState.response!.titleDetails,
                                          widget.requestId,
                                          detailsState
                                              .response!.requestDetails[0],
                                        ),
                                      const SizedBox(height: 32),
                                      _buildActionButtons(
                                        context,
                                        ref,
                                        widget.requestId,
                                        approvalActionState,
                                        authState,
                                        detailsState
                                            .response!.requestDetails[0],
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Customer Approval Details',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
      foregroundColor: const Color.fromRGBO(55, 71, 79, 1),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromRGBO(252, 242, 219, 1),
              const Color.fromRGBO(252, 242, 219, 0.85),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref
                .read(
                    customerApprovalDetailsProvider(widget.requestId).notifier)
                .fetchRequestDetails(
                  customerId: int.parse(widget.customerId),
                  customerType: widget.customerType,
                  requestId: int.parse(widget.requestId),
                  module: 'Approval',
                );
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(55, 71, 79, 1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              ref
                  .read(customerApprovalDetailsProvider(widget.requestId)
                      .notifier)
                  .fetchRequestDetails(
                    customerId: int.parse(widget.customerId),
                    customerType: widget.customerType,
                    requestId: int.parse(widget.requestId),
                    module: 'Approval',
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetailsCard(
      BuildContext context, customer.RequestDetail requestDetail) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(requestDetail.requestStatus),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      requestDetail.requestStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 24, left: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Request #${requestDetail.requestNumber}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color.fromRGBO(55, 71, 79, 1),
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Date', requestDetail.requestDate),
                  _buildDetailRow('Executive', requestDetail.executiveName),
                  _buildDetailRow('Customer', '${requestDetail.customerName}'),
                  _buildDetailRow(
                      'Shipping Address', requestDetail.shippingAddress),
                  _buildDetailRow('Area', requestDetail.areaName),
                  _buildDetailRow('Warehouse', requestDetail.wareHouseName),
                  if (requestDetail.requestRemarks != null &&
                      requestDetail.requestRemarks!.isNotEmpty)
                    _buildDetailRow('Remarks', requestDetail.requestRemarks!),
                  if (requestDetail.shippingInstructions != null &&
                      requestDetail.shippingInstructions!.isNotEmpty)
                    _buildDetailRow('Shipping Instructions',
                        requestDetail.shippingInstructions!),
                  if (requestDetail.shipmentMode != null &&
                      requestDetail.shipmentMode!.isNotEmpty)
                    _buildDetailRow(
                        'Shipment Mode', requestDetail.shipmentMode!),
                  if (requestDetail.shipmentStatus != null &&
                      requestDetail.shipmentStatus!.isNotEmpty)
                    _buildDetailRow(
                        'Shipment Status', requestDetail.shipmentStatus!),
                  _buildDetailRow('Requested Budget',
                      '${requestDetail.requestedBudget.toStringAsFixed(2)}'),
                  _buildDetailRow('Budget(units)',
                      '${requestDetail.budget.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleDetailsList(
      BuildContext context,
      WidgetRef ref,
      List<customer.TitleDetail> titleDetails,
      String requestId,
      customer.RequestDetail requestDetail) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final title in titleDetails) {
        if (!_approvedQtyControllers.containsKey(title.bookId)) {
          final initialQty = title.previousApprovedQty != null
              ? title.previousApprovedQty!
              : title.requestedQty;
          _approvedQtyControllers[title.bookId] =
              TextEditingController(text: initialQty.toString());
          ref
              .read(customerApprovalActionProvider(requestId).notifier)
              .updateApprovedQty(
                bookId: title.bookId,
                approvedQty: initialQty,
              );
        }
      }
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: titleDetails.length,
      itemBuilder: (context, index) {
        final title = titleDetails[index];
        if (!_approvedQtyControllers.containsKey(title.bookId)) {
          final initialQty = title.previousApprovedQty != null
              ? title.previousApprovedQty!
              : title.requestedQty;
          _approvedQtyControllers[title.bookId] =
              TextEditingController(text: initialQty.toString());
        }
        final controller = _approvedQtyControllers[title.bookId]!;
        final maxQty = title.previousApprovedQty != null
            ? title.previousApprovedQty!
            : title.requestedQty;

        return Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey[50],
                child: Icon(Icons.book,
                    color: const Color.fromRGBO(55, 71, 79, 1), size: 20),
              ),
              title: Text(
                title.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87),
              ),
              subtitle: Text(
                'ISBN: ${title.isbn}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Author', title.author),
                      _buildDetailRow('Series', title.series),
                      _buildDetailRow(
                          'Requested Qty', title.requestedQty.toString()),
                      if (title.previousApprovedQty?.toString() != null)
                        _buildDetailRow('Previous Approved Qty',
                            title.previousApprovedQty?.toString() ?? 'N/A'),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 140,
                              child: Text(
                                'Approved Qty:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color.fromRGBO(55, 71, 79, 1),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.36,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Colors.blueGrey),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color:
                                            Colors.blueGrey.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color.fromRGBO(55, 71, 79, 1)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  fillColor: Colors.white,
                                  filled: true,
                                  hintText: 'Qty',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  errorText: controller.text.isEmpty
                                      ? 'Cannot be empty'
                                      : int.tryParse(controller.text) != null &&
                                              int.parse(controller.text) >
                                                  maxQty
                                          ? 'Max: $maxQty'
                                          : null,
                                ),
                                style: const TextStyle(fontSize: 14),
                                onChanged: (value) {
                                  if (value.isEmpty) {
                                    ref
                                        .read(customerApprovalActionProvider(
                                                requestId)
                                            .notifier)
                                        .updateApprovedQty(
                                          bookId: title.bookId,
                                          approvedQty: 0,
                                        );
                                  } else {
                                    final approvedQty =
                                        int.tryParse(value) ?? 0;
                                    if (approvedQty > maxQty) {
                                      controller.text = maxQty.toString();
                                      controller.selection =
                                          TextSelection.fromPosition(
                                              TextPosition(
                                                  offset:
                                                      controller.text.length));
                                      ref
                                          .read(customerApprovalActionProvider(
                                                  requestId)
                                              .notifier)
                                          .updateApprovedQty(
                                            bookId: title.bookId,
                                            approvedQty: maxQty,
                                          );
                                    } else {
                                      ref
                                          .read(customerApprovalActionProvider(
                                                  requestId)
                                              .notifier)
                                          .updateApprovedQty(
                                            bookId: title.bookId,
                                            approvedQty: approvedQty,
                                          );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildDetailRow(
                          'Shipped Qty', title.shippedQty.toString()),
                      _buildDetailRow('Requested Budget',
                          '${title.requestedBudget.toStringAsFixed(2)}'),
                      _buildDetailRow(
                          'MRP', '₹${title.bookMRP.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    CustomerApprovalActionState approvalActionState,
    AuthState authState,
    customer.RequestDetail requestDetail,
  ) {
    // Watch for changes in approvalActionState to detect success or error
    ref.listen<CustomerApprovalActionState>(
      customerApprovalActionProvider(requestId),
      (previous, next) {
        if (next.successMessage != null) {
          // Log success for debugging
          debugPrint('Approval Success: ${next.successMessage}');
          // Show SnackBar with success message
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                next.successMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          // Invalidate details provider to refresh status
          ref.invalidate(customerApprovalDetailsProvider(requestId));
          // Add a small delay to allow backend to update
          Future.delayed(const Duration(seconds: 1), () {
            if (context.mounted) {
              Navigator.pop(context, true); // Return true to signal refresh
            }
          });
        } else if (next.errorMessage != null) {
          // Log error for debugging
          debugPrint('Approval Error: ${next.errorMessage}');
          // Show SnackBar with error message
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                next.errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
    );

    // Validation for approval: Check if at least one TextField has approvedQty >= 1
    bool isValidForApproval() {
      bool hasValidQty = false;
      for (var controller in _approvedQtyControllers.values) {
        if (controller.text.isEmpty) {
          return false; // Empty field detected
        }
        final qty = int.tryParse(controller.text) ?? 0;
        if (qty >= 1) {
          hasValidQty = true;
        }
      }
      return hasValidQty;
    }

    return Column(
      children: [
        if (approvalActionState.isLoading)
          const CircularProgressIndicator(color: Color.fromRGBO(55, 71, 79, 1))
        else if (approvalActionState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              approvalActionState.errorMessage!,
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          )
        else if (approvalActionState.successMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              approvalActionState.successMessage!,
              style: const TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AnimatedScale(
              scale: approvalActionState.isLoading ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                  shadowColor: Colors.green.withOpacity(0.3),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: approvalActionState.isLoading
                    ? null
                    : () async {
                        if (!isValidForApproval()) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Please ensure at least one title has an approved quantity of 1 or greater, and no quantity fields are empty.'),
                              // backgroundColor: Colors.red[700],
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.all(16),
                              duration: Duration(seconds: 3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          return;
                        }
                        // Perform budget validation before showing dialog
                        if (!_validateBudget(requestDetail)) {
                          return;
                        }
                        final remarksController = TextEditingController();
                        final approved = await showDialog<bool>(
                          context: context,
                          builder: (context) => _buildApprovalDialog(
                            title: 'Approve Request',
                            message:
                                'Are you sure you want to approve this request?',
                            confirmText: 'Approve',
                            remarksController: remarksController,
                            isReject: false,
                          ),
                        );
                        if (approved == true) {
                          final titleDetails = ref
                              .read(customerApprovalDetailsProvider(requestId))
                              .response!
                              .titleDetails;
                          final xmlItems = titleDetails.map((title) {
                            final approvedQty = int.tryParse(
                                    _approvedQtyControllers[title.bookId]
                                            ?.text ??
                                        '0') ??
                                title.approvedQty;
                            return '<ApprovedBooksAndQty><RequestId>$requestId</RequestId><BookId>${title.bookId}</BookId><ApprovedQty>$approvedQty</ApprovedQty><RequestedQty>${title.requestedQty}</RequestedQty></ApprovedBooksAndQty>';
                          }).join();
                          final approvedBooksAndQtyXML =
                              '<DocumentElement>$xmlItems</DocumentElement>';

                          // Log XML for debugging
                          debugPrint(
                              'Submitting Approval XML: $approvedBooksAndQtyXML');

                          await ref
                              .read(customerApprovalActionProvider(requestId)
                                  .notifier)
                              .submitApproval(
                                requestId: requestId,
                                approvalFor: 'Approve',
                                executiveProfile: AppUtils.getProfileCodeStr(),
                                loggedInExecutiveId: authState.loginResponse!
                                    .executiveBasicData![0].executiveId
                                    .toString(),
                                enteredBy: authState.loginResponse!
                                    .executiveBasicData![0].executiveId
                                    .toString(),
                                approvalRemarks: remarksController.text,
                                approvedBooksAndQtyXML: approvedBooksAndQtyXML,
                                customerType: widget.customerType,
                                customerId: int.parse(widget.customerId),
                              );
                        }
                      },
                child: const Text('Approve'),
              ),
            ),
            AnimatedScale(
              scale: approvalActionState.isLoading ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                  shadowColor: Colors.red.withOpacity(0.3),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: approvalActionState.isLoading
                    ? null
                    : () async {
                        final remarksController = TextEditingController();
                        final rejected = await showDialog<bool>(
                          context: context,
                          builder: (context) => _buildApprovalDialog(
                            title: 'Reject Request',
                            message:
                                'Are you sure you want to reject this request?',
                            confirmText: 'Reject',
                            remarksController: remarksController,
                            isReject: true,
                          ),
                        );
                        if (rejected == true) {
                          await ref
                              .read(customerApprovalActionProvider(requestId)
                                  .notifier)
                              .submitApproval(
                                requestId: requestId,
                                approvalFor: 'Reject',
                                executiveProfile: AppUtils.getProfileCodeStr(),
                                loggedInExecutiveId: authState.loginResponse!
                                    .executiveBasicData![0].executiveId
                                    .toString(),
                                enteredBy: authState.loginResponse!
                                    .executiveBasicData![0].executiveId
                                    .toString(),
                                approvalRemarks: remarksController.text,
                                approvedBooksAndQtyXML: '',
                                customerType: widget.customerType,
                                customerId: int.parse(widget.customerId),
                              );
                        }
                      },
                child: const Text('Reject'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApprovalDialog({
    required String title,
    required String message,
    required String confirmText,
    required TextEditingController remarksController,
    required bool isReject,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isReject ? Icons.cancel : Icons.check_circle,
                  color: isReject ? Colors.red[700] : Colors.green[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(55, 71, 79, 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText:
                    isReject ? 'Remarks (Required)' : 'Remarks (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.blueGrey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.blueGrey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color.fromRGBO(55, 71, 79, 1)),
                ),
                filled: true,
                fillColor: Colors.blueGrey[50],
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (isReject && remarksController.text.isEmpty) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Remarks are required for rejection')),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isReject ? Colors.red[700] : Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: Text(confirmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color.fromRGBO(55, 71, 79, 1),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: statusColor ?? Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green[700]!;
      case 'pending':
      case 'pending for level 2':
      case 'pending for level 3':
        return Colors.orange[700]!;
      case 'rejected':
        return Colors.red[700]!;
      default:
        return Colors.black87;
    }
  }
}
