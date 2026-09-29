// lib/screens/visit_details_screen.dart
import 'package:dart_crm/models/planList/plan.dart';
import 'package:dart_crm/models/visit_details.dart';
import 'package:dart_crm/providers/visit_details_provider.dart';
import 'package:dart_crm/screens/Visit_DSR/DSR_entry/dsr_entry.dart';
import 'package:dart_crm/screens/homeScreen/widget/userHeader.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../edit/utils/AppUtils.dart';

class PlanListDetailsScreen extends ConsumerStatefulWidget {
  final Plan plan;

  const PlanListDetailsScreen({super.key, required this.plan});

  @override
  ConsumerState<PlanListDetailsScreen> createState() => _PlanListDetailsScreenState();
}

class _PlanListDetailsScreenState extends ConsumerState<PlanListDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _fetchVisitDetails();
    });
  }

  void _fetchVisitDetails() {
    final request = VisitDetailsRequest(customerId: widget.plan.customerId);
    ref.read(visitDetailsProvider.notifier).fetchVisitDetails(request);
  }

  @override
  Widget build(BuildContext context) {
    final visitState = ref.watch(visitDetailsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'DART CRM',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Userheader(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.03),
                  if (visitState.isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (visitState.errorMessage != null)
                    Text(
                      visitState.errorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  if (visitState.visitDetailsResponse != null &&
                      visitState.visitDetailsResponse!.status == 'Success')
                    ..._buildVisitContent(
                      visitState.visitDetailsResponse!,
                      screenWidth,
                      screenHeight,
                    )
                  else if (visitState.visitDetailsResponse != null &&
                      visitState.visitDetailsResponse!.status != 'Success')
                    Text(
                      'No visit details available',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomerDetail _customerFromPlan() {
    return CustomerDetail(
      customerId: widget.plan.customerId,
      customerName: widget.plan.customerName,
      address: widget.plan.address,
      name: widget.plan.contact,
      emailId: widget.plan.emailId,
      mobile: widget.plan.phone,
    );
  }

  List<Widget> _buildVisitContent(
    VisitDetailsResponse response,
    double screenWidth,
    double screenHeight,
  ) {
    final customer = response.customerDetails.isNotEmpty
        ? response.customerDetails.first
        : _customerFromPlan();

    return [
      _buildSchoolInfo(customer, screenWidth),
      SizedBox(height: screenHeight * 0.03),
      if (response.visitDetails.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No previous visit entry is available for this customer yet.',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.grey[700],
            ),
          ),
        )
      else ...[
        _buildInfoSection(response.visitDetails.first, screenWidth),
        SizedBox(height: screenHeight * 0.03),
        _buildUploadedDocumentsSection(
          response.uploadedDocuments,
          screenWidth,
        ),
      ],
    ];
  }

  Widget _buildSchoolInfo(CustomerDetail customerDetail, double screenWidth) {
    final addressLines = customerDetail.address
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .split('\r\n')
        .where((line) => line.isNotEmpty)
        .toList();

    return Card(
      color: TColors.primary,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, vertical: screenWidth * 0.02),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${customerDetail.customerName})',
                    // '${customerDetail.customerName} (ID: ${customerDetail.customerId})',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: TColors.headerText,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  ...addressLines.map((line) => Text(
                        line,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: screenWidth * 0.035,
                        ),
                      )),
                  Text(
                    'Contact: ${customerDetail.name}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  if (customerDetail.emailId.isNotEmpty)
                    Text(
                      'Email: ${customerDetail.emailId}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  if (customerDetail.mobile.isNotEmpty)
                    Text(
                      'Mobile: ${customerDetail.mobile}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                ],
              ),
            ),
            // GestureDetector(
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => DSREntryScreen(plan: widget.plan),
            //       ),
            //     );
            //   },
            //   child: Column(
            //     children: [
            //       Icon(Icons.directions_bike,
            //           color: TColors.buttonPrimary, size: screenWidth * 0.08),
            //       Text(
            //         "DSR Entry",
            //         style: TextStyle(
            //           color: TColors.buttonPrimary,
            //           fontWeight: FontWeight.w800,
            //           fontSize: screenWidth * 0.03,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(VisitDetail visitDetail, double screenWidth) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      shadowColor: Colors.blue.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (visitDetail.visitDate != " " &&
                visitDetail.visitDate.isNotEmpty &&
                visitDetail.visitDate != null)
              _buildInfoRow('Visit Date', visitDetail.visitDate, screenWidth),
            if (visitDetail.executiveName != " " &&
                visitDetail.executiveName.isNotEmpty &&
                visitDetail.executiveName != null)
              _buildInfoRow(
                  'Visit By',
                  '${visitDetail.executiveName} (ID: ${visitDetail.executiveId})',
                  screenWidth),
            if (visitDetail.visitPurpose != " " &&
                visitDetail.visitPurpose.isNotEmpty &&
                visitDetail.visitPurpose != null)
              _buildInfoRow('Visit Purpose', visitDetail.visitPurpose, screenWidth),
            if (visitDetail.jointVisitWith != " " &&
                visitDetail.jointVisitWith.isNotEmpty &&
                visitDetail.jointVisitWith != null)
              _buildInfoRow('Joint Visit', visitDetail.jointVisitWith, screenWidth),
            if (visitDetail.jointVisitWith != " " &&
                visitDetail.jointVisitWith.isNotEmpty &&
                visitDetail.jointVisitWith != null)
              _buildInfoRow('Person Met', visitDetail.personMet, screenWidth),
            if (visitDetail.visitFeedback != " " &&
                visitDetail.visitFeedback.isNotEmpty &&
                visitDetail.visitFeedback != null)
              _buildInfoRow('Feedback', visitDetail.visitFeedback, screenWidth),
            // _buildInfoRow(
            //     'Location',
            //     'Lat ${visitDetail.lat}, Long ${visitDetail.long}',
            //     screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: TColors.headerText,
              fontSize: screenWidth * 0.04,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: screenWidth * 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedDocumentsSection(
      List<UploadedDocument> documents, double screenWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uploaded Documents:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.05,
                color: TColors.headerText,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: screenWidth * 0.025),
            if (documents.isEmpty)
              Text(
                'No documents available',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.grey,
                ),
              )
            else
              ...documents.asMap().entries.map((entry) {
                final index = entry.key;
                final doc = entry.value;
                final isNumeric = RegExp(r'^\d+$').hasMatch(doc.documentName);
                final displayName = (doc.documentName.isEmpty || isNumeric)
                    ? 'Document ${index + 1}'
                    : doc.documentName;

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _openDocument(doc.action),
                        child: SizedBox(
                          width: screenWidth * 0.65,
                          child: Text(
                            displayName,
                            style: TextStyle(
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                              fontSize: screenWidth * 0.04,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.download,
                            color: Colors.blue, size: screenWidth * 0.06),
                        onPressed: () => _downloadDocument(doc.action, displayName),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    print('Attempting to open: $url');
    if (url.isEmpty) {
      _showErrorSnackBar('No document link available');
      return;
    }
    try {
      String fullUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        fullUrl = '$BASE_URL_1$url';
      }
      fullUrl = Uri.parse(fullUrl).normalizePath().toString();
      final Uri uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => WebViewScreen(url: fullUrl),
        ));
      }
    } catch (e) {
      _showErrorSnackBar('Error opening document: $e');
    }
  }

  Future<void> _downloadDocument(String url, String fileName) async {
    print('Attempting to download: $url');
    if (url.isEmpty) {
      _showErrorSnackBar('No document link available');
      return;
    }
    try {
      String fullUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        fullUrl = '$BASE_URL_1$url';
      }
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        _showSuccessSnackBar('Document downloaded to $filePath');
      } else {
        _showErrorSnackBar('Failed to download document: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error downloading document: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Document Viewer'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
