import 'dart:convert';
import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/edit/api/repository/api_service.dart';
import 'package:dart_crm/edit/model/seller/BookSellerRequest.dart';
import 'package:dart_crm/models/customer/customer_master_list_model.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/customerProvider/customer_entry_master_provider.dart';
import 'package:dart_crm/providers/geography_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_crm/core/api/legacy_http.dart' as http;

class CustomerEditScreen extends ConsumerStatefulWidget {
  final CustomerMasterListItem customer;
  final String customerType;

  const CustomerEditScreen({
    super.key,
    required this.customer,
    required this.customerType,
  });

  @override
  ConsumerState<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends ConsumerState<CustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  String primaryContact = 'Y';
  int? salutationId = 4;
  int? contactDesignationId = 9;
  String firstName = '';
  String lastName = '';
  String contactEmailId = '';
  String contactMobile = '';
  String contactStatus = 'Active';
  int enteredBy = 8;
  String validated = 'A';
  String resAddress = '';
  int? resCity;
  String resPincode = '';
  int? stateId;
  int? countryId;
  String birthDay = '';
  String anniversary = '';
  String? customerContactId;
  String xmlSubjectClassDM = '';
  int? dataSourceId = 4;

  String? firstLastNameMandatory;
  String? mobileEmailMandatory;
  bool isLoading = true;
  bool isSubmitting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadSetupValues();
    _fetchCustomerDetails();
  }

  void _loadSetupValues() {
    final authNotifier = ref.read(authProvider.notifier);
    firstLastNameMandatory =
        authNotifier.getSetupValue('CustomerContactFirstLastNameMandatory');
    mobileEmailMandatory =
        authNotifier.getSetupValue('CustomerMobileorEmailMendatory');
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
      'CustomerId': widget.customer.customerId,
      'CustomerType': widget.customerType,
      'Validated': validated,
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Status'] == 'Success' &&
            data['SchoolDetails']?.isNotEmpty == true) {
          final details = data['SchoolDetails'][0];
          setState(() {
            firstName = details['SchoolName']?.split(' ').first ?? '';
            lastName = details['SchoolName']?.split(' ').length > 1
                ? details['SchoolName'].split(' ').skip(1).join(' ')
                : '';
            contactEmailId = details['EmailId'] ?? '';
            contactMobile = details['Mobile'] ?? '';
            resAddress = details['Address'] ?? '';
            resCity = (details['CityId'] as num?)?.toInt();
            stateId = (details['StateId'] as num?)?.toInt();
            countryId = (details['CountryId'] as num?)?.toInt();
            resPincode = details['Pincode'] ?? '';
            contactStatus = details['CustomerStatus'] ?? 'Active';
            customerContactId = details['CustomerContactId']?.toString();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            error = 'No details found';
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

  Future<void> _submitContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);
    final authState = ref.read(authProvider);
    final token = authState.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      setState(() => isSubmitting = false);
      return;
    }

    final requestBody = _buildRequestBody();
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/ContactEntryorUpdateAPI'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['Status'] == 'Success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['s'])),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed: ${responseData['s'] ?? 'HTTP ${response.statusCode}'}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Map<String, dynamic> _buildRequestBody() {
    final body = {
      'CustomerType': widget.customerType,
      'PrimaryContact': primaryContact,
      'ContactDesignationId': contactDesignationId,
      'ContactStatus': contactStatus,
      'EnteredBy': enteredBy,
      'CustomerId': widget.customer.customerId,
      'Validated': validated,
    };

    if (salutationId != null) body['SalutationId'] = salutationId;
    if (firstLastNameMandatory == 'F' || firstLastNameMandatory == 'B') {
      body['FirstName'] = firstName;
    }
    if (firstLastNameMandatory == 'L' || firstLastNameMandatory == 'B') {
      body['LastName'] = lastName;
    }
    if (mobileEmailMandatory == 'M' || mobileEmailMandatory == 'B') {
      body['ContactMobile'] = contactMobile;
    }
    if (mobileEmailMandatory == 'E' || mobileEmailMandatory == 'B') {
      body['ContactEmailId'] = contactEmailId;
    }
    if (mobileEmailMandatory == 'N') {
      if (contactMobile.isNotEmpty) body['ContactMobile'] = contactMobile;
      if (contactEmailId.isNotEmpty) body['ContactEmailId'] = contactEmailId;
    }
    if (mobileEmailMandatory == 'A') {
      if (contactMobile.isNotEmpty) {
        body['ContactMobile'] = contactMobile;
      } else if (contactEmailId.isNotEmpty) {
        body['ContactEmailId'] = contactEmailId;
      }
    }
    if (resAddress.isNotEmpty) {
      body['resAddress'] = resAddress;
      body['resCity'] = resCity;
      body['resPincode'] = resPincode;
      body['StateId'] = stateId;
      body['CountryId'] = countryId;
    }
    if (birthDay.isNotEmpty) body['BirthDay'] = birthDay;
    if (anniversary.isNotEmpty) body['Anniversary'] = anniversary;
    if (customerContactId != null)
      body['CustomerContactId'] = customerContactId;
    if (widget.customerType == 'School' || widget.customerType == 'Library') {
      if (xmlSubjectClassDM.isNotEmpty)
        body['xmlSubjectClassDM'] = xmlSubjectClassDM;
      if (dataSourceId != null) body['DataSourceId'] = dataSourceId;
    }

    return body;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: Text('Edit Contact - ${widget.customer.customerName}',
              style: const TextStyle(color: Colors.white)),
        ),
        body: Center(
            child: Text(error!, style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('Edit Contact - ${widget.customer.customerName}',
            style: const TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SAVE CONTACT',
                      style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact details being updated',
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'First Name *',
                firstName,
                (value) => firstName = value,
                isRequired: firstLastNameMandatory == 'F' ||
                    firstLastNameMandatory == 'B',
              ),
              _buildTextField(
                'Last Name',
                lastName,
                (value) => lastName = value,
                isRequired: firstLastNameMandatory == 'L' ||
                    firstLastNameMandatory == 'B',
              ),
              _buildTextField(
                'Email Id',
                contactEmailId,
                (value) => contactEmailId = value,
                isRequired:
                    mobileEmailMandatory == 'E' || mobileEmailMandatory == 'B',
              ),
              _buildTextField(
                'Mobile Number',
                contactMobile,
                (value) => contactMobile = value,
                isRequired:
                    mobileEmailMandatory == 'M' || mobileEmailMandatory == 'B',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  _buildTabButton(
                    context,
                    'Address',
                    AddressPopup(
                      resAddress: resAddress,
                      resPincode: resPincode,
                      onAddressChanged: (value) =>
                          setState(() => resAddress = value),
                      onPincodeChanged: (value) =>
                          setState(() => resPincode = value),
                      onCountryChanged: (value) =>
                          setState(() => countryId = value),
                      onStateChanged: (value) =>
                          setState(() => stateId = value),
                      onCityChanged: (value) => setState(() => resCity = value),
                      initialCountryId: countryId,
                      initialStateId: stateId,
                      initialCityId: resCity,
                    ),
                  ),
                  _buildTabButton(
                    context,
                    'School Details',
                    SchoolDetailsPopup(
                      primaryContact: primaryContact,
                      contactStatus: contactStatus,
                      onPrimaryContactChanged: (value) =>
                          setState(() => primaryContact = value!),
                      onContactStatusChanged: (value) =>
                          setState(() => contactStatus = value!),
                    ),
                  ),
                  _buildTabButton(context, 'Enrollment', EnrollmentPopup()),
                  _buildTabButton(
                    context,
                    'Teachers',
                    TeachersPopup(
                      customerContactId: int.tryParse(customerContactId ?? '0'),
                    ),
                  ),
                  _buildTabButton(
                      context, 'School Facility', SchoolFacilityPopup()),
                  _buildTabButton(
                    context,
                    'Notes/Comments',
                    NotesCommentsPopup(
                      birthDay: birthDay,
                      anniversary: anniversary,
                      xmlSubjectClassDM: xmlSubjectClassDM,
                      onBirthDayChanged: (value) =>
                          setState(() => birthDay = value),
                      onAnniversaryChanged: (value) =>
                          setState(() => anniversary = value),
                      onXmlSubjectClassDMChanged: (value) =>
                          setState(() => xmlSubjectClassDM = value),
                      customerType: widget.customerType,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Update',
                          style: TextStyle(color: Colors.blue)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String initialValue, Function(String) onChanged,
      {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: onChanged,
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return '$label is required';
              }
              if (mobileEmailMandatory == 'A' &&
                  label == 'Mobile Number' &&
                  contactEmailId.isEmpty &&
                  (value == null || value.isEmpty)) {
                return 'Either Mobile or Email is required';
              }
              if (mobileEmailMandatory == 'A' &&
                  label == 'Email Id' &&
                  contactMobile.isEmpty &&
                  (value == null || value.isEmpty)) {
                return 'Either Mobile or Email is required';
              }
              if (resAddress.isNotEmpty) {
                if (label == 'Pincode' &&
                    (resPincode == null || resPincode.isEmpty)) {
                  return 'Pincode is required when address is provided';
                }
                if ((label == 'Address' || label == 'Pincode') &&
                    (resCity == null || stateId == null || countryId == null)) {
                  return 'City, State, and Country are required when address is provided';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String title, Widget popup) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: popup,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.blue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(title, style: const TextStyle(color: Colors.blue)),
    );
  }
}

// Popup Widgets
class AddressPopup extends ConsumerStatefulWidget {
  final String resAddress;
  final String resPincode;
  final Function(String) onAddressChanged;
  final Function(String) onPincodeChanged;
  final Function(int?) onCountryChanged;
  final Function(int?) onStateChanged;
  final Function(int?) onCityChanged;
  final int? initialCountryId;
  final int? initialStateId;
  final int? initialCityId;

  const AddressPopup({
    required this.resAddress,
    required this.resPincode,
    required this.onAddressChanged,
    required this.onPincodeChanged,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
    this.initialCountryId,
    this.initialStateId,
    this.initialCityId,
  });

  @override
  _AddressPopupState createState() => _AddressPopupState();
}

class _AddressPopupState extends ConsumerState<AddressPopup> {
  late String _address;
  late String _pincode;
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _address = widget.resAddress;
    _pincode = widget.resPincode;
    final geographyState = ref.read(geographyProvider);

    if (widget.initialCountryId != null) {
      _selectedCountry = geographyState.geography
          .firstWhere(
            (item) => item.countryId == widget.initialCountryId,
            orElse: () => GeographyItem(
              countryId: 0,
              country: '',
              stateId: 0,
              stateName: '',
              districtId: 0,
              district: '',
              cityId: 0,
              city: '',
            ),
          )
          .country;
      if (_selectedCountry == '') _selectedCountry = null;
    }

    if (widget.initialStateId != null && _selectedCountry != null) {
      _selectedState = geographyState.geography
          .firstWhere(
            (item) =>
                item.stateId == widget.initialStateId &&
                item.country == _selectedCountry,
            orElse: () => GeographyItem(
              countryId: 0,
              country: '',
              stateId: 0,
              stateName: '',
              districtId: 0,
              district: '',
              cityId: 0,
              city: '',
            ),
          )
          .stateName;
      if (_selectedState == '') _selectedState = null;
    }

    if (widget.initialCityId != null && _selectedState != null) {
      _selectedCity = geographyState.geography
          .firstWhere(
            (item) =>
                item.cityId == widget.initialCityId &&
                item.stateName == _selectedState &&
                item.country == _selectedCountry,
            orElse: () => GeographyItem(
              countryId: 0,
              country: '',
              stateId: 0,
              stateName: '',
              districtId: 0,
              district: '',
              cityId: 0,
              city: '',
            ),
          )
          .city;
      if (_selectedCity == '') _selectedCity = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final geographyState = ref.watch(geographyProvider);
    final geographyNotifier = ref.read(geographyProvider.notifier);

    if (geographyState.isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (geographyState.error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text('Error: ${geographyState.error}')),
      );
    }

    final countries = geographyNotifier.getCountries();
    final states = geographyNotifier.getStates(_selectedCountry);
    final cities =
        geographyNotifier.getCities(_selectedCountry, _selectedState);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField('Address', _address, (value) {
            _address = value;
            widget.onAddressChanged(value);
          }),
          _buildTextField('Pincode', _pincode, (value) {
            _pincode = value;
            widget.onPincodeChanged(value);
          }, isRequired: _address.isNotEmpty),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Country Name',
              border: OutlineInputBorder(),
            ),
            value: _selectedCountry,
            items: countries
                .map((country) => DropdownMenuItem(
                      value: country,
                      child: Text(country),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
                _selectedState = null;
                _selectedCity = null;
                widget.onCountryChanged(value != null
                    ? geographyState.geography
                        .firstWhere((item) => item.country == value)
                        .countryId
                    : null);
                widget.onStateChanged(null);
                widget.onCityChanged(null);
              });
            },
            validator: (value) => _address.isNotEmpty && value == null
                ? 'Country is required'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'State Name',
              border: OutlineInputBorder(),
            ),
            value: _selectedState,
            items: states
                .map((state) => DropdownMenuItem(
                      value: state,
                      child: Text(state),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedState = value;
                _selectedCity = null;
                widget.onStateChanged(value != null
                    ? geographyState.geography
                        .firstWhere((item) =>
                            item.stateName == value &&
                            item.country == _selectedCountry)
                        .stateId
                    : null);
                widget.onCityChanged(null);
              });
            },
            validator: (value) => _address.isNotEmpty && value == null
                ? 'State is required'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'City Name',
              border: OutlineInputBorder(),
            ),
            value: _selectedCity != null && cities.contains(_selectedCity)
                ? _selectedCity
                : null,
            items: cities
                .map((city) => DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
                widget.onCityChanged(value != null
                    ? geographyNotifier.getCityId(
                        _selectedCountry, _selectedState, '', value)
                    : null);
              });
            },
            validator: (value) => _address.isNotEmpty && value == null
                ? 'City is required'
                : null,
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, String initialValue, Function(String) onChanged,
      {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: onChanged,
            validator: (value) => isRequired && (value == null || value.isEmpty)
                ? '$label is required'
                : null,
          ),
        ],
      ),
    );
  }
}

class SchoolDetailsPopup extends ConsumerStatefulWidget {
  final String primaryContact;
  final String contactStatus;
  final Function(String) onPrimaryContactChanged;
  final Function(String) onContactStatusChanged;

  const SchoolDetailsPopup({
    required this.primaryContact,
    required this.contactStatus,
    required this.onPrimaryContactChanged,
    required this.onContactStatusChanged,
  });

  @override
  _SchoolDetailsPopupState createState() => _SchoolDetailsPopupState();
}

class _SchoolDetailsPopupState extends ConsumerState<SchoolDetailsPopup> {
  late String _primaryContact;
  late String _contactStatus;
  String? _selectedBoard;
  String? _selectedChainSchool;
  String? _selectedStartClass;
  String? _selectedEndClass;
  String? _selectedMedium = 'English';
  String? _selectedRanking = 'A';
  String? _selectedPurchaseMode;
  String? _selectedSamplingMonth;
  String? _selectedDecisionMonth;
  String? _selectedKeyCustomer = 'Yes';
  String _panNumber = '';
  String _gstNumber = '';
  String? _selectedAccountableExecutive;
  List<Map<String, dynamic>> _selectedBookSellers =
      []; // Store selected book sellers

  @override
  void initState() {
    super.initState();
    _primaryContact = widget.primaryContact;
    _contactStatus = widget.contactStatus;
    _selectedPurchaseMode = 'Book Seller'; // Default to trigger the section
  }

  void _showBookSellerSearchPopup() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: BookSellerSearchPopup(
          onBookSellerSelected: (bookSeller) {
            setState(() {
              _selectedBookSellers.add(bookSeller);
            });
          },
          onSubmit: () {
            Navigator.pop(context); // Close only BookSellerSearchPopup
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerEntryState = ref.watch(customerEntryMasterProvider);

    if (customerEntryState.isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (customerEntryState.error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text('Error: ${customerEntryState.error}')),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('School Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Board *',
              border: OutlineInputBorder(),
            ),
            value: _selectedBoard,
            items: customerEntryState.boards
                .map((board) => DropdownMenuItem(
                      value: board.boardName,
                      child: Text(board.boardName),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedBoard = value),
            validator: (value) => value == null ? 'Board is required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Chain School',
              border: OutlineInputBorder(),
            ),
            value: _selectedChainSchool,
            items: customerEntryState.chainSchools
                .map((chain) => DropdownMenuItem(
                      value: chain.chainSchoolName,
                      child: Text(chain.chainSchoolName),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedChainSchool = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Start Class *',
              border: OutlineInputBorder(),
            ),
            value: _selectedStartClass,
            items: customerEntryState.classes
                .map((classItem) => DropdownMenuItem(
                      value: classItem.className,
                      child: Text(classItem.className),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedStartClass = value),
            validator: (value) =>
                value == null ? 'Start Class is required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'End Class *',
              border: OutlineInputBorder(),
            ),
            value: _selectedEndClass,
            items: customerEntryState.classes
                .map((classItem) => DropdownMenuItem(
                      value: classItem.className,
                      child: Text(classItem.className),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedEndClass = value),
            validator: (value) =>
                value == null ? 'End Class is required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Medium *',
              border: OutlineInputBorder(),
            ),
            value: _selectedMedium,
            items: ['English', 'Hindi', 'Regional']
                .map((medium) => DropdownMenuItem(
                      value: medium,
                      child: Text(medium),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedMedium = value),
            validator: (value) => value == null ? 'Medium is required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Ranking *',
              border: OutlineInputBorder(),
            ),
            value: _selectedRanking,
            items: ['A', 'B', 'C']
                .map((rank) => DropdownMenuItem(
                      value: rank,
                      child: Text(rank),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedRanking = value),
            validator: (value) => value == null ? 'Ranking is required' : null,
          ),
          const SizedBox(height: 16),
          _buildRadioGroup(
            'Purchase Mode *',
            customerEntryState.purchaseModes
                .map((mode) => mode.modeName)
                .toList(),
            _selectedPurchaseMode ??
                customerEntryState.purchaseModes.first.modeName,
            (value) => setState(() => _selectedPurchaseMode = value),
          ),
          if (_selectedPurchaseMode == 'Book Seller') ...[
            const SizedBox(height: 16),
            const Text(
              'BOOK SELLER',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_selectedBookSellers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTable(
                  columnSpacing: 12.0,
                  columns: const [
                    DataColumn(label: Text('S.No')),
                    DataColumn(label: Text('Book Seller Name')),
                    DataColumn(label: Text('Address')),
                    DataColumn(label: Text('City')),
                    DataColumn(label: Text('State')),
                    DataColumn(label: Text('Country')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: _selectedBookSellers.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final bookSeller = entry.value;
                    return DataRow(cells: [
                      DataCell(Text('$index')),
                      DataCell(Text(bookSeller['BookSellerName'])),
                      DataCell(Text(bookSeller['Address'])),
                      DataCell(Text(bookSeller['City'])),
                      DataCell(Text(bookSeller['State'])),
                      DataCell(Text(bookSeller['Country'])),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                _selectedBookSellers.removeAt(index - 1);
                              });
                            },
                          ),
                          const Icon(Icons.check, color: Colors.blue),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _showBookSellerSearchPopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Add Book Seller',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Sampling Month *',
              border: OutlineInputBorder(),
            ),
            value: _selectedSamplingMonth,
            items: customerEntryState.months
                .map((month) => DropdownMenuItem(
                      value: month.name,
                      child: Text(month.name),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedSamplingMonth = value),
            validator: (value) =>
                value == null ? 'Sampling Month is required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Decision Month *',
              border: OutlineInputBorder(),
            ),
            value: _selectedDecisionMonth,
            items: customerEntryState.months
                .map((month) => DropdownMenuItem(
                      value: month.name,
                      child: Text(month.name),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedDecisionMonth = value),
            validator: (value) =>
                value == null ? 'Decision Month is required' : null,
          ),
          const SizedBox(height: 16),
          _buildRadioGroup(
            'Key Customer *',
            ['Yes', 'No'],
            _selectedKeyCustomer!,
            (value) => setState(() => _selectedKeyCustomer = value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
              'PAN Number', _panNumber, (value) => _panNumber = value),
          const SizedBox(height: 16),
          _buildTextField(
              'GST Number', _gstNumber, (value) => _gstNumber = value),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Accountable Executive',
              border: OutlineInputBorder(),
            ),
            value: _selectedAccountableExecutive,
            items: customerEntryState.accountableExecutives
                .map((executive) => DropdownMenuItem(
                      value: executive.executiveName,
                      child: Text(executive.executiveName),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedAccountableExecutive = value),
          ),
          const SizedBox(height: 16),
          _buildRadioGroup('Primary Contact *', ['Y', 'N'], _primaryContact,
              (value) {
            setState(() => _primaryContact = value!);
            widget.onPrimaryContactChanged(value!);
          }),
          const SizedBox(height: 16),
          _buildRadioGroup(
              'Contact Status *', ['Active', 'Inactive'], _contactStatus,
              (value) {
            setState(() => _contactStatus = value!);
            widget.onContactStatusChanged(value!);
          }),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, String initialValue, Function(String) onChanged,
      {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
          validator: (value) => isRequired && (value == null || value.isEmpty)
              ? '$label is required'
              : null,
        ),
      ],
    );
  }

  Widget _buildRadioGroup(String label, List<String> options,
      String selectedValue, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            return Row(
              children: [
                Radio<String>(
                  value: option,
                  groupValue: selectedValue,
                  onChanged: onChanged,
                ),
                Text(option),
                const SizedBox(width: 16),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class BookSellerSearchPopup extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onBookSellerSelected;
  final VoidCallback onSubmit;

  const BookSellerSearchPopup({
    required this.onBookSellerSelected,
    required this.onSubmit,
  });

  @override
  _BookSellerSearchPopupState createState() => _BookSellerSearchPopupState();
}

class _BookSellerSearchPopupState extends ConsumerState<BookSellerSearchPopup> {
  String _bookSellerName = '';
  String _bookSellerCode = '';
  int? _selectedCountryId;
  String? _selectedCountry;
  int? _selectedStateId;
  String? _selectedState;
  int? _selectedDistrictId;
  String? _selectedDistrict;
  int? _selectedCityId;
  String? _selectedCity;
  int? _selectedRegionId;
  String? _selectedRegion;
  int? _selectedAreaId;
  String? _selectedArea;
  int? _selectedTerritoryId;
  String? _selectedTerritory;
  List<Map<String, dynamic>> _bookSellers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchBookSellers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = BookSellerRequest(
        bookSellerName: _bookSellerName.trim(),
        bookSellerCode: _bookSellerCode.trim(),
        cityId: _selectedCityId,
        regionId: _selectedRegionId?.toString(),
        areaId: _selectedAreaId?.toString(),
        territoryId: _selectedTerritoryId?.toString(),
        loggedInExecutiveId: AppUtils.getExecutiveStr(),
        downHierarchy: AppUtils.getDownStr(),
        territoryAccess: AppUtils.getTerritoryAccess(),
      );
      final rows = await ApiService().bookSellerSearchAPI(request) ?? const [];
      if (!mounted) return;
      setState(() {
        _bookSellers = rows
            .map((seller) => <String, dynamic>{
                  'BookSellerName': seller.bookSellerName ?? '',
                  'Address': seller.address ?? '',
                  'City': seller.city ?? '',
                  'State': seller.state ?? '',
                  'Country': seller.country ?? '',
                  'Action': seller.action ?? 0,
                })
            .where((seller) => (seller['Action'] as int) > 0)
            .toList();
        _error = _bookSellers.isEmpty ? 'No book sellers found' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = CrmApiClient.messageFrom(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final geographyState = ref.watch(geographyProvider);
    final geographyNotifier = ref.read(geographyProvider.notifier);

    if (geographyState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final countries = geographyNotifier.getCountries();
    final states = geographyNotifier.getStates(
        _selectedCountry ?? (countries.isNotEmpty ? countries.first : ''));
    final cities =
        geographyNotifier.getCities(_selectedCountry ?? '', _selectedState);
    final districts =
        geographyNotifier.getDistricts(_selectedCountry ?? '', _selectedState);

    final regions = ['Region 1', 'Region 2', 'Region 3'];
    final areas = ['Area 1', 'Area 2', 'Area 3'];
    final territories = ['Territory 1', 'Territory 2', 'Territory 3'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.orange,
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search Book Seller',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField('Book Seller Name', _bookSellerName,
                      (value) => setState(() => _bookSellerName = value)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField('Book Seller Code', _bookSellerCode,
                      (value) => setState(() => _bookSellerCode = value)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Geographical Structure',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Country Name',
                      border: InputBorder.none,
                    ),
                    value: _selectedCountry,
                    items: countries.map((country) {
                      final countryId = geographyState.geography
                          .firstWhere((item) => item.country == country,
                              orElse: () => GeographyItem(
                                    countryId: 0,
                                    country: '',
                                    stateId: 0,
                                    stateName: '',
                                    districtId: 0,
                                    district: '',
                                    cityId: 0,
                                    city: '',
                                  ))
                          .countryId;
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedCountry = value;
                      _selectedCountryId = geographyState.geography
                          .firstWhere((item) => item.country == value,
                              orElse: () => GeographyItem(
                                    countryId: 0,
                                    country: '',
                                    stateId: 0,
                                    stateName: '',
                                    districtId: 0,
                                    district: '',
                                    cityId: 0,
                                    city: '',
                                  ))
                          .countryId;
                      _selectedState = null;
                      _selectedStateId = null;
                      _selectedDistrict = null;
                      _selectedDistrictId = null;
                      _selectedCity = null;
                      _selectedCityId = null;
                    }),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'State Name',
                      border: InputBorder.none,
                    ),
                    value: _selectedState,
                    items: states.map((state) {
                      final stateId = geographyState.geography
                          .firstWhere(
                              (item) =>
                                  item.stateName == state &&
                                  item.country == (_selectedCountry ?? ''),
                              orElse: () => GeographyItem(
                                    countryId: 0,
                                    country: '',
                                    stateId: 0,
                                    stateName: '',
                                    districtId: 0,
                                    district: '',
                                    cityId: 0,
                                    city: '',
                                  ))
                          .stateId;
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedState = value;
                      _selectedStateId = geographyState.geography
                          .firstWhere(
                              (item) =>
                                  item.stateName == value &&
                                  item.country == (_selectedCountry ?? ''),
                              orElse: () => GeographyItem(
                                    countryId: 0,
                                    country: '',
                                    stateId: 0,
                                    stateName: '',
                                    districtId: 0,
                                    district: '',
                                    cityId: 0,
                                    city: '',
                                  ))
                          .stateId;
                      _selectedDistrict = null;
                      _selectedDistrictId = null;
                      _selectedCity = null;
                      _selectedCityId = null;
                    }),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'District Name',
                      border: InputBorder.none,
                    ),
                    value: _selectedDistrict,
                    items: districts.map((district) {
                      final districtId = geographyState.geography
                          .firstWhere(
                              (item) =>
                                  item.district == district &&
                                  item.stateName == (_selectedState ?? ''),
                              orElse: () => GeographyItem(
                                    countryId: 0,
                                    country: '',
                                    stateId: 0,
                                    stateName: '',
                                    districtId: 0,
                                    district: '',
                                    cityId: 0,
                                    city: '',
                                  ))
                          .districtId;
                      return DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedDistrict = value;
                      _selectedDistrictId = geographyState.geography
                          .firstWhere(
                              (item) =>
                                  item.district == value &&
                                  item.stateName == (_selectedState ?? ''),
                              orElse: () => GeographyItem(
                                    countryId: 0,
                                    country: '',
                                    stateId: 0,
                                    stateName: '',
                                    districtId: 0,
                                    district: '',
                                    cityId: 0,
                                    city: '',
                                  ))
                          .districtId;
                      _selectedCity = null;
                      _selectedCityId = null;
                    }),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'City Name',
                      border: InputBorder.none,
                    ),
                    value: _selectedCity,
                    items: cities.map((city) {
                      final cityId = geographyState.geography
                          .firstWhere(
                              (item) =>
                                  item.city == city &&
                                  item.district == (_selectedDistrict ?? ''),
                              orElse: () => GeographyItem(
                                    countryId: 0,
                                    country: '',
                                    stateId: 0,
                                    stateName: '',
                                    districtId: 0,
                                    district: '',
                                    cityId: 0,
                                    city: '',
                                  ))
                          .cityId;
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedCity = value;
                      _selectedCityId = geographyState.geography
                          .firstWhere(
                              (item) =>
                                  item.city == value &&
                                  item.district == (_selectedDistrict ?? ''),
                              orElse: () => GeographyItem(
                                    countryId: 0,
                                    country: '',
                                    stateId: 0,
                                    stateName: '',
                                    districtId: 0,
                                    district: '',
                                    cityId: 0,
                                    city: '',
                                  ))
                          .cityId;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Organizational Structure',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Region Name',
                      border: InputBorder.none,
                    ),
                    value: _selectedRegion,
                    items: regions.map((region) {
                      final regionId = regions.indexOf(region) + 1;
                      return DropdownMenuItem<String>(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedRegion = value;
                      _selectedRegionId = regions.indexOf(value!) + 1;
                    }),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Area Name',
                      border: InputBorder.none,
                    ),
                    value: _selectedArea,
                    items: areas.map((area) {
                      final areaId = areas.indexOf(area) + 1;
                      return DropdownMenuItem<String>(
                        value: area,
                        child: Text(area),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedArea = value;
                      _selectedAreaId = areas.indexOf(value!) + 1;
                    }),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Territory Name',
                      border: InputBorder.none,
                    ),
                    value: _selectedTerritory,
                    items: territories.map((territory) {
                      final territoryId = territories.indexOf(territory) + 1;
                      return DropdownMenuItem<String>(
                        value: territory,
                        child: Text(territory),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedTerritory = value;
                      _selectedTerritoryId = territories.indexOf(value!) + 1;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchBookSellers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child:
                  const Text('Search', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
            else if (_bookSellers.isEmpty)
              const Center(child: Text('No book sellers found'))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book Sellers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _bookSellers.length,
                    itemBuilder: (context, index) {
                      final bookSeller = _bookSellers[index];
                      return ListTile(
                        title: Text(bookSeller['BookSellerName']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bookSeller['Address']),
                            Text(bookSeller['City']),
                            Text(
                                '${bookSeller['State']}, ${bookSeller['Country']}'),
                          ],
                        ),
                        onTap: () {
                          widget.onBookSellerSelected(bookSeller);
                        },
                      );
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: widget.onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child:
                    const Text('Submit', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String initialValue, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class EnrollmentPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enrollment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField('Total Enrollment', '0', (_) {},
              placeholder: 'No data available - API pending'),
          const SizedBox(height: 16),
          Center(
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'))),
        ],
      ),
    );
  }
}

class TeachersPopup extends ConsumerStatefulWidget {
  final int? customerContactId; // Added to pass CustomerContactId

  const TeachersPopup({this.customerContactId});

  @override
  _TeachersPopupState createState() => _TeachersPopupState();
}

class _TeachersPopupState extends ConsumerState<TeachersPopup> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContactDetails();
  }

  Future<void> _fetchContactDetails() async {
    if (widget.customerContactId == null) {
      setState(() {
        _error = 'No CustomerContactId provided';
        _isLoading = false;
      });
      return;
    }

    final authState = ref.read(authProvider);
    final token = authState.token;
    if (token == null) {
      setState(() {
        _error = 'Please log in first';
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final requestBody = {
      'Validated': 'T',
      'CustomerType': 'School', // Adjust if teacher-specific type is needed
      'CustomerContactId': widget.customerContactId,
    };

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/FetchCustomerContactDetails'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Status'] == 'Success' &&
            data['SchoolContactDetails'] != null &&
            data['SchoolContactDetails'].isNotEmpty) {
          setState(() {
            _contacts =
                List<Map<String, dynamic>>.from(data['SchoolContactDetails']);
            _error = null;
          });
        } else {
          setState(() {
            _contacts = [];
            _error = 'No contact details found';
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch contact details: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching contact details: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddNewTeacherPopup() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: AddNewTeacherPopup(customerContactId: widget.customerContactId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('List of Contacts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: _showAddNewTeacherPopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Add New Teacher',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
          else if (_contacts.isEmpty)
            const Center(child: Text('No contacts found'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return ListTile(
                  title: Text('${contact['FirstName']} ${contact['LastName']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${contact['ContactEmailId'] ?? 'N/A'}'),
                      Text('Mobile: ${contact['ContactMobile'] ?? 'N/A'}'),
                      Text('Address: ${contact['resAddress'] ?? 'N/A'}'),
                      Text('Status: ${contact['ContactStatus']}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _showAddNewTeacherPopup(); // Open edit mode with this contact's ID
                    },
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class AddNewTeacherPopup extends ConsumerStatefulWidget {
  final int? customerContactId; // Added to pass CustomerContactId for edit

  const AddNewTeacherPopup({this.customerContactId});

  @override
  _AddNewTeacherPopupState createState() => _AddNewTeacherPopupState();
}

class _AddNewTeacherPopupState extends ConsumerState<AddNewTeacherPopup> {
  final _formKey = GlobalKey<FormState>(); // Added for validation
  String? _salutationId;
  String? _firstName;
  String? _lastName;
  String? _contactDesignationId;
  String? _contactEmailId;
  String? _contactMobile;
  String? _address;
  String? _pincode;
  String? _country;
  String? _state;
  String? _district;
  String? _city;
  String? _dataSource;
  String? _birthDay;
  String? _anniversary;
  String? _primaryContact = 'No'; // Default to No
  String? _contactStatus = 'Active'; // Default to Active
  String? _teacherClassName;
  String? _subjectName;
  bool _isLoading = false;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerContactId != null) {
      _fetchContactDetails();
    }
  }

  Future<void> _fetchContactDetails() async {
    final authState = ref.read(authProvider);
    final token = authState.token;
    if (token == null) {
      setState(() {
        _error = 'Please log in first';
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final requestBody = {
      'Validated': 'T',
      'CustomerType': 'School',
      'CustomerContactId': widget.customerContactId,
    };

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/FetchCustomerContactDetails'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Status'] == 'Success' &&
            data['SchoolContactDetails'] != null &&
            data['SchoolContactDetails'].isNotEmpty) {
          final contact = data['SchoolContactDetails'][0];
          setState(() {
            _salutationId = contact['SalutationId']?.toString();
            _firstName = contact['FirstName'];
            _lastName = contact['LastName'];
            _contactDesignationId = contact['ContactDesignationId']?.toString();
            _contactEmailId = contact['ContactEmailId'];
            _contactMobile = contact['ContactMobile'];
            _address = contact['resAddress'];
            _pincode = contact['resPincode'];
            _country = contact['Country'];
            _state = contact['State'];
            _district = contact['District'];
            _city = contact['City'];
            _dataSource = contact['DataSource'];
            _birthDay = contact['BirthDay'];
            _anniversary = contact['Anniversary'];
            _primaryContact = contact['PrimaryContact'] ?? 'No';
            _contactStatus = contact['ContactStatus'] ?? 'Active';
            _error = null;
          });
        } else {
          setState(() {
            _error = 'No contact details found';
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch contact details: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching contact details: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authState = ref.read(authProvider);
    final token = authState.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final requestBody = {
      'CustomerType': 'School',
      'PrimaryContact': _primaryContact,
      'SalutationId': _salutationId,
      'FirstName': _firstName,
      'LastName': _lastName,
      'ContactDesignationId': _contactDesignationId,
      'ContactEmailId': _contactEmailId,
      'ContactMobile': _contactMobile,
      'ContactStatus': _contactStatus,
      'EnteredBy': 8,
      'CustomerId': '', // Replace with actual CustomerId
      'Validated': 'A',
      'CustomerContactId': widget.customerContactId?.toString(),
      'resAddress': _address,
      'resPincode': _pincode,
      'Country': _country,
      'State': _state,
      'District': _district,
      'City': _city,
      'DataSourceId': _dataSource,
      'BirthDay': _birthDay,
      'Anniversary': _anniversary,
      'xmlSubjectClassDM': _subjectName != null && _teacherClassName != null
          ? '<SubjectClass><SubjectName>$_subjectName</SubjectName><ClassName>$_teacherClassName</ClassName></SubjectClass>'
          : '',
    };

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/ContactEntryorUpdateAPI'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['Status'] == 'Success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['s'])),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed: ${responseData['s'] ?? 'HTTP ${response.statusCode}'}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerEntryState = ref.watch(customerEntryMasterProvider);
    final geographyState = ref.watch(geographyProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add New Teacher',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(
                      child: Text(_error!, style: TextStyle(color: Colors.red)))
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRadioGroup(
                              'Primary Contact *',
                              ['Yes', 'No'],
                              _primaryContact ?? 'No',
                              (value) =>
                                  setState(() => _primaryContact = value),
                            ),
                            _buildRadioGroup(
                              'Contact Status *',
                              ['Active', 'Inactive'],
                              _contactStatus ?? 'Active',
                              (value) => setState(() => _contactStatus = value),
                            ),
                            _buildDropdownField(
                              'Salutation',
                              _salutationId,
                              (value) => setState(() => _salutationId = value),
                              items: customerEntryState.salutations
                                  .map((sal) => DropdownMenuItem(
                                        value: sal.salutationId.toString(),
                                        child: Text(sal.salutationName),
                                      ))
                                  .toList(),
                            ),
                            _buildTextField(
                              'First Name *',
                              _firstName ?? '',
                              (value) => setState(() => _firstName = value),
                              isRequired: true,
                            ),
                            _buildTextField(
                              'Last Name',
                              _lastName ?? '',
                              (value) => setState(() => _lastName = value),
                            ),
                            // _buildDropdownField(
                            //   'Designation *',
                            //   _contactDesignationId,
                            //   (value) =>
                            //       setState(() => _contactDesignationId = value),
                            //   items: customerEntryState.designations
                            //       .map((des) => DropdownMenuItem(
                            //             value: des.designationId.toString(),
                            //             child: Text(des.designationName),
                            //           ))
                            //       .toList(),
                            //   isRequired: true,
                            // ),b
                            _buildTextField(
                              'Email Id *',
                              _contactEmailId ?? '',
                              (value) =>
                                  setState(() => _contactEmailId = value),
                              isRequired: true,
                            ),
                            _buildTextField(
                              'Mobile Number',
                              _contactMobile ?? '',
                              (value) => setState(() => _contactMobile = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              'Address',
                              _address ?? '',
                              (value) => setState(() => _address = value),
                            ),
                            _buildTextField(
                              'Pincode',
                              _pincode ?? '',
                              (value) => setState(() => _pincode = value),
                            ),
                            _buildDropdownField(
                              'Country',
                              _country,
                              (value) => setState(() => _country = value),
                              items: geographyState.geography
                                  .map((geo) => DropdownMenuItem(
                                        value: geo.country,
                                        child: Text(geo.country),
                                      ))
                                  .toList(),
                            ),
                            _buildDropdownField(
                              'State',
                              _state,
                              (value) => setState(() => _state = value),
                              items: geographyState.geography
                                  .where((geo) => geo.country == _country)
                                  .map((geo) => DropdownMenuItem(
                                        value: geo.stateName,
                                        child: Text(geo.stateName),
                                      ))
                                  .toList(),
                            ),
                            _buildDropdownField(
                              'District',
                              _district,
                              (value) => setState(() => _district = value),
                              items: geographyState.geography
                                  .where((geo) => geo.stateName == _state)
                                  .map((geo) => DropdownMenuItem(
                                        value: geo.district,
                                        child: Text(geo.district),
                                      ))
                                  .toList(),
                            ),
                            _buildDropdownField(
                              'City',
                              _city,
                              (value) => setState(() => _city = value),
                              items: geographyState.geography
                                  .where((geo) => geo.district == _district)
                                  .map((geo) => DropdownMenuItem(
                                        value: geo.city,
                                        child: Text(geo.city),
                                      ))
                                  .toList(),
                            ),
                            _buildDropdownField(
                              'Data Source',
                              _dataSource,
                              (value) => setState(() => _dataSource = value),
                              items: customerEntryState.dataSources
                                  .map((ds) => DropdownMenuItem(
                                        value: ds.dataSourceName,
                                        child: Text(ds.dataSourceName),
                                      ))
                                  .toList(),
                            ),
                            _buildTextField(
                              'Birth Day',
                              _birthDay ?? '',
                              (value) => setState(() => _birthDay = value),
                            ),
                            _buildTextField(
                              'Anniversary',
                              _anniversary ?? '',
                              (value) => setState(() => _anniversary = value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          'Subject Name',
                          _subjectName,
                          (value) => setState(() => _subjectName = value),
                          items: customerEntryState.subjects
                              .map((sub) => DropdownMenuItem(
                                    value: sub.subjectName,
                                    child: Text(sub.subjectName),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'Class Name',
                          _teacherClassName ?? '',
                          (value) => setState(() => _teacherClassName = value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.yellow[100],
                          child: const Center(child: Text('DECISION MAKER')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.yellow[100],
                          child: const Center(child: Text('ACTION')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitTeacher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String initialValue, Function(String) onChanged,
      {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: initialValue,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onChanged: onChanged,
            validator: (value) => isRequired && (value == null || value.isEmpty)
                ? '$label is required'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? initialValue,
    Function(String?) onChanged, {
    List<DropdownMenuItem<String>>? items,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: initialValue,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            items: items ?? [],
            onChanged: onChanged,
            validator: (value) =>
                isRequired && value == null ? '$label is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioGroup(String label, List<String> options,
      String selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: options.map((option) {
              return Row(
                children: [
                  Radio<String>(
                    value: option,
                    groupValue: selectedValue,
                    onChanged: onChanged,
                  ),
                  Text(option, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class SchoolFacilityPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('School Facility',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCheckbox('WiFi', false, (_) {},
              placeholder: 'No data available - API pending'),
          _buildCheckbox('Working Computers', false, (_) {},
              placeholder: 'No data available - API pending'),
          _buildCheckbox('Projector', false, (_) {},
              placeholder: 'No data available - API pending'),
          const SizedBox(height: 16),
          Center(
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'))),
        ],
      ),
    );
  }
}

class NotesCommentsPopup extends StatelessWidget {
  final String birthDay;
  final String anniversary;
  final String xmlSubjectClassDM;
  final String customerType;
  final Function(String) onBirthDayChanged;
  final Function(String) onAnniversaryChanged;
  final Function(String) onXmlSubjectClassDMChanged;

  const NotesCommentsPopup({
    required this.birthDay,
    required this.anniversary,
    required this.xmlSubjectClassDM,
    required this.customerType,
    required this.onBirthDayChanged,
    required this.onAnniversaryChanged,
    required this.onXmlSubjectClassDMChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notes/Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField('Comments', '', (_) {},
              placeholder: 'No data available - API pending'),
          _buildTextField('Birth Day', birthDay, onBirthDayChanged),
          _buildTextField('Anniversary', anniversary, onAnniversaryChanged),
          if (customerType == 'School' || customerType == 'Library')
            _buildTextField('XML Subject Class DM', xmlSubjectClassDM,
                onXmlSubjectClassDMChanged),
          const SizedBox(height: 16),
          Center(
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'))),
        ],
      ),
    );
  }
}

// Reusable Widgets
Widget _buildTextField(
    String label, String initialValue, Function(String) onChanged,
    {bool isRequired = false, String? placeholder}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: placeholder ?? label,
          ),
          onChanged: onChanged,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    ),
  );
}

Widget _buildDropdownField(
    String label, String? initialValue, Function(String?) onChanged,
    {List<DropdownMenuItem<String>>? items, String? placeholder}) {
  return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: initialValue,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items ?? // Use provided items or fallback to placeholder
                [
                  DropdownMenuItem<String>(
                    value: placeholder,
                    child: Text(placeholder ?? ''),
                  )
                ],
            onChanged: onChanged,
            validator: (value) => value == null ? '$label is required' : null,
          ),
        ],
      ));
}

Widget _buildRadioGroup(String label, List<String> options,
    String selectedValue, ValueChanged<String?> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            return Row(
              children: [
                Radio<String>(
                  value: option,
                  groupValue: selectedValue,
                  onChanged: onChanged,
                ),
                Text(option),
                const SizedBox(width: 16),
              ],
            );
          }).toList(),
        ),
      ],
    ),
  );
}

Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged,
    {String? placeholder}) {
  return Row(
    children: [
      Checkbox(value: value, onChanged: onChanged),
      Text(placeholder ?? title),
    ],
  );
}
