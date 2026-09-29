import 'package:dart_crm/providers/samplingProvider/request/customer_sampling_provider/customer_sampling_provider.dart';
import 'package:dart_crm/screens/homeScreen/widget/userHeader.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/customer_sampling_screen/customer_search_list_screen.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerSampleRequest extends ConsumerStatefulWidget {
  final String customerType;

  const CustomerSampleRequest({Key? key, required this.customerType})
      : super(key: key);

  @override
  _CustomerSampleRequestState createState() => _CustomerSampleRequestState();
}

class _CustomerSampleRequestState extends ConsumerState<CustomerSampleRequest> {
  final _formKey = GlobalKey<FormState>();
  String? city; // Stores composite value "state|cityId"
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
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    // Log setupValues for debugging
    print(
        'Setup Values: ${authState.setupValues?.map((v) => "${v.keyName}: ${v.keyValue}").toList() ?? []}');

    // Get mandatory flags from setupValues
    final isCustomerNameRequired =
        authNotifier.getSetupValue('CustomerNameRequired') == 'true' ||
            authNotifier.getSetupValue('CustomerNameRequired') == '1';
    final isCustomerCodeRequired =
        authNotifier.getSetupValue('CustomerCodeRequired') == 'true' ||
            authNotifier.getSetupValue('CustomerCodeRequired') == '1';
    final isCustomerContactNameRequired = authNotifier
                .getSetupValue('CustomerContactFirstLastNameMandatory')
                ?.toUpperCase() ==
            'F' ||
        authNotifier
                .getSetupValue('CustomerContactFirstLastNameMandatory')
                ?.toUpperCase() ==
            'B';
    final isCityRequired =
        authNotifier.getSetupValue('CityRequired') == 'true' ||
            authNotifier.getSetupValue('CityRequired') == '1';

    // Log if expected keys are missing
    if (authNotifier.getSetupValue('CustomerNameRequired') == null) {
      print('Warning: CustomerNameRequired not found in setupValues');
    }
    if (authNotifier.getSetupValue('CustomerCodeRequired') == null) {
      print('Warning: CustomerCodeRequired not found in setupValues');
    }
    if (authNotifier.getSetupValue('CustomerContactFirstLastNameMandatory') ==
        null) {
      print(
          'Warning: CustomerContactFirstLastNameMandatory not found in setupValues');
    }
    if (authNotifier.getSetupValue('CityRequired') == null) {
      print('Warning: CityRequired not found in setupValues');
    }

    // Log mandatory field states
    print('Mandatory Fields:');
    print('CustomerNameRequired: $isCustomerNameRequired');
    print('CustomerCodeRequired: $isCustomerCodeRequired');
    print('CustomerContactNameRequired: $isCustomerContactNameRequired');
    print('CityRequired: $isCityRequired');

    // Determine the label for the contact name field based on customerType
    final contactLabel = widget.customerType.toLowerCase() == 'school'
        ? 'Principal / Teacher Name'
        : 'Contact Name';
    final contactSemanticLabel = widget.customerType.toLowerCase() == 'school'
        ? 'Principal or Teacher Name'
        : 'Contact Name';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '${widget.customerType} Sampling - Search',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.black,
          ),
        ),
        backgroundColor: TColors.primary,
        elevation: 2,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Userheader(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Customer Details'),
                      const SizedBox(height: 15),
                      _buildTextField(
                        label: 'Customer Name',
                        icon: Icons.person_outline,
                        onChanged: (value) {
                          setState(() => customerName = value);
                          print('CustomerName updated: $customerName');
                        },
                        semanticLabel: 'Customer Name',
                        isRequired: isCustomerNameRequired,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        label: 'Customer Code',
                        icon: Icons.code,
                        onChanged: (value) {
                          setState(() => customerCode = value);
                          print('CustomerCode updated: $customerCode');
                        },
                        semanticLabel: 'Customer Code',
                        isRequired: isCustomerCodeRequired,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        label: contactLabel,
                        icon: Icons.contact_page_outlined,
                        onChanged: (value) {
                          setState(() => customerContactName = value);
                          print(
                              'CustomerContactName updated: $customerContactName');
                        },
                        semanticLabel: contactSemanticLabel,
                        // isRequired: isCustomerContactNameRequired,
                      ),
                      const SizedBox(height: 15),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 10),
                      _buildSectionTitle('Location'),
                      const SizedBox(height: 15),
                      _buildCityDropdown(isRequired: isCityRequired),
                      const SizedBox(height: 22),
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.search, color: Colors.white),
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

                                try {
                                  final cityId =
                                      city != null && city != 'SELECT|0'
                                          ? int.parse(city!.split('|')[1])
                                          : 0;
                                  final searchParams = {
                                    'CityId': cityId,
                                    'CustomerType': widget.customerType,
                                    'CustomerContactName':
                                        customerContactName ?? '',
                                    'CustomerCode': customerCode ?? '',
                                    'CustomerName': customerName ?? '',
                                  };
                                  print('Search Params: $searchParams');

                                  ref.invalidate(
                                      customerResultProvider(searchParams));

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CustomerResultScreen(
                                        searchParams: searchParams,
                                        customerType: widget.customerType,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Invalid city selection: $e')),
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
                                  horizontal: 32, vertical: 16),
                              backgroundColor: TColors.buttonPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
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
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        letterSpacing: 0.5,
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
        suffixIcon: isRequired
            ? const Icon(Icons.star, color: Colors.red, size: 10)
            : null,
      ),
      onChanged: onChanged,
      validator: isRequired
          ? (value) => value == null || value.trim().isEmpty
              ? 'Please enter $label'
              : null
          : null,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      keyboardAppearance: Brightness.light,
      textInputAction: TextInputAction.next,
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
}
