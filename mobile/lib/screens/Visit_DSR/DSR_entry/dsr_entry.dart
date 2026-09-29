import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_crm/edit/api/repository/api_service.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/planList/dsr_entry_model.dart';
import 'package:dart_crm/models/planList/eProduct_details.dart';
import 'package:dart_crm/models/planList/eproduct_list.dart';
import 'package:dart_crm/models/planList/plan.dart';
import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/planList/dsr_sampling_details.dart'
    as dsrsampling;
import 'package:dart_crm/models/ship_to.dart';
import 'package:dart_crm/models/shipment_model.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/dsr_entry_provider.dart';
import 'package:dart_crm/screens/Visit_DSR/DSR_entry/widget/dsr_entry_widgets.dart';
import 'package:dart_crm/util/constants/userHeader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart' as xml;

import '../../../edit/utils/all_field_widget.dart';
import '../../../edit/utils/color_constants.dart';
import '../../../edit/utils/fill_button_widget.dart';
import '../../../edit/utils/widgetUtils.dart';
import '../../../models/planList/image/upload/UploadDocumentRequest.dart';
import '../../../models/planList/sampling_details.dart';
import '../../../util/constants/colors.dart';
import 'widget/sampling_widget.dart';

class DSREntryScreen extends ConsumerStatefulWidget {
  final Plan plan;

  const DSREntryScreen({super.key, required this.plan});

  @override
  ConsumerState<DSREntryScreen> createState() => _DSREntryScreenState();
}

class _DSREntryScreenState extends ConsumerState<DSREntryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Future<DSREntryResponse> _dsrEntryFuture;

  bool isSubmitting = false;
  bool isUploadingDocument = false;
  bool _hasLocation = false;

  // Form fields
  String? visitPurpose;
  String? jointVisitID;

  bool samplingDone = false;
  bool eProducts = false;
  bool followUpAction = false;
  TextEditingController visitDateController = TextEditingController();
  TextEditingController feedbackController = TextEditingController();

  dsrsampling.dsrSamplingDetailsResponse? samplingResponse;
  dsrsampling.dsrSeriesAndClassLevelResponse? classLevelResponse;
  int? selectedCustomerContactId;
  List<FollowUpAction> followUpActionsList = [];
  List<EProductData> productAddList = [];
  List<DocumentSaveData> documentSateData = [];

  int? selectAcademicSessionId;
  TextEditingController addressEntryController = TextEditingController();

  String? selectedDepartmentId;
  String? selectedExecutive;
  String? selectedExecutiveId;
  TextEditingController actionDateController = TextEditingController();
  TextEditingController actionTextController = TextEditingController();
  List<Executive> executives = [];
  bool isLoadingExecutives = false;

  // E-Products fields
  String? selectedBrandId;
  String? selectedBrandName;
  int? selectedProductId;
  String? selectedProductName;
  String? selectedClassId;
  String? selectedClassName;

  String? selectedCurrentSalesStage;
  String? selectProspect;
  String? previousSalesStage;
  TextEditingController eProductRemarkController = TextEditingController();
  EProductListResponse? productResponse;
  EProductDetailsResponse? productDetailsResponse;
  bool isLoadingEProducts = false;

  List<String> brandNames = [];
  List<BrandData>? brandList;
  List<VisitPurpose>? visitorPurpose;
  List<ProspectData>? prospectList;
  List<SaleStagData>? saleStagList;
  List<AllowedDateRange> allowedDateRanges = const [];

  ShipmentModeResponse? dsrShipmentModeResponse;
  String? selectedDsrShipmentModeId;
  bool isLoadingDsrShipmentModes = false;

  bool feedbackMandatory = false;
  int? feedbackMaxLength;

  bool samplingDoneVisible = true;
  bool eProductsVisible = true;
  bool followUpActionVisible = true;

  @override
  void initState() {
    sampleInSeries.clear();
    sampleNotInSeries.clear();
    AppUtils.loadSetUp();
    print('VVVVVV FROM_TODSR ${FROM_TODSR}');

    var feedback = AppUtils.filterSetup('VisitFeedbackMandatory');
    feedbackMandatory = feedback != null &&
        (feedback.keyValue.toLowerCase() == 'y' ||
            feedback.keyValue.toLowerCase() == 'yes');
    var feedbackMinChar = AppUtils.filterSetup('VisitFeedbackMinChar');
    feedbackMaxLength = int.tryParse(feedbackMinChar?.keyValue ?? '500');

    var sampling = AppUtils.filterSetup('VisitBooksSampling');
    samplingDoneVisible = sampling != null &&
        (sampling.keyValue.toLowerCase() == 'y' ||
            sampling.keyValue.toLowerCase() == 'yes');

    var eProducts = AppUtils.filterSetup('VisitEProducts');
    eProductsVisible = eProducts != null &&
        (eProducts.keyValue.toLowerCase() == 'y' ||
            eProducts.keyValue.toLowerCase() == 'yes');

    var followUpAction = AppUtils.filterSetup('DisplayFollowUpAction');
    followUpActionVisible = followUpAction != null &&
        (followUpAction.keyValue.toLowerCase() == 'y' ||
            followUpAction.keyValue.toLowerCase() == 'yes');

    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _fetchSamplingDetails();
    _fetchDsrShipmentModes();
    WidgetsBinding.instance.addPostFrameCallback((_) => getAddress());
    final authState = ref.read(authProvider);
    final token = authState.token ?? '';

    _dsrEntryFuture = ref
        .read(dsrEntryProvider.notifier)
        .getDSREntry(
          executiveId: AppUtils.getExecutiveStr(),
          customerType: widget.plan.customerType,
          customerId: widget.plan.customerId ?? 0,
          upHierarchy: AppUtils.getUpStr(),
          downHierarchy: AppUtils.getDownStr(),
          token: token,
        )
        .timeout(const Duration(seconds: 30), onTimeout: () {
      throw TimeoutException('Failed to load DSR entry data');
    });
    _fetchSeriesList();
  }

  Future<void> getAddress({bool showSettingsPrompt = true}) async {
    try {
      final pos = await _determinePosition(showSettingsPrompt: showSettingsPrompt);
      final address = await _getAddressFromLatLng(pos);
      if (!mounted) return;
      addressEntryController.text = address;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _fetchEProductList(String brandId) async {
    setState(() => isLoadingEProducts = true);
    final authState = ref.read(authProvider);
    final token = authState.token ?? '';
    final request =
        EProductListRequest(brandId: brandId); // Adjust if brandId is dynamic

    try {
      final response =
          await ref.read(dsrEntryProvider.notifier).getEProductListByBrand(
                request: request,
                token: token,
              );
      setState(() {
        productResponse = response;
        isLoadingEProducts = false;
      });
    } catch (e) {
      setState(() => isLoadingEProducts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading E-Products: $e')),
      );
    }
  }

  Future<void> _fetchEProductDetails(int eProductId) async {
    setState(() => isLoadingEProducts = true);
    final authState = ref.read(authProvider);
    final token = authState.token ?? '';
    final request = EProductDetailsRequest(
      eProductId: eProductId.toString(),
      academicSessionId: (selectAcademicSessionId ?? 1).toString(),
      customerId: (widget.plan.customerId ?? 0).toString(),
    );

    try {
      final response =
          await ref.read(dsrEntryProvider.notifier).getEProductDetails(
                request: request,
                token: token,
              );
      setState(() {
        productDetailsResponse = response;
        isLoadingEProducts = false;
        if (response.status == 'Success' &&
            response.productDetails.isNotEmpty) {
          previousSalesStage = response.productDetails.first.previousSalesStage;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to load E-Product details: ${response.status}')),
          );
        }
      });
    } catch (e) {
      setState(() => isLoadingEProducts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading E-Product details: $e')),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasLocation) {
      getAddress(showSettingsPrompt: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    visitDateController.dispose();
    feedbackController.dispose();
    addressEntryController.dispose();
    actionDateController.dispose();
    actionTextController.dispose();
    eProductRemarkController.dispose();
    super.dispose();
  }

  Future<void> _fetchDsrShipmentModes() async {
    if (!samplingDoneVisible) return;
    if (mounted) setState(() => isLoadingDsrShipmentModes = true);
    try {
      final authState = ref.read(authProvider);
      final response = await ref.read(dsrEntryProvider.notifier).fetchShipmentMode(
            token: authState.token ?? '',
            executiveId: authState.loginResponse?.executiveBasicData?[0].executiveId,
          );
      if (!mounted) return;
      setState(() {
        dsrShipmentModeResponse = response;
        isLoadingDsrShipmentModes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingDsrShipmentModes = false);
      AppUtils.showSnack(context, 'Unable to load Shipment Modes: $e');
    }
  }

  Future<void> _fetchSamplingDetails() async {
    final authState = ref.read(authProvider);

    final token = authState.token ?? '';

    final request = dsrsampling.dsrSamplingDetailsRequest(
      titleId: null,
      classLevelId: null,
      seriesId: null,
      customerId: widget.plan.customerId ?? 0,
      requestType: 'visit',
      profileId: AppUtils.getProfileIdStr(),
      customerType: widget.plan.customerType,
      executiveId: AppUtils.getExecutiveStr(),
    );

    final response =
        await ref.read(dsrEntryProvider.notifier).dsrfetchSamplingDetails(
              request: request,
              token: token,
            );
    if (response.status == "Success") {
      samplingResponse = response;
    }
    setState(() {});
  }

  Future<void> _fetchExecutives(int deptId) async {
    setState(() => isLoadingExecutives = true);
    final authState = ref.read(authProvider);
    final token = authState.token ?? '';

    final response =
        await ref.read(dsrEntryProvider.notifier).getFollowUpAction(
              executiveDepartmentId: deptId,
              executiveId: AppUtils.getExecutiveStr(),
              token: token,
            );

    setState(() {
      isLoadingExecutives = false;
      if (response.status == 'Success') {
        executives = response.executives;
        if (executives.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No executives available for this department')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load executives: ${response.status}')),
        );
      }
    });
  }

  void _addProductListDynamic() {
    print('object ${classOptions.length}');
    bool isMatch = false;

    final List<int> classss = [];
    final List<String> classssName = [];
    for (var action in classOptions) {
      if (action.isCheck) {
        isMatch = true;
        classss.add(action.classNumId);
        classssName.add(action.className);
        print('object action.className ${action.className}');
      }
    }

    String name = '';
    if (classss.isNotEmpty) {
      selectedClassId = classss.join(',');
      name = classssName.join(',');
    }

    print('object name ${name}');

    if (AppUtils.isBlank(selectedBrandId)) {
      AppUtils.showSnack(context, 'Select brand name');
      return;
    } else if (AppUtils.isBlankInt(selectedProductId)) {
      AppUtils.showSnack(context, 'Select product name');
      return;
    } else if (!isMatch) {
      AppUtils.showSnack(context, 'Select class name');
      return;
    } else if (AppUtils.isBlank(selectedCurrentSalesStage)) {
      AppUtils.showSnack(context, 'Select current sale stage');
      return;
    } else if (AppUtils.isBlank(selectProspect)) {
      AppUtils.showSnack(context, 'Select prospect');
      return;
    }

    String? brandNames;
    brandList?.forEach((action) {
      if ('${action.BrandId}' == selectedBrandId) {
        brandNames = action.BrandName;
      }
    });

    String? productNames;
    productResponse?.productList.forEach((action) {
      if ('${action.id}' == '$selectedProductId') {
        productNames = action.productName;
      }
    });

    int? selectProspectId;
    prospectList?.forEach((action) {
      if (action.ProspectName == '$selectProspect') {
        selectProspectId = action.ProspectId;
      }
    });

    int? selectedSalesStageId;
    saleStagList?.forEach((stage) {
      if (stage.SalesStageName == selectedCurrentSalesStage) {
        selectedSalesStageId = stage.SalesStageId;
      }
    });
    if (selectedSalesStageId == null) {
      AppUtils.showSnack(context, 'Selected sales stage is invalid');
      return;
    }

    final followUp = EProductData(
      brandId: selectedBrandId,
      brandName: brandNames,
      productId: '$selectedProductId',
      productName: productNames,
      classId: '$selectedClassId',
      className: name,
      preSalesStageId: "",
      preSalesStageName: previousSalesStage,
      currentSalesStageId: selectedSalesStageId.toString(),
      currentSalesStageName: selectedCurrentSalesStage,
      prospectId: selectProspectId?.toString(),
      prospectName: selectProspect,
      remark: eProductRemarkController.text.trim(),
    );

    setState(() {
      productAddList.add(followUp);
      for (var action in classOptions) {
        action.isCheck = false;
      }
      selectedBrandId = null;
      selectedProductId = null;
      selectedClassId = null;
      previousSalesStage = null;
      selectedCurrentSalesStage = null;
      selectProspect = null;
      eProductRemarkController.clear();
    });
  }

  void _addFollowUpAction() {
    final deptId = selectedDepartmentId != null
        ? int.tryParse(selectedDepartmentId!)
        : null;
    if (deptId == null || actionTextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a department and enter action text')),
      );
      return;
    }

    final followUp = FollowUpAction(
      executiveDepartmentId: deptId,
      executive: selectedExecutive ?? '',
      executiveID: selectedExecutiveId ?? '',
      actionDate: actionDateController.text,
      actionText: actionTextController.text,
    );

    setState(() {
      followUpActionsList.add(followUp);
      selectedDepartmentId = null;
      selectedExecutive = null;
      actionDateController.clear();
      actionTextController.clear();
      executives = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Follow-up action added successfully')),
    );
  }

  String escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  bool isValidXml(String? xmlString) {
    if (xmlString == null || xmlString.isEmpty) return true;
    try {
      xml.XmlDocument.parse(xmlString);
      return true;
    } catch (e) {
      print('Invalid XML: $e');
      return false;
    }
  }

  void _fetchSeriesList() async {
    try {
      final authState = ref.read(authProvider);

      final token = authState.token ?? '';

      final response =
          await ref.read(dsrEntryProvider.notifier).dsrfetchSeriesAndClassLevel(
                request: dsrsampling.dsrSeriesAndClassLevelRequest(
                  profileId: AppUtils.getProfileIdStr(),
                  executiveId: AppUtils.getExecutiveStr(),
                  classLevelId: 0,
                ),
                token: token,
              );

      setState(() {
        if (response.status == 'Success') {
          classLevelResponse = response;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading series: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.read(authProvider);
    final executiveId =
        authState.loginResponse?.executiveBasicData?[0].executiveId ?? 110;

    return Scaffold(
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 15,
          ),
          _widgetDsrSubmit(),
          SizedBox(
            height: 45,
          )
        ],
      ),
      appBar: AppBar(
        title: const Text(
          "DSR Entry",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Userheader(),
            FutureBuilder<DSREntryResponse>(
              future: _dsrEntryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return DSREntryWidgets.buildErrorContainer(
                      'Error: ${snapshot.error}');
                } else if (!snapshot.hasData ||
                    snapshot.data!.status != 'Success') {
                  return DSREntryWidgets.buildErrorContainer(
                      'No DSR entry data available');
                }

                final dsrData = snapshot.data!;
                brandList = dsrData.brand;
                visitorPurpose = dsrData.visitPurpose;
                prospectList = dsrData.prospect;
                saleStagList = dsrData.saleStage;
                allowedDateRanges = dsrData.allowedDateRange;
                if (dsrData.applicationSetupKeyValue.isNotEmpty) {
                  final visitFlags = dsrData.applicationSetupKeyValue.first;
                  samplingDoneVisible = visitFlags.booksSamplingEnabled;
                  eProductsVisible = visitFlags.eProductsEnabled;
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DSREntryWidgets.buildCustomerCard(widget.plan),

                        const SizedBox(height: 25),
                        DSREntryWidgets.buildDateField(
                          visitDateController,
                          context,
                          allowedDateRanges: dsrData.allowedDateRange,
                          onDateSelected: (pickedDate) {
                            setState(() {
                              visitDateController.text =
                                  pickedDate.toString().split(" ")[0];
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        // visit Purpose

                        DSREntryWidgets.buildDropdownField(
                          label: "Visit Purpose",
                          options: dsrData.visitPurpose
                              .map((e) => e.visitPurpose)
                              .toList(),
                          onChanged: (value) =>
                              setState(() => visitPurpose = value),
                          isMandatory: true,
                        ),
                        SizedBox(height: 20),
                        // joint Visit

                        DSREntryWidgets.buildDropdownField(
                          label: "Joint Visit With",
                          options: dsrData.joinVisit
                              .map((e) => e.executiveName)
                              .toList(),
                          onChanged: (value) {
                            for (var action in dsrData.joinVisit) {
                              if (value == action.executiveName) {
                                jointVisitID = '${action.executiveId}';
                              }
                            }
                            setState(() {});
                          },
                          isMandatory: false,
                        ),

                        SizedBox(height: 20),
                        DSREntryWidgets.buildPersonMetField(
                          dsrData.personMet,
                          selectedCustomerContactId,
                          false,
                          (id, name) {
                            setState(() {
                              selectedCustomerContactId = id;
                            });
                          },
                        ),
                        if (eProducts) SizedBox(height: 20),
                        if (eProducts)
                          DSREntryWidgets.buildAcademicSessionField(
                            dsrData.academicSession,
                            selectAcademicSessionId,
                            true,
                            (id, name) {
                              setState(() {
                                selectAcademicSessionId = id;
                              });
                            },
                          ),
                        /* const SizedBox(height: 20),
                        DSREntryWidgets.buildAddressField(
                          addressEntryController,
                          true,
                        ),*/
                        const SizedBox(height: 20),
                        // sampling Done
                        if (samplingDoneVisible)
                          DSREntryWidgets.buildRadioButtons(
                            label: "Sampling Done",
                            value: samplingDone,
                            onChanged: (value) {
                              setState(() {
                                samplingDone = value;
                              });
                            },
                          ),
                        if (samplingDoneVisible &&
                            samplingDone &&
                            samplingResponse != null) ...[
                          SamplingWidget(
                            samplingResponse: samplingResponse,
                            classLevelResponse: classLevelResponse,
                            customerId: widget.plan.customerId ?? 0,
                            customerType: widget.plan.customerType,
                            customerContactId: selectedCustomerContactId ?? 0,
                            executiveId: executiveId,
                            token: authState.token ?? '',
                            contextType: 'dsr',
                          ),
                          const SizedBox(height: 12),
                          if (isLoadingDsrShipmentModes)
                            const Center(child: CircularProgressIndicator())
                          else
                            DropdownButtonFormField<String>(
                              value: selectedDsrShipmentModeId,
                              isExpanded: true,
                              decoration: getInputDecoration(
                                label: 'Shipment Mode',
                                isMandatory: true,
                              ),
                              items: dsrShipmentModeResponse?.shipmentModes
                                  .map(
                                    (mode) => DropdownMenuItem<String>(
                                      value: mode.shipmentModeId.toString(),
                                      child: Text(mode.shipmentModeName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => selectedDsrShipmentModeId = value),
                              validator: (value) => value == null
                                  ? 'Please select a Shipment Mode'
                                  : null,
                            ),
                        ],
                        const SizedBox(height: 10),
                        if (samplingDoneVisible && samplingDone)
                          const SizedBox(height: 10),

                        // E-Products
                        if (eProductsVisible)
                          DSREntryWidgets.buildRadioButtons(
                            label: "E-Products",
                            value: eProducts,
                            onChanged: (value) =>
                                setState(() => eProducts = value),
                          ),
                        if (eProductsVisible && eProducts) ...[
                          const SizedBox(height: 10),
                          Text(
                            "E-Product",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          ...productAddList.asMap().entries.map((entry) {
                            final index = entry.key;
                            final followUp = entry.value;
                            return DSREntryWidgets.buildProductAddCard(
                                index, followUp, onDelete: (d) {
                              productAddList.remove(d);
                              setState(() {});
                            });
                          }),
                          buildEProductFields(
                            isLoadingEProducts: isLoadingEProducts,
                            productResponse: productResponse,
                            brandList: brandList,
                            prospectList: prospectList,
                            saleStagList: saleStagList,
                            selectedBrandName: selectedBrandId,
                            selectedProductId: selectedProductId,
                            productDetailsResponse: productDetailsResponse,
                            selectedCurrentSalesStage:
                                selectedCurrentSalesStage,
                            selectedProspect: selectProspect,
                            previousSalesStage: previousSalesStage,
                            remarkController: eProductRemarkController,
                            onBrandChanged: (value) {
                              setState(() {
                                selectedBrandId = value;
                                selectedProductId = null;
                                selectedClassId = null;
                                selectedCurrentSalesStage = null;
                                previousSalesStage = null;
                                productDetailsResponse = null;
                                if (value != null) {
                                  _fetchEProductList(value);
                                }
                              });
                            },
                            onProductChanged: (value) {
                              setState(() {
                                selectedProductId = value;
                                selectedClassId = null;
                                selectedCurrentSalesStage = null;
                                previousSalesStage = null;
                                productDetailsResponse = null;
                                if (value != null) {
                                  _fetchEProductDetails(value);
                                }
                              });
                            },
                            onSalesStageChanged: (value) {
                              setState(() => selectedCurrentSalesStage = value);
                            },
                            onProspectChanged: (value) {
                              setState(() => selectProspect = value);
                            },
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (eProductsVisible && eProducts)
                          const SizedBox(height: 10),
                        if (followUpActionVisible)
                          DSREntryWidgets.buildRadioButtons(
                            label: "Follow Up Action",
                            value: followUpAction,
                            onChanged: (value) =>
                                setState(() => followUpAction = value),
                          ),
                        if (followUpActionVisible && followUpAction) ...[
                          const SizedBox(height: 8),
                          ...followUpActionsList.asMap().entries.map((entry) {
                            final index = entry.key;
                            final followUp = entry.value;
                            return DSREntryWidgets.buildFollowUpActionCard(
                                index, followUp, onDelete: (d) {
                              followUpActionsList.remove(d);
                              setState(() {});
                            });
                          }),
                          DSREntryWidgets.buildAddFollowUpAction(
                            context,
                            dsrData.department,
                            selectedDepartmentId,
                            executives,
                            selectedExecutive,
                            isLoadingExecutives,
                            actionDateController,
                            actionTextController,
                            visitDateController,
                            selectAcademicSessionId,
                            onDepartmentChanged: (value) {
                              setState(() {
                                selectedDepartmentId = value;
                                executives = [];
                                selectedExecutive = null;
                                if (value != null) {
                                  _fetchExecutives(int.parse(value));
                                } else {
                                  isLoadingExecutives = false;
                                }
                              });
                            },
                            onExecutiveChanged: (value) {
                              selectedExecutive = value;
                              for (var action in executives) {
                                if (action.name == selectedExecutive) {
                                  selectedExecutiveId = '${action.executiveId}';
                                }
                              }
                              setState(() {});
                            },
                            onActionDateSelected: (pickedDate) {
                              setState(() {
                                actionDateController.text =
                                    pickedDate.toString().split(" ")[0];
                              });
                            },
                            onAddAction: _addFollowUpAction,
                          ),
                        ],
                        if (documentSateData.isNotEmpty)
                          const SizedBox(height: 6),
                        ...documentSateData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final followUp = entry.value;
                          return DSREntryWidgets.buildForDocument(
                              index, followUp, onDelete: (d) {
                            documentSateData.remove(d);
                            setState(() {});
                          });
                        }),
                        SizedBox(height: 4),
                        DSREntryWidgets.buildDocumentUpload(
                          onUpload: isUploadingDocument ? null : _pickDocument,
                          isUploading: isUploadingDocument,
                        ),
                        SizedBox(height: 30),
                        DSREntryWidgets.buildFeedbackField(
                          feedbackController,
                          feedbackMandatory,
                          500,
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _widgetDsrSubmit() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25),
      child: Column(
        children: [
          isSubmitting
              ? CircularProgressIndicator(color: Colors.white)
              : DSREntryWidgets.buildSubmitButton(
                  onSubmit: _submitDSREntry,
                ),
        ],
      ),
    );
  }

  Future<void> _submitDSREntry() async {
    try {
      if (!_validateForm()) return;

      final authState = ref.read(authProvider);

      final executiveId =
          authState.loginResponse?.executiveBasicData?[0].executiveId;
      final userId = authState.loginResponse?.executiveBasicData?[0].userId;
      final profileCode =
          authState.loginResponse?.executiveBasicData?[0].profileCode ?? '';
      if (executiveId == null || userId == null) {
        AppUtils.showSnack(context, 'Login session is incomplete. Please login again.');
        return;
      }

      // A Visit/DSR must use a real device location. If location was not
      // available when this screen opened, ask again before submitting.
      if (!_hasLocation) {
        await getAddress(showSettingsPrompt: true);
        if (!_hasLocation) {
          if (mounted) {
            AppUtils.showSnack(
              context,
              'Location is required before submitting the DSR entry.',
            );
          }
          return;
        }
      }

      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final visitDate = visitDateController.text.isNotEmpty
          ? DateTime.parse(visitDateController.text)
          : now;

      if (visitDate.isAfter(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit date cannot be in the future')),
        );
        return;
      }
      if (allowedDateRanges.isNotEmpty &&
          !allowedDateRanges.any((range) => range.contains(visitDate))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit date is outside the allowed date range')),
        );
        return;
      }

      final formattedVisitDate = dateFormat.format(visitDate);
      AllowedDateRange? selectedAllowedRange;
      for (final range in allowedDateRanges) {
        if (range.contains(visitDate)) {
          selectedAllowedRange = range;
          break;
        }
      }
      if (visitPurpose == null || visitorPurpose == null || visitorPurpose!.isEmpty) {
        AppUtils.showSnack(context, 'Select a valid visit purpose');
        return;
      }
      final visitPurposeId = visitorPurpose!
          .firstWhere(
            (vp) => vp.visitPurpose == visitPurpose,
            orElse: () => visitorPurpose!.first,
          )
          .id;

      String? eProductXML;
      if (eProductsVisible && eProducts && productAddList.isNotEmpty) {
        final buffer = StringBuffer('<DocumentElement>');
        for (final action in productAddList) {
          buffer
            ..write('<EProductPromotionDetails>')
            ..write('<BrandId>${action.brandId}</BrandId>')
            ..write('<eProductId>${action.productId}</eProductId>')
            ..write('<SalesStageId>${action.currentSalesStageId}</SalesStageId>')
            ..write('<ProspectId>${action.prospectId}</ProspectId>')
            ..write('<Classes>${action.classId}</Classes>')
            ..write('<Remarks>${escapeXml(action.remark ?? '')}</Remarks>')
            ..write('</EProductPromotionDetails>');
        }
        buffer.write('</DocumentElement>');
        eProductXML = buffer.toString();
      }

      String? samplingXMLData;
      double totalPrice = 0;
      int totalQnt = 0;

      if (samplingDoneVisible && samplingDone) {
        String data = '';

        for (var sample in sampleInSeries) {
          sample.titles?.forEach((title) {
            var mRP = title.price.replaceAll('₹', "").trim();
            var t = double.tryParse(mRP) ?? 0;
            var seriesId = sample.seriesId;
            var bookId = title.bookId;
            var requestQty = title.quantity.toString().padLeft(2, '0');
            var shipTo = sample.shipTo;
            var shipToLabel = sample.shipToLabel;
            var samplingType = sample.samplingType;
            var sampleTo = sample.sampleToId;
            var sampleGiven = sample.sampleGiven;
            var subjectId = title.subjectId;

            print('object subjectId: $subjectId');

            totalPrice = totalPrice + (t * title.quantity);
            totalQnt = totalQnt + title.quantity;
            data =
                '$data<CustomerSamplingRequestDetails><SeriesId>$seriesId</SeriesId><SubjectId>$subjectId</SubjectId><BookId>$bookId</BookId><RequestedQty>$requestQty</RequestedQty><ShipTo>$shipToLabel</ShipTo><ShippingAddress>$shipTo</ShippingAddress><SamplingType>$samplingType</SamplingType><SampleTo>$sampleTo</SampleTo><SampleGiven>$sampleGiven</SampleGiven><MRP>$mRP</MRP></CustomerSamplingRequestDetails>';
          });
        }

        for (var sample in sampleNotInSeries) {
          sample.titles?.forEach((title) {
            var mRP = title.price.replaceAll('₹', "").trim();
            var t = double.tryParse(mRP) ?? 0;
            var subjectId = title.subjectId;
            var seriesId = sample.seriesId;
            var bookId = title.bookId;
            var requestQty = title.quantity.toString().padLeft(2, '0');
            var shipTo = sample.shipTo;
            var shipToLabel = sample.shipToLabel;
            var samplingType = sample.samplingType;
            var sampleTo = sample.sampleToId;
            var sampleGiven = sample.sampleGiven;
            totalPrice = totalPrice + (t * title.quantity);
            totalQnt = totalQnt + title.quantity;
            data =
                '$data<CustomerSamplingRequestDetails><SeriesId>$seriesId</SeriesId><SubjectId>$subjectId</SubjectId><BookId>$bookId</BookId><RequestedQty>$requestQty</RequestedQty><ShipTo>$shipToLabel</ShipTo><ShippingAddress>$shipTo</ShippingAddress><SamplingType>$samplingType</SamplingType><SampleTo>$sampleTo</SampleTo><SampleGiven>$sampleGiven</SampleGiven><MRP>$mRP</MRP></CustomerSamplingRequestDetails>';
          });
        }

        samplingXMLData = '<DocumentElement>$data</DocumentElement>';
      }

      print('samplingXMLData $samplingXMLData');

      String? followUpActionXML;
      if (followUpActionVisible &&
          followUpAction &&
          followUpActionsList.isNotEmpty) {
        String data = '';
        followUpActionsList.forEach((action) {
          try {
            final actionDate = DateTime.parse(action.actionDate);
            if (actionDate.isBefore(visitDate)) {
              throw Exception('Action date must be on or after visit date');
            }

            var department = action.executiveDepartmentId;
            var followUpExecutiveId = action.executiveID;
            var followUpAction = action.actionText;
            var followUpDate = action.actionDate;

            data =
                '$data<FollowUpAction><Department>$department</Department><FollowUpExecutive>$followUpExecutiveId</FollowUpExecutive><FollowUpAction>$followUpAction</FollowUpAction><FollowUpDate>$followUpDate</FollowUpDate></FollowUpAction>';
          } catch (e) {
            throw Exception('Invalid action date format: $e');
          }
        });

        followUpActionXML = '<DocumentElement>$data</DocumentElement>';
      }

      String? documentXML;
      if (documentSateData.isNotEmpty) {
        String data = '';
        documentSateData?.forEach((action) {
          var documentName = action.documentName;
          var fileName = action.fileName;
          var fileSize = action.size;
          data =
              '$data<UploadedDocument><DocumentName>$documentName</DocumentName><FileName>$fileName</FileName><FileSize>$fileSize</FileSize></UploadedDocument>';
        });

        documentXML = '<DocumentElement>$data</DocumentElement>';
      }

      // Prepare DSR submission data
      final dsrRequest = {
        "ExecutiveId": AppUtils.getExecutiveStr(),
        "LoggedInExecutiveid": AppUtils.getExecutiveStr(),
        "CustomerId": widget.plan.customerId,
        "CustomerType": widget.plan.customerType,
        "VisitDate": formattedVisitDate,
        "VisitPurpose": visitPurposeId,
        "CustomerContact": selectedCustomerContactId ?? 0,
        "VisitFeedBack": escapeXml(feedbackController.text.isNotEmpty
            ? feedbackController.text
            : "No feedback provided"),
        "LoggedInExecutiveProfileCode": profileCode,
        "AcademicSessionId": selectAcademicSessionId ?? 0,
        "addressEntry": escapeXml(addressEntryController.text.trim().isNotEmpty
            ? addressEntryController.text.trim()
            : '${latValue.toStringAsFixed(6)}, ${longValue.toStringAsFixed(6)}'),
        "EnteredBy": userId,
        "LongEntry": longValue.toString(),
        "LatEntry": latValue.toString(),
        "UploadedDocumentXML": documentXML,
        "RequestRemarks": "DSR Entry Submission",
        if (selectedAllowedRange?.backdateRequestId != null)
          "BackdateRequestId": selectedAllowedRange!.backdateRequestId,
        if (jointVisitID != null) "JointVisitWith": jointVisitID,
        if (samplingXMLData != null && samplingDoneVisible) ...{
          "VisitDetailsXMLforToBeDispatched": samplingXMLData,
          "ShipmentMode": selectedDsrShipmentModeId,
        },
        if (followUpActionXML != null && followUpActionVisible)
          "FollowUpActionXML": followUpActionXML,
        if (eProductXML != null && eProductsVisible && eProducts)
          "EProductPromotionDetailsXML": eProductXML,
        "TotalQty": totalQnt,
        "TotalPrice": totalPrice,
      };

      AppUtils.showToast(
          'Please wait for a minute... DSR data is uploading...');
      isSubmitting = true;
      setState(() {});

      final submitted = await ApiService().addDsrEntryAPI(dsrRequest);
      if (!mounted) return;
      if (submitted) {
        checkDsrResult();
      } else {
        AppUtils.showSnack(
          context,
          'DSR entry could not be submitted. Please check the message above and try again.',
        );
      }
    } catch (e) {
      checkEProductResult('Error submitting DSR Entry: $e');
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void checkEProductResult(String? msg) {
    AppUtils.showSnack(context, msg);

    return;
  }

  void checkDsrResult() {
    Navigator.pop(context);
    if (FROM_TODSR == 2) {
      Navigator.pop(context);
    }
  }

  bool _validateForm() {
    if (visitDateController.text.isEmpty) {
      AppUtils.showSnack(context, 'Please enter a Visit Date');
      return false;
    }

    if (visitPurpose == null) {
      AppUtils.showSnack(context, 'Please select a Visit Purpose');
      return false;
    }

    if (eProducts && selectAcademicSessionId == null) {
      AppUtils.showSnack(context, 'Please select an academic session');
      return false;
    }

    /* if (addressEntryController.text.isEmpty) {
      AppUtils.showSnack(context, 'Please enter the visit address');
      return false;
    }*/

    if (samplingDoneVisible && samplingDone) {
      /*if (selectedSamplingType == null || selectedSampleGiven == null) {
        AppUtils.showSnack(context, 'Please select sampling type and sample given');
        return false;
      }
*/
      if (sampleInSeries.isEmpty && sampleNotInSeries.isEmpty) {
        AppUtils.showSnack(
            context, 'Please select Sampling series or not in series');
        return false;
      }

      if (sampleInSeries.isNotEmpty) {
        var isFind = false;
        for (var action in sampleInSeries) {
          if (action.sampleTo == 'Select') {
            isFind = true;
          }
          if (action.shipTo == 'Select') {
            isFind = true;
          }
        }
        if (isFind) {
          AppUtils.showSnack(
              context, 'Please select sample and ship to in series');
          return false;
        }
      }

      if (sampleNotInSeries.isNotEmpty) {
        var isFind = false;
        for (var action in sampleNotInSeries) {
          if (action.sampleTo == 'Select') {
            isFind = true;
          }
          if (action.shipTo == 'Select') {
            isFind = true;
          }
        }
        if (isFind) {
          AppUtils.showSnack(
              context, 'Please select sample and ship to not in series');
          return false;
        }
      }
    }

    if (samplingDoneVisible && samplingDone &&
        selectedDsrShipmentModeId == null) {
      AppUtils.showSnack(context, 'Please select a Shipment Mode');
      return false;
    }

    if (eProductsVisible && eProducts && productAddList.isEmpty) {
      AppUtils.showSnack(context, 'Please complete all E-Products details');
      return false;
    }
    if (followUpActionVisible &&
        followUpAction &&
        followUpActionsList.isEmpty) {
      AppUtils.showSnack(context, 'Required Follow-Up Action');
      return false;
    }

    if (feedbackMandatory && feedbackController.text.isEmpty) {
      AppUtils.showSnack(context, 'Please enter Visit Feedback');
      return false;
    }
    if (feedbackMaxLength != null &&
        feedbackController.text.length < feedbackMaxLength!) {
      AppUtils.showSnack(context,
          'Visit Feedback minimum length is $feedbackMaxLength characters');
      return false;
    }
    return true;
  }

  Future<void> _pickDocument() async {
    await DSREntryWidgets.showDocumentUploadDialog(
      context,
      onCaptureImage: _captureImage,
      onPickFile: _pickFile,
    );
  }

  Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _captureImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      await fileUploadAPI(image);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var action in result.files) {
          await fileUploadAPI(action.xFile);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking documents: $e')),
      );
    }
  }

  Future<void> fileUploadAPI(XFile? image) async {
    if (image == null || isUploadingDocument) return;

    final fileName = image.name;
    final fileSizeInBytes = await image.length();
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    if (!const ['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
      if (mounted) {
        AppUtils.showSnack(
          context,
          'Only PDF, JPG, JPEG and PNG files are allowed',
        );
      }
      return;
    }

    if (fileSizeInBytes > 10 * 1024 * 1024) {
      if (mounted) {
        AppUtils.showSnack(context, 'Document size cannot exceed 10 MB');
      }
      return;
    }

    documentController.clear();
    final confirmed = await dialogGoBackCross();
    if (!confirmed || !mounted) return;

    setState(() => isUploadingDocument = true);
    try {
      final bytes = await image.readAsBytes();
      final request = UploadDocumentRequest()
        ..fileName = fileName
        ..fileExtension = extension
        ..module = 'visit'
        ..base64String = base64Encode(bytes);

      AppUtils.showToast('Document file is uploading. Please wait...');

      final data = await ApiService().uploadDocumentAPI(request);
      if (!mounted) return;

      if (data?.returnDetails?.isNotEmpty != true) {
        AppUtils.showSnack(
          context,
          'Document upload failed. Check that the latest Backend V2 is running.',
        );
        return;
      }

      final storedName = data!.returnDetails!.first.fileName?.trim() ?? '';
      if (storedName.isEmpty) {
        AppUtils.showSnack(
          context,
          'Document upload failed: server did not return a file name.',
        );
        return;
      }

      documentSateData.add(
        DocumentSaveData()
          ..documentName = documentController.text.trim()
          ..fileName = storedName
          ..size = fileSizeInBytes,
      );
      setState(() {});
      AppUtils.showToast('Document uploaded successfully');
    } catch (e) {
      if (mounted) {
        AppUtils.showSnack(context, 'Document upload failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isUploadingDocument = false);
      }
    }
  }

  double latValue = 0;
  double longValue = 0;

  Future<Position> _determinePosition({bool showSettingsPrompt = true}) async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showSettingsPrompt && mounted) {
        final openSettings = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Turn on location'),
                content: const Text(
                  'Location is required for Visit/DSR entry. Please turn on device location and return to the app.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            ) ??
            false;
        if (openSettings) {
          await Geolocator.openLocationSettings();
        }
      }
      throw Exception('Location services are disabled. Turn on location to continue.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (showSettingsPrompt && mounted) {
        final openSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Location permission required'),
                content: const Text(
                  'Location permission is permanently denied. Enable it from app settings to use Visit/DSR.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Open App Settings'),
                  ),
                ],
              ),
            ) ??
            false;
        if (openSettings) {
          await Geolocator.openAppSettings();
        }
      }
      throw Exception('Location permission is required for Visit/DSR.');
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<String> _getAddressFromLatLng(Position position) async {
    latValue = position.latitude;
    longValue = position.longitude;
    _hasLocation = true;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks.first;
      return '${place.street}, ${place.subLocality}, ${place.locality}, '
          '${place.administrativeArea}, ${place.postalCode}, ${place.country}';
    } catch (_) {
      // Reverse geocoding can fail even when GPS succeeded. Keep the real
      // coordinates so Visit/DSR submission can still continue.
      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }
  }

  List<ClassDetail> classOptions = [];

  Widget buildEProductFields({
    required bool isLoadingEProducts,
    required EProductListResponse? productResponse,
    required List<BrandData>? brandList,
    required List<ProspectData>? prospectList,
    required List<SaleStagData>? saleStagList,
    required String? selectedBrandName,
    required int? selectedProductId,
    required EProductDetailsResponse? productDetailsResponse,
    required String? selectedCurrentSalesStage,
    required String? selectedProspect,
    required String? previousSalesStage,
    required TextEditingController remarkController,
    required Function(String?) onBrandChanged,
    required Function(int?) onProductChanged,
    required Function(String?) onSalesStageChanged,
    required Function(String?) onProspectChanged,
  }) {
    classOptions = productDetailsResponse?.classes ?? [];

    final filteredProducts = productResponse?.productList ?? [];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: TColors.icon),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "E-Products",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Divider(color: Colors.black),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                width: 50,
                child: Text(
                  'SNO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
          if (brandList?.isEmpty == true)
            const Text(
              "No brands available. Please try again.",
              style: TextStyle(color: Colors.red),
            )
          else ...[
            Row(
              children: [
                const SizedBox(width: 50, child: Text('1')),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedBrandName,
                        decoration: getInputDecoration(
                          label: 'Brand Name',
                          isMandatory: true,
                          borderColor: selectedBrandName == null
                              ? Colors.red
                              : Colors.green,
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Select'),
                          ),
                          ...brandList!.map((brand) => DropdownMenuItem<String>(
                                value: '${brand.BrandId}',
                                child: Text(brand.BrandName),
                              )),
                        ],
                        onChanged: onBrandChanged,
                        validator: (value) =>
                            value == null ? 'Please select a Brand Name' : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: selectedProductId,
                        decoration: getInputDecoration(
                          label: 'Product Name',
                          isMandatory: true,
                          borderColor: selectedProductId == null
                              ? Colors.red
                              : Colors.green,
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Select'),
                          ),
                          ...filteredProducts!
                              .map((product) => DropdownMenuItem<int>(
                                    value: product.id,
                                    child: Text(product.productName),
                                  )),
                        ],
                        onChanged: onProductChanged,
                        validator: (value) => value == null
                            ? 'Please select a Product Name'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      classOptions.isEmpty
                          ? SizedBox()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  'Classes',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                SizedBox(
                                  child: GridView.count(
                                    crossAxisCount: 3,
                                    childAspectRatio: 4,
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    children: classOptions.map((option) {
                                      return InkWell(
                                        onTap: () {
                                          print('object');
                                          option.isCheck = !(option.isCheck);
                                          setState(() {});
                                        },
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: option.isCheck,
                                              onChanged: (bool? checked) {
                                                print('object $checked');
                                                option.isCheck =
                                                    !(option.isCheck);
                                                setState(() {});
                                              },
                                              visualDensity: VisualDensity(
                                                  horizontal: -4.0,
                                                  vertical: -4.0),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize.padded,
                                            ),
                                            Expanded(
                                                child: Text(
                                              option.className,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColor.black),
                                            )),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                      SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        initialValue: previousSalesStage ?? 'None',
                        readOnly: true,
                        decoration: getInputDecoration(
                          label: 'Previous Sales Stage',
                          isMandatory: false,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCurrentSalesStage,
                        decoration: getInputDecoration(
                          label: 'Current Sales Stage',
                          isMandatory: true,
                          borderColor: selectedCurrentSalesStage == null
                              ? Colors.red
                              : Colors.green,
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Select'),
                          ),
                          ...saleStagList!
                              .map((stage) => DropdownMenuItem<String>(
                                    value: stage.SalesStageName,
                                    child: Text(stage.SalesStageName),
                                  )),
                        ],
                        onChanged: onSalesStageChanged,
                        validator: (value) => value == null
                            ? 'Please select a Current Sales Stage'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedProspect,
                        decoration: getInputDecoration(
                          label: 'Prospect',
                          isMandatory: true,
                          borderColor: selectedProspect == null
                              ? Colors.red
                              : Colors.green,
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Select'),
                          ),
                          ...prospectList!
                              .map((stage) => DropdownMenuItem<String>(
                                    value: stage.ProspectName,
                                    child: Text(stage.ProspectName),
                                  )),
                        ],
                        onChanged: onProspectChanged,
                        validator: (value) =>
                            value == null ? 'Please select a prospect' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: remarkController,
                        maxLines: 2,
                        decoration: getInputDecoration(
                          label: 'Remark',
                          isMandatory: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          SizedBox(
            height: 10,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _addProductListDynamic,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.buttonPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Add E-Product",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration getInputDecoration({
    required String label,
    bool isMandatory = false,
    Color borderColor = Colors.blue,
    EdgeInsets contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
  }) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
          children: [
            if (isMandatory)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: TColors.borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: TColors.borderColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: contentPadding,
    );
  }

  TextEditingController documentController = TextEditingController();
  FocusNode file = FocusNode();
  FocusNode documentFocus = FocusNode();

  Future<bool> dialogGoBackCross() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: AppColor.white,
        surfaceTintColor: AppColor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Upload Document',
                  style: TextStyle(
                    color: AppColor.black,
                    fontSize: 20,
                  ),
                ),
                AllFieldWidget(
                  controller: documentController,
                  preNode: documentFocus,
                  max: 30,
                  nextNode: null,
                  required: '*',
                  format: FORMAT.ALL,
                  field: 'Document Name',
                  onTypeChange: (value) {},
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: FillButtonWidget(
                        radius: 8,
                        height: 36,
                        title: 'Add',
                        bgColor: AppColor.color_B0B0B0,
                        onPressed: () {
                          final documentName = documentController.text.trim();
                          if (AppUtils.isBlank(documentName)) {
                            AppUtils.showToast('Enter document name');
                            return;
                          }
                          Navigator.pop(dialogContext, true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }
}
