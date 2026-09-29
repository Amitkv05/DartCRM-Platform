import 'dart:async';
import 'dart:convert';
import 'package:dart_crm/edit/api/repository/api_service.dart';
import 'package:dart_crm/edit/model/school/SchoolListResponse.dart';
import 'package:dart_crm/edit/model/teacher/ContactModel.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/customer/customer_master_list_model.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/customerProvider/customer_entry_master_provider.dart';
import 'package:dart_crm/providers/geography_provider.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_crm/core/api/legacy_http.dart' as http;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class CustomerDetailsScreen extends ConsumerStatefulWidget {
  final CustomerMasterListItem? customer;
  final String customerType;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
    required this.customerType,
  });

  @override
  ConsumerState<CustomerDetailsScreen> createState() =>
      _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends ConsumerState<CustomerDetailsScreen> {
  Map<String, dynamic>? customerDetails;
  List<Map<String, dynamic>>? EnrolmentList;
  List<Map<String, dynamic>>? FacilitiesList;
  List<dynamic>? bookSellerList;
  bool isLoading = true;
  String? error;
  String? displayTitle;
  String? cityName;
  String? stateName;
  String? countryName;
  String? districtName;
  String? startClassName;
  String? endClassName;
  String? boardName;
  String? chainSchools;
  SchoolListResponse? apiData;
  String? title = '';
  int? customerId;

  final StreamController<List<ContactModel>?> _loadDataStream =
  BehaviorSubject();

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => onPostFrameCallback(context));
  }

  Future<void> _fetchCustomerDetails() async {
    final authState = ref.read(authProvider);
    final token = authState.token;
    if (token == null) {
      setState(() {
        isLoading = false;
        error = 'Please log in first';
      });
      return;
    }

    final requestBody = {
      'CustomerId': widget.customer?.customerId,
      'CustomerType': widget.customerType,
      'Validated': AppUtils.onlyChar(widget.customer?.action),
    };

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/FetchCustomerDetails'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      print(requestBody);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Status'] == 'Success') {
          setState(() {
            customerDetails = data['SchoolDetails']?.isNotEmpty == true
                ? data['SchoolDetails'][0]
                : null;
            EnrolmentList = (data['EnrolmentList'] as List?)
                ?.map((item) => item as Map<String, dynamic>)
                .toList() ??
                [];
            FacilitiesList = (data['SchoolFacility'] as List?)
                ?.map((item) => item as Map<String, dynamic>)
                .toList() ??
                [];
            bookSellerList = data['BookSellerList'];
            displayTitle = customerDetails?['SchoolDetails'] ??
                widget.customer?.customerName;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            error = 'No details found: ${data['s'] ?? 'Unknown error'}';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          error = 'Failed to fetch details: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Error fetching details: $e';
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

    if (customerDetails != null) {
      final cityId = (customerDetails!['CityId'] as num?)?.toInt();
      final stateId = (customerDetails!['StateId'] as num?)?.toInt();
      final countryId = (customerDetails!['CountryId'] as num?)?.toInt();
      final districtId = (customerDetails!['DistrictId'] as num?)?.toInt();

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
            city: 'Unknown',
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
            stateName: 'Unknown',
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
            country: 'Unknown',
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
            district: 'Unknown',
            cityId: 0,
            city: '',
          ),
        )
            .district
            : '';
      });
    }
  }

  void _mapClassAndBoardData(CustomerEntryMasterState masterState) {
    if (masterState.isLoading) {
      print('Master data is still loading');
      return;
    }

    if (masterState.error != null) {
      setState(() {
        error = 'Master data fetch failed: ${masterState.error}';
      });
      print('Master data error: ${masterState.error}');
      return;
    }

    final classList = masterState.classes;
    final boardList = masterState.boards;
    final chainSchoolList = masterState.chainSchools;
    if (classList.isEmpty || classList.isEmpty) {
      setState(() {
        error = 'No class or board data available';
      });
      print('Master data error: No class or board data available');
      return;
    }

    if (customerDetails != null) {
      final startClassId = (customerDetails!['StartClassId'] as num?)?.toInt();
      final endClassId = (customerDetails!['EndClassId'] as num?)?.toInt();
      final boardId = (customerDetails!['BoardId'] as num?)?.toInt();
      final chainSchoolId =
      (customerDetails!['ChainSchoolId'] as num?)?.toInt();

      setState(() {
        startClassName = startClassId != null
            ? classList
            .firstWhere(
              (item) => item.classNumId == startClassId,
          orElse: () => ClassItem(classNumId: 0, className: 'Unknown'),
        )
            .className
            : '';
        endClassName = endClassId != null
            ? classList
            .firstWhere(
              (item) => item.classNumId == endClassId,
          orElse: () => ClassItem(classNumId: 0, className: 'Unknown'),
        )
            .className
            : '';
        boardName = boardId != null
            ? boardList
            .firstWhere(
              (item) => item.boardId == boardId,
          orElse: () => BoardItem(boardId: 0, boardName: 'Unknown'),
        )
            .boardName
            : '';
        chainSchools = chainSchoolId != null
            ? chainSchoolList
            .firstWhere(
              (item) => item.chainSchoolId == chainSchoolId,
          orElse: () => ChainSchoolItem(
              chainSchoolId: 0, chainSchoolName: 'Unknown'),
        )
            .chainSchoolName
            : '';
      });
    }
  }

  String getMonthName(int? month) {
    if (month == null || month < 1 || month > 12) return '';
    return DateFormat.MMMM().format(DateTime(2025, month));
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
    final masterState = ref.watch(customerEntryMasterProvider);

    // Map geography and class/board data when providers are ready and customerDetails is available
    if (!geographyState.isLoading && customerDetails != null) {
      _mapGeographyData(geographyState);
    }
    if (!masterState.isLoading && customerDetails != null) {
      _mapClassAndBoardData(masterState);
    }

    if (isLoading || geographyState.isLoading || masterState.isLoading) {
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
                'Loading ${isLoading ? 'Customer' : (geographyState.isLoading ? 'Geography' : 'Master')} Details...',
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

    if (error != null) {
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
                error!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(geographyProvider);
                  ref.invalidate(customerEntryMasterProvider);
                  _fetchCustomerDetails();
                },
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
                child: _buildPrincipalCard(context),
              ),
              Transform.translate(
                offset: const Offset(0, -10),
                child: _buildTeacherCard(context),
              ),
              Transform.translate(
                offset: const Offset(0, -15),
                child: _buildSchoolDetailsCard(context),
              ),
              if (bookSellerList != null && bookSellerList!.isNotEmpty)
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: _buildBooksellersCard(context),
                ),
              Transform.translate(
                offset: const Offset(0, -25),
                child: _buildStrengthCard(context),
              ),
              Transform.translate(
                offset: const Offset(0, -30),
                child: _buildFacilitiesCard(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Details - $displayTitle',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: TColors.primary,
      // foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildCustomerCard(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableSection(
            'Address',
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
                          customerDetails!['SchoolName'] +
                              ' (' +
                              customerDetails!['SchoolCode'] +
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
                      // _buildDetail(districtName ?? ''),
                      Row(
                        children: [
                          _buildDetail(cityName ?? ''),
                          Text(', '),
                          _buildDetail(countryName ?? ''),
                        ],
                      ),
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
                      // Text("Teacher"),
                      // Text(EnrolmentList == null
                      //     ? "No Data"
                      //     : EnrolmentList!['ClassName'] ??
                      //         // : customerData!['EnrolmentList'][0]['ClassName'] ??
                      //         ''),
                      // _buildDetail(
                      //   customerDetails!['RefCode'] ?? '',
                      // ),
                      // _buildDetail(
                      //   'Validation Status',
                      //   customerDetails!['ValidationStatus'] == 'Y'
                      //       ? 'Validated'
                      //       : 'Pending',
                      //   valueColor: customerDetails!['ValidationStatus'] == 'Y'
                      //       ? Colors.green.shade600
                      //       : Colors.orange.shade600,
                      // ),
                      // _buildDetail(
                      //   customerDetails!['CustomerStatus'] ?? '',
                      // ),
                      // _buildDetail(
                      //   customerDetails!['KeyCustomer'] ?? '',
                      // ),
                    ],
                  ),
                ),
              ),
            ],
            initiallyExpanded: true),
      ],
    );
  }

  Widget _buildPrincipalCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableSection(
            'Principal',
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
                            if (customerDetails!['ContactDesignationName'] !=
                                null &&
                                customerDetails!['ContactDesignationName'] !=
                                    '')
                              Text(
                                customerDetails!['ContactDesignationName'] ??
                                    '',
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
                                        Text('Email copied to clipboard')),
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
                                      text: customerDetails!['EmailId'] ?? ''));
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
            initiallyExpanded: true),
      ],
    );
  }

  Widget _buildTeacherCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableSection('Teacher', [
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
              }),
        ]),
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
                'Name',
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
            DataColumn(
              label: Text(
                'Primary Contact',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          rows: contactList != null
              ? contactList.asMap().entries.map((entry) {
            final index = entry.key + 1; // S.No starts from 1
            final teacher = entry.value;
            return DataRow(
              // color: MaterialStateProperty.resolveWith<Color?>(
              //   (Set<MaterialState> states) {
              //     return Colors.grey.shade200; // Background color
              //   },
              // ),
              cells: [
                DataCell(Text(
                  index.toString(),
                  style: TextStyle(fontSize: 12),
                )),
                DataCell(Text(
                  teacher.contactName?.trim() ?? 'NA',
                  style: TextStyle(fontSize: 12),
                )),
                DataCell(teacher.designation == null ||
                    teacher.designation!.isEmpty
                    ? Text('NA')
                    : Text(
                  teacher.designation!.trim(),
                  style: TextStyle(fontSize: 12),
                )),
                DataCell(teacher.mobile == null || teacher.mobile!.isEmpty
                    ? Text('NA')
                    : Text(
                  teacher.mobile!,
                  style: TextStyle(fontSize: 12),
                )),
                DataCell(teacher.email == null || teacher.email!.isEmpty
                    ? Text('NA')
                    : Text(
                  teacher.email!,
                  style: TextStyle(fontSize: 12),
                )),
                DataCell(Text(
                  teacher.primaryContact ?? 'NA',
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

  Widget _buildStrengthCard(BuildContext context) {
    return _buildExpandableSection('School Strength', [
      Container(
        width: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange),
        ),
        child: DataTable(
          columns: [
            DataColumn(label: Text('CLASS NAME')),
            DataColumn(label: Text('ENROLLMENT')),
          ],
          rows: EnrolmentList != null
              ? EnrolmentList!.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['ClassName'].toString())),
              DataCell(Text(item['EnrolValue'].toString())),
            ]);
          }).toList()
              : [], // Fallback to empty list if EnrolmentList is null
        ),
      ),
    ]);
  }

  Widget _buildFacilitiesCard(BuildContext context) {
    // Filter facilities where FacilityAvailable is 'Y'
    final availableFacilities = FacilitiesList != null
        ? FacilitiesList!
        .where((item) => item['FacilityAvailable'] == 'Y')
        .toList()
        : [];

    return _buildExpandableSection(
      'School Facilities',
      [
        availableFacilities.isNotEmpty
            ? Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange),
          ),
          child: DataTable(
            columns: [
              DataColumn(label: Text('S.NO.')),
              DataColumn(label: Text('School Facility')),
            ],
            rows: availableFacilities.map((item) {
              return DataRow(cells: [
                DataCell(Text(item['CustomerFacilityId'].toString())),
                DataCell(Text(item['CustomerFacilityName'].toString())),
              ]);
            }).toList(),
          ),
        )
            : Center(
          child: Text(
            'No Facility Available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolDetailsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableSection(
          'School Details',
          [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.orange),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
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
                    _buildDetailRow('Board', boardName ?? ''),
                    _buildDetailRow(
                      'Medium',
                      customerDetails!['MediumInstruction'] ?? '',
                    ),
                    // classes..
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: Text(
                              'Classes:',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            startClassName ?? '',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          Text('-'),
                          Text(
                            endClassName ?? '',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (chainSchools != null &&
                        chainSchools != "" &&
                        chainSchools!.isNotEmpty &&
                        chainSchools != '')
                      _buildDetailRow('Chain School', chainSchools ?? ''),
                    _buildDetailRow(
                      'Sampling Month',
                      getMonthName(customerDetails!['SamplingMonth']) ?? '',
                    ),
                    _buildDetailRow(
                      'Decision Month',
                      getMonthName(customerDetails!['DecisionMonth']) ?? '',
                    ),
                    _buildDetailRow(
                        'Ranking/Category', customerDetails!['Ranking'] ?? ''),
                    _buildDetailRow(
                      'Purchase Mode',
                      customerDetails!['PurchaseMode'] ?? '',
                    ),
                    _buildDetailRow(
                      'Average Fee',
                      customerDetails!['AverageFee'].toString() ?? '',
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

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

  Widget _buildDetail(String value, {Color? valueColor}) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 14,
        color: valueColor ?? Colors.grey.shade800,
      ),
    );
  }

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

  Widget _buildBooksellersCard(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildExpandableSection('Booksellers', [
        const SizedBox(height: 4),
        ...bookSellerList!
            .map((seller) => _buildBookSellerCard(seller))
            .toList(),
      ]),
    ]);
  }

  Widget _buildBookSellerCard(dynamic seller) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TColors.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seller['BookSellerName'] ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            _buildBookSellerDetail(seller['Address'].trim() ?? ''),
            _buildBookSellerDetail(seller['City'] ?? ''),
            _buildBookSellerDetail(seller['State'] ?? ''),
            _buildBookSellerDetail(seller['Country'] ?? ''),
            // _buildBookSellerDetail(seller['Action']?.toString() ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildBookSellerDetail(String value, {Color? valueColor}) {
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
        tilePadding: EdgeInsets.symmetric(horizontal: 4),
        initiallyExpanded: initiallyExpanded,
      ),
    );
  }
}