import 'dart:async';

import 'package:dart_crm/edit/library/library_edit_page.dart';
import 'package:dart_crm/edit/model/teacher/ContactModel.dart';
import 'package:dart_crm/edit/student/student_edit_page.dart';
import 'package:dart_crm/edit/trade/trade_edit_page.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/customer/customer_master_list_model.dart';
import 'package:dart_crm/screens/customer/details/school_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../screens/customer/details/library_details_screen.dart';
import '../screens/customer/details/trade_detail_screen.dart' hide TColors;
import 'api/repository/api_service.dart';

class SchoolMasterList extends ConsumerStatefulWidget {
  final String customerType;

  const SchoolMasterList({super.key, required this.customerType});

  @override
  ConsumerState<SchoolMasterList> createState() => _SchoolMasterListState();
}

class _SchoolMasterListState extends ConsumerState<SchoolMasterList> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<CustomerMasterListItem>? customerList = [];
  final StreamController<List<CustomerMasterListItem>?> _listStream =
      BehaviorSubject();
  ContactModel? teacher;
  final TextEditingController remarksController = TextEditingController();
  String customerType = '';
  String noDataAPI = '';
  String noDataStr = '';
  int currentPage = 1;
  final int pageSize = 100;
  int totalPages = 1;
  bool showPagination = false;

  @override
  void initState() {
    customerType = widget.customerType;
    noDataAPI = 'No $customerType is available. Please try again';
    super.initState();
    getSchoolList(currentPage);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listStream.close();
    remarksController.dispose();
    super.dispose();
  }

  void _changePage(int newPage) {
    setState(() {
      currentPage = newPage;
      _searchController.clear();
    });
    getSchoolList(currentPage); // Fetch data for the new page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: showPagination ? _buildPaginationControls() : null,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "$customerType Master List",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        elevation: 2,
        centerTitle: true,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          launchEditAndCreate();
        },
        backgroundColor: Colors.blueAccent,
        elevation: 6,
        tooltip: 'Add New $customerType',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: () async {
          getSchoolList(currentPage);
        },
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search $customerType by name or code...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    var filteredList = customerList
                        ?.where((i) =>
                            i.customerName
                                .toLowerCase()
                                .contains(value.toLowerCase()) ||
                            i.customerCode
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                        .toList();
                    noDataStr = "No $customerType is available.";
                    setState(() {
                      // Keep pagination hidden if customer count <= pageSize, even when filtering
                      showPagination = totalPages > 1 &&
                          filteredList != null &&
                          filteredList.isNotEmpty;
                    });
                    _listStream.sink.add(filteredList);
                  },
                ),
              ),
              StreamBuilder<List<CustomerMasterListItem>?>(
                  stream: _listStream.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var list = snapshot.data;

                      if (list == null || list.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                noDataStr,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 75),
                        child: _widgetListWidget(list),
                      );
                    } else {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.blueAccent,
                        ),
                      );
                    }
                  })
            ],
          ),
        ),
      ),
    );
  }

  Widget _widgetListWidget(List<CustomerMasterListItem> customerList) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListView(
        controller: _scrollController,
        children: [
          Container(
            color: Colors.white,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 10),
              itemCount: customerList.length,
              itemBuilder: (context, index) {
                var customer = customerList[index];
                return _buildCustomerCard(customer, context, customerType);
              },
            ),
          ),
          SizedBox(height: 60)
        ],
      ),
    );
  }

  Widget _buildCustomerCard(CustomerMasterListItem customer,
      BuildContext context, String customerType) {
    final validationStatus = customer.validationStatus;
    final apiService = ApiService();
    return GestureDetector(
      onTap: () {
        launchDetail(customer: customer);
      },
      child: Container(
        padding: const EdgeInsets.all(10.0),
        margin: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade600,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  child: Text(
                    '${customer.customerName} (${customer.customerCode.split(',')[0]})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                _buildSubtitleText('', customer.address),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSubtitleText('Validation: ', validationStatus),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                            onTap: () {
                              launchEditAndCreate(customer: customer);
                            },
                            child: Icon(Icons.edit,
                                color: Colors.black, size: 25)),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 25),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text(
                                  'Delete Customer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Are you sure you want to delete ${customer.customerName}?',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                        )),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: remarksController,
                                      decoration: InputDecoration(
                                        labelText: 'Remarks (Optional)',
                                        labelStyle:
                                            TextStyle(color: Colors.red[800]!),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.red[800]!
                                                  .withOpacity(0.3)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.red[800]!),
                                        ),
                                        filled: true,
                                        fillColor:
                                            Colors.red[800]!.withOpacity(0.05),
                                      ),
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16)),
                                  ),
                                  TextButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[800],
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    onPressed: () async {
                                      apiService.deleteCustomer(
                                        context: context,
                                        customerId: customer.customerId,
                                        customerContactId:
                                            AppUtils.onlyInt(teacher?.edit),
                                        validated:
                                            AppUtils.onlyChar(customer?.action),
                                        enteredBy: AppUtils.getUserId(),
                                        customerType: customerType,
                                        remarks: remarksController.text,
                                      );
                                      Navigator.pop(context);
                                      remarksController.clear();
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed:
                  currentPage > 1 ? () => _changePage(currentPage - 1) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Previous'),
            ),
            Text(
              'Page $currentPage of $totalPages',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            ElevatedButton(
              onPressed: currentPage < totalPages
                  ? () => _changePage(currentPage + 1)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }

  void getSchoolList(int page) {
    ApiService service = ApiService();

    // Fetch customer list and total count sequentially
    service
        .fetchCustomers(customerType: customerType, currentPage: page)
        .then((data) async {
      noDataStr = noDataAPI;
      customerList = data?.customerList;

      int? customerCount = data?.customerCount;
      setState(() {
        if (customerCount != null && customerCount > 0) {
          totalPages = (customerCount / pageSize).ceil();
          // Only show pagination if customer count is greater than pageSize
          showPagination = customerCount > pageSize;
        } else {
          totalPages = 1;
          showPagination = false;
        }
      });

      if (customerList == null || customerList!.isEmpty) {
        setState(() {
          showPagination = false; // Hide pagination if no data
        });
      }

      _listStream.sink.add(customerList);

      // Scroll to the top after the list is updated
      if (_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(0);
        });
      }

      setState(() {});
    }).catchError((error) {
      // Handle any errors from fetchCustomers or fetchTotalCustomerCount
      noDataStr = noDataAPI;
      _listStream.sink.add(null);
      setState(() {
        showPagination = false;
      });
    });
  }

  void launchDetail({CustomerMasterListItem? customer}) {
    switch (customerType) {
      case 'School':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailsScreen(
              customer: customer,
              customerType: customerType,
            ),
          ),
        );
        break;

      case 'Trade':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TradeDetailsScreen(
              customer: customer,
              customerType: customerType,
            ),
          ),
        );
        break;

      case 'Library':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LibraryDetailsScreen(
              customer: customer,
              customerType: customerType,
            ),
          ),
        );
        break;
    }
  }

  void launchEditAndCreate({CustomerMasterListItem? customer}) {
    switch (customerType) {
      case 'School':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentEditPage(
              customer: customer,
              customerType: customerType,
            ),
          ),
        ).then((_) {
          getSchoolList(currentPage);
        });
        break;

      case 'Trade':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TradeEditPage(
              customer: customer,
              customerType: customerType,
            ),
          ),
        ).then((_) {
          getSchoolList(currentPage);
        });
        break;

      case 'Library':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LibraryEditPage(
              customer: customer,
              customerType: customerType,
            ),
          ),
        ).then((_) {
          getSchoolList(currentPage);
        });
        break;
    }
  }
}
