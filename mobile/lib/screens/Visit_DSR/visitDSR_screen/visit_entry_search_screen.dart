import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/setup_value.dart';
import 'package:dart_crm/screens/Visit_DSR/visitDSR_screen/visit_entry_search_list.dart';
import 'package:dart_crm/screens/homeScreen/widget/userHeader.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:dart_crm/core/api/legacy_http.dart' as http;

final cityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authProvider);
  final token = authState.token;

  if (token == null) throw Exception('No authentication token available');

  final response = await http.post(
    Uri.parse('$BASE_URL/CityListForSearchCustomer'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'ExecutiveId': AppUtils.getExecutiveStr(),
      'ExecutiveDownHierarchy': AppUtils.getDownStr()
    }),
    // body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data['Status'] == 'Success') {
      final cityList =
          List<Map<String, dynamic>>.from(data['CityList']).map((city) {
        return {
          ...city,
          'CityId': (city['CityId'] is double
              ? city['CityId'].toInt()
              : int.tryParse(city['CityId'].toString()) ?? city['CityId']),
        };
      }).toList();

      return cityList;
    } else {
      throw Exception('Failed to load cities: ${data['Message']}');
    }
  } else {
    throw Exception('Server error: ${response.statusCode}');
  }
});

final customerResultProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>(
        (ref, searchParams) async {
  final authState = ref.watch(authProvider);
  final token = authState.token;
  if (token == null) throw Exception('No authentication token available');

  final requestBody = {
    'ExecutiveId': AppUtils.getExecutiveStr(),
    'ExecutiveDownHierarchy': AppUtils.getDownStr(),
    'CityId': searchParams['CityId'],
    'CityAccess': AppUtils.getCityAccess(),
    'TerritoryAccess': AppUtils.getTerritoryAccess(),
    'CustomerType': searchParams['CustomerType'],
    'CustomerContactName': searchParams['CustomerContactName'],
    'CustomerCode': searchParams['CustomerCode'],
    'CustomerName': searchParams['CustomerName'],
  };

  final response = await http.post(
    Uri.parse('$BASE_URL/SearchCustomerResult'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['Status'] == 'Success') {
      final results = List<Map<String, dynamic>>.from(data['Result']);
      print('Unfiltered Results: $results');

      return results.where((customer) {
        bool matches = true;

        // CityId comparison
        if (searchParams['CityId'] != null &&
            searchParams['CityId'] != 0 &&
            customer.containsKey('CityId')) {
          final customerCityId = customer['CityId'] is int
              ? customer['CityId']
              : int.tryParse(customer['CityId'].toString());
          final searchCityId = searchParams['CityId'] is int
              ? searchParams['CityId']
              : int.tryParse(searchParams['CityId'].toString());
          matches = matches &&
              customerCityId != null &&
              searchCityId != null &&
              customerCityId == searchCityId;
        }

        // CustomerType comparison
        if (searchParams['CustomerType'] != null &&
            customer.containsKey('CustomerType')) {
          matches = matches &&
              customer['CustomerType'].toString() ==
                  searchParams['CustomerType'].toString();
        }

        // CustomerName comparison
        if (searchParams['CustomerName'] != null &&
            customer.containsKey('CustomerName')) {
          final customerName = customer['CustomerName']?.toString() ?? '';
          final searchName = searchParams['CustomerName']?.toString() ?? '';
          matches = matches &&
              customerName.toLowerCase().contains(searchName.toLowerCase());
        }

        // CustomerCode comparison
        if (searchParams['CustomerCode'] != null &&
            customer.containsKey('CustomerCode')) {
          final customerCode = customer['CustomerCode']?.toString() ?? '';
          final searchCode = searchParams['CustomerCode']?.toString() ?? '';
          matches = matches &&
              customerCode.toLowerCase().contains(searchCode.toLowerCase());
        }

        // CustomerContactName comparison
        if (searchParams['CustomerContactName'] != null &&
            customer.containsKey('CustomerContactName')) {
          final customerContactName =
              customer['CustomerContactName']?.toString() ?? '';
          final searchContactName =
              searchParams['CustomerContactName']?.toString() ?? '';
          matches = matches &&
              customerContactName
                  .toLowerCase()
                  .contains(searchContactName.toLowerCase());
        }

        return matches;
      }).toList();
    } else {
      throw Exception('Failed to load customers: ${data['Message']}');
    }
  } else {
    throw Exception('Server error: ${response.statusCode}');
  }
});

class VisitEntryScreen extends ConsumerStatefulWidget {
  const VisitEntryScreen({Key? key}) : super(key: key);

  @override
  _VisitEntryScreenState createState() => _VisitEntryScreenState();
}

class _VisitEntryScreenState extends ConsumerState<VisitEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String? city; // Stores CityId as a String
  String? customerType; // Stores CustomerType
  String? customerName, customerCode, customerContactName;

  final TextEditingController _cityController =
      TextEditingController(); // Added controller

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).getSetupValues());
  }

  @override
  void dispose() {
    _cityController.dispose(); // Dispose of the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authProvider.notifier);

    final isCustomerNameRequired =
        authNotifier.getSetupValue('CustomerNameRequired') == 'true' ||
            authNotifier.getSetupValue('CustomerNameRequired') == '1';
    final isCustomerCodeRequired =
        authNotifier.getSetupValue('CustomerCodeRequired') == 'true' ||
            authNotifier.getSetupValue('CustomerCodeRequired') == '1';

    authNotifier
            .getSetupValue('CustomerContactFirstLastNameMandatory')
            ?.toUpperCase() ==
        'B';
    final isCityRequired =
        authNotifier.getSetupValue('CityRequired') == 'true' ||
            authNotifier.getSetupValue('CityRequired') == '1';
    final isCustomerTypeRequired =
        authNotifier.getSetupValue('CustomerTypeRequired') == 'true' ||
            authNotifier.getSetupValue('CustomerTypeRequired') == '1';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Visit Entry',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: TColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Userheader(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Customer Details'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Customer Name',
                          icon: Icons.person_outline,
                          onChanged: (value) => setState(() =>
                              customerName = value.isEmpty ? null : value),
                          semanticLabel: 'Customer Name',
                          isRequired: isCustomerNameRequired,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Customer Code',
                          icon: Icons.code,
                          onChanged: (value) => setState(() =>
                              customerCode = value.isEmpty ? null : value),
                          semanticLabel: 'Customer Code',
                          isRequired: isCustomerCodeRequired,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Location'),
                        const SizedBox(height: 16),
                        _buildCityDropdown(isRequired: isCityRequired),
                        const SizedBox(height: 16),
                        _buildCustomerTypeDropdown(
                            isRequired: isCustomerTypeRequired),
                        const SizedBox(height: 16),
                        Center(
                            child: ElevatedButton.icon(
                          icon: Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (isCityRequired &&
                                  (city == null || city == 'SELECT|0')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please select a valid city')),
                                );
                                return;
                              }
                              if (isCustomerTypeRequired &&
                                  (customerType == null ||
                                      customerType == 'Select')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please select a valid customer type')),
                                );
                                return;
                              }

                              try {
                                // Extract CityId from composite value (e.g., 'MAHARASHTRA|456')
                                String? cityId;
                                if (city != null && city != 'SELECT|0') {
                                  final parts = city!.split('|');
                                  if (parts.length == 2) {
                                    cityId = parts[1]; // e.g., '456'
                                  }
                                }

                                // Extract CustomerType (exclude 'Select')
                                String? selectedCustomerType;
                                if (customerType != null &&
                                    customerType != 'Select') {
                                  selectedCustomerType = customerType;
                                }

                                final searchParams = {
                                  'CityId': cityId, // String, API will parse
                                  'CustomerType': selectedCustomerType,
                                  'CustomerContactName': customerContactName,
                                  'CustomerCode': customerCode,
                                  'CustomerName': customerName,
                                  'ExecutiveId': AppUtils.getExecutiveStr(),
                                  'DownHierarchyExecutive':
                                      AppUtils.getDownStr(),
                                };
                                print('Search Params: $searchParams');

                                ref.invalidate(
                                    customerResultProvider(searchParams));

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VisitEntryResultScreen(
                                            searchParams: searchParams,
                                            customerType: selectedCustomerType),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Invalid selection: $e')),
                                );
                              }
                            }
                          },
                          label: const Text(
                            'Search',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            backgroundColor: TColors.buttonPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF424242),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
    required String semanticLabel,
    bool isRequired = false,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.icon),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.icon),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.icon),
        ),
        prefixIcon: Icon(icon, color: TColors.icon),
        suffixIcon: isRequired
            ? const Icon(Icons.star, color: Colors.red, size: 10)
            : null, // Optional: Add visual indicator for mandatory fields
      ),
      onChanged: onChanged,
      validator: isRequired
          ? (value) => value == null || value.trim().isEmpty
              ? 'Please enter $label'
              : null
          : null,
      style: const TextStyle(fontSize: 16),
      keyboardAppearance: Brightness.light,
      textInputAction: TextInputAction.next,
      // semanticLabel: semanticLabel,
    );
  }

  Widget _buildCityDropdown({bool isRequired = false}) {
    final cityListAsyncValue = ref.watch(cityProvider);

    print('Current city value: $city');

    return cityListAsyncValue.when(
      data: (cities) {
        print('Cities loaded: $cities');
        // Clean and group cities
        final Map<String, List<Map<String, dynamic>>> groupedCities = {};
        for (var city in cities) {
          if (city['CityId'] != null && city['CityId'] != 0) {
            final state =
                (city['StateName'] ?? 'Unknown').toString().toUpperCase();
            groupedCities.putIfAbsent(state, () => []).add(city);
          }
        }

        // Create dropdown items with 'Select' option, state headers, and city children
        final List<Map<String, dynamic>> dropdownItems = [
          {
            'value': 'SELECT|0',
            'isSelectable': true,
            'child': Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          },
        ];

        final sortedStates = groupedCities.keys.toList()..sort();

        for (var state in sortedStates) {
          dropdownItems.add({
            'value': null,
            'isSelectable': false,
            'child': Container(
              color: TColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                state,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          });

          final citiesInState = groupedCities[state]!
            ..sort((a, b) =>
                (a['CityName'] ?? '').compareTo((b['CityName'] ?? '')));
          for (var c in citiesInState) {
            final cityName = c['CityName'] ?? 'Unknown City';
            final cityId = c['CityId'].toString();
            final compositeValue = '$state|$cityId';
            dropdownItems.add({
              'value': compositeValue,
              'isSelectable': true,
              'child': Padding(
                padding: const EdgeInsets.only(
                    left: 32, right: 16, bottom: 5, top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    if (city == compositeValue)
                      const Icon(Icons.check, color: Colors.blue),
                  ],
                ),
              ),
            });
          }
        }

        // Get the display text for the selected city
        String getSelectedCityName() {
          if (city == null || city == 'SELECT|0') {
            return 'Select';
          }
          final parts = city!.split('|');
          if (parts.length != 2) {
            return 'Select';
          }
          final selectedCityId = parts[1];
          final selectedCity = cities.firstWhere(
            (c) => c['CityId'].toString() == selectedCityId,
            orElse: () => {'CityName': 'Select'},
          );
          return selectedCity['CityName'] as String? ?? 'Select';
        }

        // Function to show custom dropdown dialog
        void showCustomDropdown(BuildContext context) {
          final TextEditingController searchController =
              TextEditingController();
          String searchQuery = '';
          List<Map<String, dynamic>> filteredItems = List.from(dropdownItems);

          void updateFilteredItems() {
            if (searchQuery.isEmpty) {
              filteredItems = List.from(dropdownItems);
            } else {
              filteredItems = [];
              // Always include the 'Select' option
              filteredItems.add(dropdownItems
                  .firstWhere((item) => item['value'] == 'SELECT|0'));

              // Filter cities by name, preserving state headers
              for (var state in sortedStates) {
                final matchingCities = groupedCities[state]!
                    .where((c) => (c['CityName'] ?? '')
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()))
                    .toList();
                if (matchingCities.isNotEmpty) {
                  // Add state header
                  filteredItems.add(dropdownItems.firstWhere(
                    (item) {
                      if (item['value'] != null) return false;
                      final child = item['child'] as Container;
                      final textWidget = child.child as Text;
                      return textWidget.data == state;
                    },
                  ));
                  // Add matching cities
                  for (var c in matchingCities
                    ..sort((a, b) => (a['CityName'] ?? '')
                        .compareTo((b['CityName'] ?? '')))) {
                    final cityName = c['CityName'] ?? 'Unknown City';
                    final cityId = c['CityId'].toString();
                    final compositeValue = '$state|$cityId';
                    filteredItems.add({
                      'value': compositeValue,
                      'isSelectable': true,
                      'child': Padding(
                        padding: const EdgeInsets.only(left: 32, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cityName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            if (city == compositeValue)
                              const Icon(Icons.check, color: Colors.blue),
                          ],
                        ),
                      ),
                    });
                  }
                }
              }
            }
          }

          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: StatefulBuilder(
                    builder:
                        (BuildContext context, StateSetter dialogSetState) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Search city by name...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              onChanged: (value) {
                                dialogSetState(() {
                                  searchQuery = value;
                                  updateFilteredItems();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelectable =
                                    item['isSelectable'] as bool;
                                return InkWell(
                                  onTap: isSelectable
                                      ? () {
                                          setState(() {
                                            city = item['value'];
                                            _cityController.text =
                                                getSelectedCityName();
                                            print(
                                                'Selected city (composite): $city');
                                          });
                                          Navigator.pop(dialogContext);
                                        }
                                      : null,
                                  child: item['child'] as Widget,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          );
        }

        return TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'City',
            labelStyle: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TColors.borderColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            hintText: 'Select a city',
            hintStyle: const TextStyle(color: Colors.grey),
            suffixIcon: isRequired
                ? const Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.arrow_drop_down),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.star, color: Colors.red, size: 10),
                      ),
                    ],
                  )
                : const Icon(Icons.arrow_drop_down),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          ),
          controller: _cityController,
          onTap: () => showCustomDropdown(context),
          validator: isRequired
              ? (value) {
                  if (city == null || city == 'SELECT|0') {
                    return 'Please select a valid city';
                  }
                  final parts = city!.split('|');
                  if (parts.length != 2 || parts[1] == '0') {
                    return 'Please select a valid city';
                  }
                  return null;
                }
              : null,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Text('Error: $error', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildCustomerTypeDropdown({bool isRequired = false}) {
    final authState = ref.watch(authProvider);

    // Define a default SetupValue object for orElse
    final defaultSetupValue = SetupValue(
      id: 0,
      keyName: '',
      keyValue: '',
      keyStatus: false,
      keyDescription: '',
    );

    // Fetch customer types from setupValues
    final customerTypesRaw = authState.setupValues
            ?.firstWhere(
              (v) => v.keyName == 'CustomerTypes',
              orElse: () => defaultSetupValue,
            )
            .keyValue ??
        '';

    // Initialize customer types with two hardcoded values
    List<String> customerTypes = ['Select', 'School'];

    // Parse customer types (comma-separated string)
    if (customerTypesRaw is String && customerTypesRaw.isNotEmpty) {
      final parsedTypes =
          customerTypesRaw.split(',').map((type) => type.trim()).toList();
      // Add dynamic types while preserving order, avoiding duplicates
      for (var type in parsedTypes) {
        if (!customerTypes.contains(type)) {
          customerTypes.add(type);
        }
      }
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Customer Type',
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.icon),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.icon),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.icon),
        ),
        suffixIcon: isRequired
            ? const Icon(Icons.star, color: Colors.red, size: 10)
            : null,
      ),
      value: customerType ?? 'Select',
      items: customerTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          customerType = newValue;
          print('Selected customer type: $customerType');
        });
      },
      validator: isRequired
          ? (value) => value == null || value == 'Select'
              ? 'Please select a valid customer type'
              : null
          : null,
      dropdownColor: Colors.white,
      isExpanded: true,
      hint: const Text('Select', style: TextStyle(color: Colors.grey)),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
    );
  }
}
