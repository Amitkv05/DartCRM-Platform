import 'dart:async';
import 'package:dart_crm/edit/api/repository/api_repository.dart';
import 'package:dart_crm/edit/api/repository/api_result.dart';
import 'package:dart_crm/edit/api/repository/api_service.dart';
import 'package:dart_crm/edit/model/school/SchoolListResponse.dart';
import 'package:dart_crm/edit/model/teacher/ContactModel.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/customer/customer_master_list_model.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/geography_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_crm/core/api/legacy_http.dart' as http;
import 'dart:convert';
import 'package:rxdart/rxdart.dart';

class TColors {
  static const primary = Color.fromRGBO(252, 242, 219, 1);
}

class CustomerCategory {
  final String categoryName;
  final String categoryId;

  CustomerCategory({required this.categoryName, required this.categoryId});

  factory CustomerCategory.fromJson(Map<String, dynamic> json) {
    return CustomerCategory(
      categoryName: json['CustomerCategoryName']?.toString() ?? '',
      categoryId: json['CustomerCategoryId']?.toString() ?? '',
    );
  }
}

class AccountTableExecutive {
  final String executiveName;
  final String sno;

  AccountTableExecutive({required this.executiveName, required this.sno});

  factory AccountTableExecutive.fromJson(Map<String, dynamic> json) {
    return AccountTableExecutive(
      executiveName: json['ExecutiveName']?.toString() ?? '',
      sno: json['SNo']?.toString() ?? '',
    );
  }
}

class BoardResponse {
  final List<CustomerCategory> customerCategories;
  final List<AccountTableExecutive> accountExecutives;

  BoardResponse({
    required this.customerCategories,
    required this.accountExecutives,
  });

  factory BoardResponse.fromJson(Map<String, dynamic> json) {
    print('BoardResponse.fromJson raw data: $json');
    var categoryList = json['CustomerCategory'] as List<dynamic>? ?? [];
    var executiveList = json['AccountableExecutive'] as List<dynamic>? ?? [];
    return BoardResponse(
      customerCategories:
          categoryList.map((item) => CustomerCategory.fromJson(item)).toList(),
      accountExecutives: executiveList
          .map((item) => AccountTableExecutive.fromJson(item))
          .toList(),
    );
  }
}

class TradeDetailsScreen extends ConsumerStatefulWidget {
  final CustomerMasterListItem? customer;
  final String customerType;

  const TradeDetailsScreen({
    super.key,
    required this.customer,
    required this.customerType,
  });

  @override
  ConsumerState<TradeDetailsScreen> createState() => _TradeDetailsScreenState();
}

class _TradeDetailsScreenState extends ConsumerState<TradeDetailsScreen> {
  Map<String, dynamic>? customerDetails;
  bool isLoading = true;
  String? errorMessage;
  List<dynamic>? bookSellerList;
  String? error;
  String? cityName;
  String? districtName;
  String? stateName;
  String? countryName;
  String? startClassName;
  String? endClassName;
  String? boardName;
  SchoolListResponse? apiData;
  String? title = '';
  int? customerId;
  List<CustomerCategory> customerCategories = [];
  List<AccountTableExecutive> accountExecutives = [];
  String? selectedCategoryName;
  String? selectedExecutiveName;

  final StreamController<List<ContactModel>?> _loadDataStream =
      BehaviorSubject();

  @override
  void initState() {
    super.initState();
    _loadData();

    // Teacher List
    WidgetsBinding.instance
        .addPostFrameCallback((_) => onPostFrameCallback(context));
  }

  Future<void> _loadData() async {
    await getBoardData(); // Load categories and executives
    await fetchCustomerDetails(); // Then fetch customer detailsa
  }

  Future<void> getBoardData() async {
    try {
      // DownHierarchy is not required, so use empty payload
      Map<String, dynamic> map = {};

      print('API request payload: $map');

      ApiResult result = await ApiRepository().postRequest(
        '$BASE_URL/CustomerEntryMasterAPI',
        data: map,
      );

      print('getBoardData isSuccess: ${result.isSuccess}');
      print('getBoardData response: ${result.response?.data}');

      if (result.isSuccess) {
        final responseData = result.response?.data;
        final boardResponse = BoardResponse.fromJson(responseData ?? {});
        setState(() {
          customerCategories = boardResponse.customerCategories;
          accountExecutives = boardResponse.accountExecutives;
          print('Parsed customerCategories: $customerCategories');
          print('Parsed accountExecutives: $accountExecutives');
        });
      } else {
        var error =
            result.response?.data['Message']?.toString() ?? 'Unknown error';
        print('API error: $error');
        AppUtils.showToast(error);
      }
    } catch (e) {
      print('getBoardData exception: $e');
      AppUtils.showToast('Failed to fetch data: $e');
    }
  }

  Future<void> fetchCustomerDetails() async {
    final authState = ref.read(authProvider);
    final token = authState.token;
    try {
      final validatedStatus = widget.customer?.validationStatus == 'Yes'
          ? 'A'
          : widget.customer?.validationStatus;

      final response = await http.post(
        Uri.parse('$BASE_URL/FetchCustomerDetails'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'CustomerId': widget.customer?.customerId,
          'CustomerType': widget.customerType,
          'Validated': validatedStatus,
        }),
      );

      print('Request sent: ${{
        'CustomerId': widget.customer?.customerId,
        'CustomerType': widget.customerType,
        'Validated': validatedStatus,
      }}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response received: $responseData');

        if (responseData['Status'] == 'Success') {
          if (responseData['CustomerDetails'] is List &&
              responseData['CustomerDetails'].isNotEmpty) {
            setState(() {
              customerDetails = responseData['CustomerDetails'][0];
              bookSellerList = responseData['List'];
              // Map xmlCustomerCategoryId
              final categoryIdString =
                  customerDetails?['xmlCustomerCategoryId']?.toString();
              if (categoryIdString != null && customerCategories.isNotEmpty) {
                final categoryIds = categoryIdString.split(',');
                final categoryNames = categoryIds
                    .map((id) => customerCategories
                        .firstWhere(
                          (category) => category.categoryId == id.trim(),
                          orElse: () => CustomerCategory(
                              categoryName: 'Unknown', categoryId: id),
                        )
                        .categoryName)
                    .where((name) => name != 'Unknown')
                    .toList();
                selectedCategoryName = categoryNames.isNotEmpty
                    ? categoryNames.join(', ')
                    : 'No category assigned';
                print(
                    'Mapped xmlCustomerCategoryId: $categoryIdString to $selectedCategoryName');
              } else {
                selectedCategoryName = 'No category assigned';
                print('No categoryId or empty customerCategories');
              }

              // Map xmlAccountTableExecutiveId
              final executiveIdString =
                  customerDetails?['xmlAccountTableExecutiveId']?.toString();
              if (executiveIdString != null && accountExecutives.isNotEmpty) {
                final executiveIds = executiveIdString.split(',');
                final executiveNames = executiveIds
                    .map((id) => accountExecutives
                        .firstWhere(
                          (executive) => executive.sno == id.trim(),
                          orElse: () => AccountTableExecutive(
                              executiveName: 'Unknown', sno: id),
                        )
                        .executiveName)
                    .where((name) => name != 'Unknown')
                    .toList();
                selectedExecutiveName = executiveNames.isNotEmpty
                    ? executiveNames.join(', ')
                    : 'No executive assigned';
                print(
                    'Mapped xmlAccountTableExecutiveId: $executiveIdString to $selectedExecutiveName');
              } else {
                selectedExecutiveName = 'No executive assigned';
                print('No executiveId or empty accountExecutives');
              }

              isLoading = false;
            });
          } else {
            setState(() {
              errorMessage =
                  'No customer details found for ID ${widget.customer?.customerId}';
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = 'API returned failure: ${responseData['Status']}';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to load customer details: HTTP ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching customer details: $e';
        isLoading = false;
      });
    }
  }

  void _mapGeographyData(GeographyState geographyState) {
    if (geographyState.isLoading) {
      print('Geography data is still loading');
      return;
    }

    if (geographyState.error != null) {
      setState(() {
        error = 'Geography fetch failed: ${geographyState.error}';
      });
      print('Geography error: ${geographyState.error}');
      return;
    }

    final geographyList = geographyState.geography;
    if (geographyList.isEmpty) {
      setState(() {
        error = 'No geography data available';
      });
      print('Geography error: No geography data available');
      return;
    }

    if (customerDetails == null) {
      setState(() {
        error = 'Customer details not available for geography mapping';
      });
      print('Geography error: Customer details not available');
      return;
    }

    final cityId = (customerDetails!['CityId'] as num?)?.toInt();
    final stateId = (customerDetails!['StateId'] as num?)?.toInt();
    final countryId = (customerDetails!['CountryId'] as num?)?.toInt();
    final districtId = (customerDetails!['DistrictId'] as num?)?.toInt();

    print(
        'Mapping geography IDs: CityId=$cityId, StateId=$stateId, CountryId=$countryId, DistrictId=$districtId');

    setState(() {
      cityName = cityId != null
          ? geographyList
              .firstWhere(
                (item) => item.cityId == cityId,
                orElse: () => GeographyItem(
                  countryId: 0,
                  country: '',
                  stateId: 0,
                  stateName: '',
                  districtId: 0,
                  district: '',
                  cityId: 0,
                  city: 'Unknown City',
                ),
              )
              .city
          : '';
      stateName = stateId != null
          ? geographyList
              .firstWhere(
                (item) => item.stateId == stateId,
                orElse: () => GeographyItem(
                  countryId: 0,
                  country: '',
                  stateId: 0,
                  stateName: 'Unknown State',
                  districtId: 0,
                  district: '',
                  cityId: 0,
                  city: '',
                ),
              )
              .stateName
          : '';
      countryName = countryId != null
          ? geographyList
              .firstWhere(
                (item) => item.countryId == countryId,
                orElse: () => GeographyItem(
                  countryId: 0,
                  country: 'Unknown Country',
                  stateId: 0,
                  stateName: '',
                  districtId: 0,
                  district: '',
                  cityId: 0,
                  city: '',
                ),
              )
              .country
          : '';
      districtName = districtId != null
          ? geographyList
              .firstWhere(
                (item) => item.districtId == districtId,
                orElse: () => GeographyItem(
                  countryId: 0,
                  country: '',
                  stateId: 0,
                  stateName: '',
                  districtId: 0,
                  district: 'Unknown District',
                  cityId: 0,
                  city: '',
                ),
              )
              .district
          : '';

      print(
          'Mapped geography: cityName=$cityName, stateName=$stateName, countryName=$countryName, districtName=$districtName');
    });
  }

  void onPostFrameCallback(BuildContext context) {
    customerId = widget.customer!.customerId;
    ApiService service = ApiService();
    if (customerId != null && customerId != 0) {
      service
          .getContactList(widget.customer!.customerId, widget.customerType,
              widget.customer!.action)
          .then((data) {
        var contactList = data?.contactList ?? [];
        _loadDataStream.sink.add(contactList);
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final geographyState = ref.watch(geographyProvider);

    // Call _mapGeographyData whenever geographyState changes and customerDetails is available
    if (!geographyState.isLoading && customerDetails != null) {
      _mapGeographyData(geographyState);
    }
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading Customer Details...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (customerDetails == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: Center(
          child: Text(
            'No details available for this customer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerCard(context),
              Transform.translate(
                  offset: const Offset(0, -5),
                  child: _buildPrincipalCard(context)),
              Transform.translate(
                  offset: const Offset(0, -10),
                  child: _buildContactCard(context)),
              Transform.translate(
                  offset: const Offset(0, -15),
                  child: _buildTradeDetailsCard(context)),
              // if (bookSellerList != null && bookSellerList!.isNotEmpty) ...[
              //   const SizedBox(height: 16),
              //   _buildBooksellersCard(context),
              // ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        '${widget.customerType} Customer Details',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: TColors.primary,
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableSection(
          'Primary Address',
          [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.orange),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.87,
                      child: Text(
                        customerDetails!['CustomerName'] +
                            ' (' +
                            customerDetails!['CustomerCode'] +
                            ')',
                        // overflow: TextOverflow.ellipsis,
                        // maxLines: 2,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    _buildDetail(customerDetails!['Address'] ?? ''),
                    Row(
                      children: [
                        _buildDetail(stateName ?? ''),
                        Text(', '),
                        _buildDetail(customerDetails!['Pincode'] ?? ''),
                      ],
                    ),
                    Row(
                      children: [
                        _buildDetail(cityName ?? ''),
                        Text(', '),
                        _buildDetail(countryName ?? ''),
                      ],
                    ),
                    if (districtName != null &&
                        districtName != '' &&
                        districtName != 'Unknown District')
                      _buildDetail(districtName!),
                    if (customerDetails!['EmailId'] != null &&
                        customerDetails!['EmailId'] != '')
                      _buildInteractiveDetailRow(
                        'Email',
                        customerDetails!['EmailId'],
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text: customerDetails!['EmailId'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Email copied to clipboard')),
                          );
                        },
                      ),
                    if (customerDetails!['Mobile'] != null &&
                        customerDetails!['Mobile'] != '')
                      _buildInteractiveDetailRow(
                        'Phone',
                        customerDetails!['Mobile'] ?? '',
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text: customerDetails!['Mobile'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Phone copied to clipboard')),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
          initiallyExpanded: true,
        ),
      ],
    );
  }

  Widget _buildPrincipalCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableSection(
          'Primary Contact',
          [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.orange),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/person-icon.avif'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                customerDetails!['salutationname'] ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(' '),
                              Text(
                                customerDetails!['firstname'] ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(' '),
                              Text(
                                customerDetails!['lastname'] ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            customerDetails!['ContactDesignationName'] ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900),
                          ),
                          if (customerDetails!['mobile1'] != null &&
                              customerDetails!['mobile1'] != '')
                            _buildInteractiveDetailRow(
                              'Phone',
                              customerDetails!['mobile1'] ?? '',
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                    text: customerDetails!['mobile1'] ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Phone copied to clipboard')),
                                );
                              },
                            ),
                          if (customerDetails!['emailid1'] != null &&
                              customerDetails!['emailid1'] != '')
                            _buildInteractiveDetailRow(
                              'Email',
                              customerDetails!['emailid1'] ?? '',
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                    text: customerDetails!['emailid1'] ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Email copied to clipboard')),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          initiallyExpanded: true,
        ),
      ],
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableSection(
          'Contact',
          [
            StreamBuilder<List<ContactModel>?>(
              stream: _loadDataStream.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var data = snapshot.data;
                  return _widgetList(data);
                }
                return Text(
                  'No contact here.',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _widgetList(List<ContactModel>? contactList) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        border: Border.all(color: Colors.orange),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 10,
          columns: [
            DataColumn(
              label: Text(
                'S.No',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            DataColumn(
              label: Text(
                'Contact Name',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            DataColumn(
              label: Text(
                'Designation',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            DataColumn(
              label: Text(
                'Mobile',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            DataColumn(
              label: Text(
                'Email',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          rows: contactList != null
              ? contactList.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final contact = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        index.toString(),
                        style: TextStyle(fontSize: 12),
                      )),
                      DataCell(Text(
                        contact.contactName?.trim() ?? '',
                        style: TextStyle(fontSize: 12),
                      )),
                      DataCell(contact.designation == null ||
                              contact.designation!.isEmpty
                          ? Text('')
                          : Text(
                              contact.designation!.trim(),
                              style: TextStyle(fontSize: 12),
                            )),
                      DataCell(contact.mobile == null || contact.mobile!.isEmpty
                          ? Text('')
                          : Text(
                              contact.mobile!,
                              style: TextStyle(fontSize: 12),
                            )),
                      DataCell(contact.email == null || contact.email!.isEmpty
                          ? Text('')
                          : Text(
                              contact.email!,
                              style: TextStyle(fontSize: 12),
                            )),
                    ],
                  );
                }).toList()
              : [],
        ),
      ),
    );
  }

  Widget _buildTradeDetailsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableSection(
          'Customer Details',
          [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.orange),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customerDetails!['PanNumber'] != null &&
                        customerDetails!['PanNumber'] != '')
                      _buildDetailRow(
                        'PAN Number',
                        customerDetails!['PanNumber'] ?? '',
                      ),
                    if (customerDetails!['GstNumber'] != null &&
                        customerDetails!['GstNumber'] != '')
                      _buildDetailRow(
                        'GST Number',
                        customerDetails!['GstNumber'] ?? '',
                      ),
                    _buildDetailRow(
                      'Key Trade',
                      customerDetails!['KeyCustomer'] == 'Y' ? 'Yes' : 'No',
                    ),
                    _buildDetailRow(
                      'Trade Status',
                      customerDetails!['CustomerStatus'] ?? '',
                    ),
                    SizedBox(height: 2),
                    _buildCategoryCard(context),
                    _buildExecutiveCard(context),
                    SizedBox(height: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text(
          'Customer Category',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          selectedCategoryName ?? 'No category assigned',
          style: TextStyle(
            fontSize: 14,
            color: selectedCategoryName != null
                ? Colors.grey.shade800
                : Colors.red.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Accountable Executive',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          selectedExecutiveName ?? 'No executive assigned',
          style: TextStyle(
            fontSize: 14,
            color: selectedExecutiveName != null
                ? Colors.grey.shade800
                : Colors.red.shade400,
          ),
        ),
      ],
    );
  }

  // Widget _buildBooksellersCard(BuildContext context) {
  //   return Card(
  //     elevation: 4,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           _buildSectionHeader('Booksellers'),
  //           const SizedBox(height: 8),
  //           ...bookSellerList!
  //               .map((seller) => _buildBookSellerCard(seller))
  //               .toList(),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildSectionHeader(String title) {
  //   return Text(
  //     title,
  //     style: TextStyle(
  //       fontSize: 18,
  //       fontWeight: FontWeight.bold,
  //       color: Colors.blue.shade700,
  //     ),
  //   );
  // }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveDetailRow(String label, String value,
      {VoidCallback? onTap}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildBookSellerCard(dynamic seller) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(vertical: 8.0),
  //     decoration: BoxDecoration(
  //       color: Colors.grey.shade50,
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: Colors.grey.shade200),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           _buildDetailRow('Name', seller['BookSellerName'] ?? ''),
  //           _buildDetailRow('Address', seller['Address'] ?? ''),
  //           _buildDetailRow('City', seller['City'] ?? ''),
  //           _buildDetailRow('State', seller['State'] ?? ''),
  //           _buildDetailRow('Country', seller['Country'] ?? ''),
  //           _buildDetailRow('Action', seller['Action']?.toString() ?? ''),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDetail(String value, {Color? valueColor}) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 14,
        color: valueColor ?? Colors.grey.shade800,
      ),
    );
  }

  Widget _buildExpandableSection(String title, List<Widget> children,
      {bool initiallyExpanded = false}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: children,
        tilePadding: EdgeInsets.symmetric(horizontal: 6),
        initiallyExpanded: initiallyExpanded,
      ),
    );
  }

  @override
  void dispose() {
    _loadDataStream.close();
    super.dispose();
  }
}
