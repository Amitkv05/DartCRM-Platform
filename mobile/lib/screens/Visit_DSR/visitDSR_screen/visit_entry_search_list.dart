import 'package:dart_crm/models/planList/plan.dart';
import 'package:dart_crm/screens/Visit_DSR/DSR_entry/dsr_entry.dart';
import 'package:dart_crm/screens/Visit_DSR/visitDSR_screen/todays_Plan/visit_details_screen.dart';
import 'package:dart_crm/screens/Visit_DSR/visitDSR_screen/visit_entry_search_screen.dart';
import 'package:dart_crm/screens/homeScreen/widget/userHeader.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../edit/utils/AppUtils.dart';

class VisitEntryResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> searchParams;
  final String? customerType;

  const VisitEntryResultScreen({
    required this.searchParams,
    super.key,
    required this.customerType,
  });

  @override
  ConsumerState<VisitEntryResultScreen> createState() =>
      _VisitEntryResultScreenState();
}

class _VisitEntryResultScreenState
    extends ConsumerState<VisitEntryResultScreen> {
  int _currentPage = 1;
  final int _itemsPerPage = 100;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _changePage(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    // Scroll to the top of the list
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerResultAsyncValue =
        ref.watch(customerResultProvider(widget.searchParams));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.customerType == null
              ? 'Customer Visit - List'
              : '${widget.customerType} Visit - List',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: TColors.primary,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const Userheader(),
          Expanded(
            child: customerResultAsyncValue.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search parameters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate pagination details
                final totalItems = customers.length;
                final totalPages = (totalItems / _itemsPerPage).ceil();
                final startIndex = (_currentPage - 1) * _itemsPerPage;
                final endIndex = startIndex + _itemsPerPage < totalItems
                    ? startIndex + _itemsPerPage
                    : totalItems;
                final paginatedCustomers =
                    customers.sublist(startIndex, endIndex);

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paginatedCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = paginatedCustomers[index];
                        final customerId = customer['CustomerId']?.toString();
                        if (customerId == null || customerId.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(10.0),
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.shade600,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer['CustomerName'] ??
                                        'Unknown Customer',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    customer['Address']
                                            ?.replaceAll('\\r\\n', ', ') ??
                                        'No address available',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Invalid Customer ID',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final plan = Plan(
                          emailId: customer['EmailId']?.toString() ?? '',
                          state: customer['State']?.toString() ?? '',
                          contact: customer['Contact']?.toString() ?? '',
                          address: customer['Address']?.toString() ?? '',
                          refCode: customer['RefCode']?.toString() ?? '',
                          customerCode:
                              customer['CustomerCode']?.toString() ?? '',
                          phone: customer['Phone']?.toString() ?? '',
                          city: customer['City']?.toString() ?? '',
                          visitPurpose:
                              customer['VisitPurpose']?.toString() ?? '',
                          customerId: customer['CustomerId'] ?? 0,
                          customerName: customer['CustomerName']?.toString() ??
                              'Unknown Customer',
                          customerType:
                              customer['CustomerType']?.toString() ?? 'School',
                        );

                        return Container(
                          padding: const EdgeInsets.all(10.0),
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.shade600,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              FROM_TODSR = 2;
                              print('XXXXX LIST VISIT');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VisitDetailsScreen(plan: plan),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer['CustomerName'] ??
                                            'Unknown Customer',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      SizedBox(
                                        width: 250,
                                        child: Text(
                                          customer['Address']?.replaceAll(
                                                  '\\r\\n', ', ') ??
                                              'No address available',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                  ),
                                ),
                                Material(
                                  color: Colors.grey.shade200,
                                  child: InkWell(
                                    onTap: () {
                                      FROM_TODSR = 1;
                                      print('XXXXX VISIT');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DSREntryScreen(plan: plan),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Column(
                                        children: [
                                          Icon(Icons.directions_bike,
                                              color: TColors.buttonPrimary,
                                              size: 30),
                                          Text(
                                            "DSR Entry",
                                            style: TextStyle(
                                              color: TColors.buttonPrimary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Pagination Controls
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: _currentPage > 1
                                ? () => _changePage(_currentPage - 1)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColors.primary,
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Previous'),
                          ),
                          Text(
                            'Page $_currentPage of $totalPages',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          ElevatedButton(
                            onPressed: _currentPage < totalPages
                                ? () => _changePage(_currentPage + 1)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColors.primary,
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error: $error',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
