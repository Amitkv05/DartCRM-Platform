import 'package:dart_crm/providers/customerProvider/customer_data_provider.dart';
import 'package:dart_crm/providers/geography_provider.dart';
import 'package:dart_crm/screens/customer/customerCreationScreen/widget/school_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class CustomerCreation extends ConsumerStatefulWidget {
  final int? customerId;
  final String? initialCustomerType;

  const CustomerCreation({
    super.key,
    this.customerId,
    this.initialCustomerType,
  });

  @override
  ConsumerState<CustomerCreation> createState() => _CustomerCreationState();
}

class _CustomerCreationState extends ConsumerState<CustomerCreation> {
  final _formKey = GlobalKey<FormState>();
  String? customerType;
  String customerName = '';
  String refCode = '';
  String address = '';
  String? selectedCountry;
  String? selectedStateName; // Renamed from selectedState
  String? selectedDistrict;
  String? selectedCity;
  String pincode = '';
  String emailId = '';
  String mobile = '';
  String latEntry = '';
  String longEntry = '';

  @override
  void initState() {
    super.initState();
    customerType = widget.initialCustomerType;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location permissions permanently denied')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        latEntry = position.latitude.toString();
        longEntry = position.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _submitCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final cityId = ref.read(geographyProvider.notifier).getCityId(
          selectedCountry,
          selectedStateName, // Updated to selectedStateName
          selectedDistrict,
          selectedCity,
        );

    final customerDetails = {
      'customerId': widget.customerId,
      'customerType': customerType!,
      'customerName': customerName,
      'refCode': refCode.isNotEmpty ? refCode : null,
      'address': address,
      'cityId': cityId,
      'pincode': pincode,
      'latEntry': latEntry,
      'longEntry': longEntry,
      'emailId': emailId.isNotEmpty ? emailId : null,
      'mobile': mobile.isNotEmpty ? mobile : null,
    };

    ref.read(customerDataProvider.notifier).update(
          (state) => state.copyWith(customerDetails: customerDetails),
        );

    if (customerType == 'School') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SchoolDetailsScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.customerId == null
              ? 'Customer created successfully'
              : 'Customer updated successfully'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerData = ref.watch(customerDataProvider);
    final geography = ref.watch(geographyProvider);
    final geographyNotifier = ref.watch(geographyProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.customerId == null
              ? "New Customer - $customerType"
              : "Update Customer",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (customerData.customerDetails.isNotEmpty &&
              widget.customerId != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Previous Customer Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                      'Name: ${customerData.customerDetails['customerName'] ?? 'N/A'}'),
                  Text(
                      'Type: ${customerData.customerDetails['customerType'] ?? 'N/A'}'),
                  Text(
                      'Address: ${customerData.customerDetails['address'] ?? 'N/A'}'),
                  Text(
                      'Ref Code: ${customerData.customerDetails['refCode'] ?? 'N/A'}'),
                  Text(
                      'City ID: ${customerData.customerDetails['cityId'] ?? 'N/A'}'),
                  Text(
                      'Pincode: ${customerData.customerDetails['pincode'] ?? 'N/A'}'),
                  Text(
                      'Email: ${customerData.customerDetails['emailId'] ?? 'N/A'}'),
                  Text(
                      'Mobile: ${customerData.customerDetails['mobile'] ?? 'N/A'}'),
                  Text(
                      'Latitude: ${customerData.customerDetails['latEntry'] ?? 'N/A'}'),
                  Text(
                      'Longitude: ${customerData.customerDetails['longEntry'] ?? 'N/A'}'),
                ],
              ),
            ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.05,
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          title: "Customer Details",
                          icon: Icons.person,
                          screenWidth: screenWidth,
                        ),
                        _buildDropdownField(
                          label: "Customer Type *",
                          value: customerType,
                          items: ['School', 'Trade', 'Library'],
                          onChanged: (value) =>
                              setState(() => customerType = value),
                          validator: (value) =>
                              value == null ? 'Required' : null,
                          screenWidth: screenWidth,
                        ),
                        _buildTextField(
                          label: "Customer Name *",
                          onChanged: (value) => customerName = value,
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                          screenWidth: screenWidth,
                        ),
                        _buildTextField(
                          label: "Reference Code",
                          onChanged: (value) => refCode = value,
                          screenWidth: screenWidth,
                        ),
                        _buildSectionHeader(
                          title: "Location",
                          icon: Icons.location_on,
                          screenWidth: screenWidth,
                        ),
                        _buildTextField(
                          label: "Address *",
                          onChanged: (value) => address = value,
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                          screenWidth: screenWidth,
                        ),
                        _buildDropdownField(
                          label: "Country *",
                          value: selectedCountry,
                          items: geography.isLoading
                              ? ['Loading countries...']
                              : geography.error != null
                                  ? ['Error: ${geography.error}']
                                  : geography.geography.isEmpty
                                      ? ['No countries available']
                                      : geographyNotifier.getCountries(),
                          onChanged:
                              geography.isLoading || geography.error != null
                                  ? null
                                  : (value) {
                                      setState(() {
                                        selectedCountry = value;
                                        selectedStateName = null; // Updated
                                        selectedDistrict = null;
                                        selectedCity = null;
                                      });
                                    },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                          screenWidth: screenWidth,
                        ),
                        _buildDropdownField(
                          label: "State *",
                          value: selectedStateName, // Updated
                          items: geography.isLoading
                              ? ['Loading states...']
                              : geography.error != null
                                  ? ['Error: ${geography.error}']
                                  : selectedCountry == null
                                      ? ['Select a country first']
                                      : geographyNotifier
                                          .getStates(selectedCountry),
                          onChanged: geography.isLoading ||
                                  geography.error != null ||
                                  selectedCountry == null
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedStateName = value; // Updated
                                    selectedDistrict = null;
                                    selectedCity = null;
                                  });
                                },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                          screenWidth: screenWidth,
                        ),
                        _buildDropdownField(
                          label: "District *",
                          value: selectedDistrict,
                          items: geography.isLoading
                              ? ['Loading districts...']
                              : geography.error != null
                                  ? ['Error: ${geography.error}']
                                  : (selectedCountry == null ||
                                          selectedStateName == null) // Updated
                                      ? ['Select a state first']
                                      : geographyNotifier.getDistricts(
                                          selectedCountry,
                                          selectedStateName), // Updated
                          onChanged: geography.isLoading ||
                                  geography.error != null ||
                                  selectedCountry == null ||
                                  selectedStateName == null // Updated
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedDistrict = value;
                                    selectedCity = null;
                                  });
                                },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                          screenWidth: screenWidth,
                        ),
                        _buildDropdownField(
                          label: "City *",
                          value: selectedCity,
                          items: geography.isLoading
                              ? ['Loading cities...']
                              : geography.error != null
                                  ? ['Error: ${geography.error}']
                                  : (selectedCountry == null ||
                                          selectedStateName ==
                                              null || // Updated
                                          selectedDistrict == null)
                                      ? ['Select a district first']
                                      : geographyNotifier.getCities(
                                          selectedCountry,
                                          selectedStateName, // Updated
                                          selectedDistrict),
                          onChanged: geography.isLoading ||
                                  geography.error != null ||
                                  selectedCountry == null ||
                                  selectedStateName == null || // Updated
                                  selectedDistrict == null
                              ? null
                              : (value) => setState(() => selectedCity = value),
                          validator: (value) =>
                              value == null ? 'Required' : null,
                          screenWidth: screenWidth,
                        ),
                        if (geography.error != null)
                          Padding(
                            padding: EdgeInsets.only(top: screenWidth * 0.025),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Failed to load geography data. ',
                                  style: TextStyle(color: Colors.red),
                                ),
                                TextButton(
                                  onPressed: () => ref
                                      .read(geographyProvider.notifier)
                                      .fetchGeography(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        _buildTextField(
                          label: "Pincode *",
                          onChanged: (value) => pincode = value,
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                          screenWidth: screenWidth,
                        ),
                        _buildTextField(
                          label: "Email ID",
                          onChanged: (value) => emailId = value,
                          screenWidth: screenWidth,
                        ),
                        _buildTextField(
                          label: "Mobile",
                          onChanged: (value) => mobile = value,
                          screenWidth: screenWidth,
                        ),
                        SizedBox(height: screenWidth * 0.08),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitCustomer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  vertical: screenWidth * 0.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Next",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required double screenWidth,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: screenWidth * 0.03,
        horizontal: screenWidth * 0.04,
      ),
      margin: EdgeInsets.only(bottom: screenWidth * 0.025),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: screenWidth * 0.06),
          SizedBox(width: screenWidth * 0.025),
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    required double screenWidth,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.025),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.035,
          ),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
    String? Function(String?)? validator,
    required double screenWidth,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.025),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.035,
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.black87,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.grey,
          size: screenWidth * 0.07,
        ),
      ),
    );
  }
}
