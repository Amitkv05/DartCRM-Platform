import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/menu.dart';
import 'package:dart_crm/screens/Visit_DSR/visitDSR_screen/visit_entry_search_screen.dart';
import 'package:dart_crm/screens/Visit_DSR/visitDSR_screen/todays_Plan/visit_today_plan_screen.dart';
import 'package:dart_crm/screens/homeScreen/notification_screen.dart';
import 'package:dart_crm/screens/homeScreen/widget/change_password.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/customer_sampling_screen/customer_sampling_request_screen.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/checkin_checkout_provider.dart';
import 'package:dart_crm/edit/school_master_list_screen.dart';
import 'package:dart_crm/screens/Visit_DSR/planList/plan_list_screen.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/self_stock_request_screen.dart';
import 'package:dart_crm/providers/notification_provider.dart';
import 'package:dart_crm/screens/approvals/approval_module_list_screen.dart';
import 'package:dart_crm/screens/admin/approval_role_management_screen.dart';
import 'package:dart_crm/screens/admin/user_role_management_screen.dart';
import 'package:dart_crm/screens/admin/request_approval_history_screen.dart';
import 'package:dart_crm/screens/approvals/my_request_history_screen.dart';
import 'package:dart_crm/screens/Visit_DSR/backdate/visit_backdate_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _lastErrorMessage;

  void _toggleCheckinCheckout() {
    final checkinState = ref.read(checkinCheckoutProvider);
    if (checkinState.isCheckedIn) {
      ref.read(checkinCheckoutProvider.notifier).checkOut();
    } else {
      ref.read(checkinCheckoutProvider.notifier).checkIn();
    }
    Navigator.pop(context);
  }

  Widget _getScreenFromLink(String? linkUrl, String? childMenuName) {
    final menuName = childMenuName?.toLowerCase() ?? '';
    switch (menuName) {
      case 'school list':
        return const SchoolMasterList(customerType: 'School');
      case 'trade list':
        return const SchoolMasterList(customerType: 'Trade');
      case 'library list':
        return const SchoolMasterList(customerType: 'Library');
      case 'customer sampling approval':
      case 'sampling approval':
        return const ApprovalModuleListScreen(
          moduleName: 'CUSTOMER_SAMPLING',
          title: 'Customer Sampling Approvals',
        );
      case 'self-stock request':
        return const SelfStockRequestScreen();
      case 'self-stock approval':
        return const ApprovalModuleListScreen(
          moduleName: 'SELF_STOCK',
          title: 'Self-Stock Approvals',
        );
      case 'customer create approval':
        return const ApprovalModuleListScreen(
          moduleName: 'CUSTOMER_CREATE',
          title: 'Customer Creation Approvals',
        );
      case 'customer update approval':
        return const ApprovalModuleListScreen(
          moduleName: 'CUSTOMER_UPDATE',
          title: 'Customer Update Approvals',
        );
      case 'customer delete approval':
        return const ApprovalModuleListScreen(
          moduleName: 'CUSTOMER_DELETE',
          title: 'Customer Delete Approvals',
        );
      case 'contact approval':
        return const ApprovalModuleListScreen(
          moduleName: 'CONTACT_CREATE',
          title: 'Contact Approvals',
        );
      case 'visit backdate approval':
        return const ApprovalModuleListScreen(
          moduleName: 'VISIT_BACKDATE',
          title: 'Visit Backdate Approvals',
        );
      case 'approval role management':
        return const UserRoleManagementScreen();
      case 'user & role management':
        return const UserRoleManagementScreen();
      case 'request & approval history':
        return const RequestApprovalHistoryScreen();
      case 'my request history':
        return const MyRequestHistoryScreen();
      case 'visit backdate request':
        return const VisitBackdateRequestScreen();
      case 'view today\'s plan':
        return const PlanListScreen(initialTab: 0);
      case 'view tomorrow\'s plan':
        return const PlanListScreen(initialTab: 1);
      case 'school sampling':
        return const CustomerSampleRequest(customerType: 'School');
      case 'trade sampling':
        return const CustomerSampleRequest(customerType: 'Trade');
      case 'library sampling':
        return const CustomerSampleRequest(customerType: 'Library');
      case 'visit entry':
        return const VisitEntryScreen();
      case 'today\'s plan':
        return const TodayPlanScreen();
      default:
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(title: Text(childMenuName ?? 'Unknown')),
          body: Center(
            child: Text('Screen not implemented for ${linkUrl ?? 'unknown'}'),
          ),
        );
    }
  }

  @override
  void initState() {
    print('HomeScreen: initState');
    AppUtils.getToken();
    AppUtils.loadExecutive();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final checkinState = ref.watch(checkinCheckoutProvider);
    final notificationState = ref.watch(notificationProvider);

    ref.listen(authProvider, (previous, next) {
      print(
          'HomeScreen: authProvider listener - Previous: ${previous?.loginResponse?.executiveBasicData}, Next: ${next.loginResponse?.executiveBasicData}');
      if (next.errorMessage != null &&
          next.errorMessage != _lastErrorMessage &&
          !next.errorMessage!.contains('Password change') &&
          !next.errorMessage!.contains('refresh session')) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        _lastErrorMessage = next.errorMessage;
        if (next.errorMessage == 'Failed to generate token' &&
            ModalRoute.of(context)?.settings.name != '/home') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
      if (next.token == null && next.loginResponse == null) {
        print(
            'HomeScreen: Detected logout, resetting notificationProvider and navigating to /login');
        ref.read(notificationProvider.notifier).reset();
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    ref.listen(checkinCheckoutProvider, (previous, next) {
      if (next.message != null && next.message != previous?.message) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message!),
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(checkinCheckoutProvider.notifier).clearMessageAndEvent();
      }
    });

    ref.listen(notificationProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final Map<String, List<Menu>> menuGroups = {};
    if (authState.menus != null) {
      for (var menu in authState.menus!) {
        final groupName = menu.menuName ?? 'Other';
        menuGroups.putIfAbsent(groupName, () => []).add(menu);
      }
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('CRM Dashboard'),
            elevation: 0,
            backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
            foregroundColor: Colors.blueGrey[900],
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      final executiveId = authState.loginResponse
                                  ?.executiveBasicData?.isNotEmpty ==
                              true
                          ? authState
                              .loginResponse!.executiveBasicData![0].executiveId
                          : 110;
                      print(
                          'HomeScreen: Navigating to NotificationView with executiveId: $executiveId');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationView(
                            executiveId: executiveId,
                          ),
                        ),
                      );
                    },
                  ),
                  if (notificationState.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationState.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          drawer: Drawer(
            child: Container(
              color: Colors.grey[100],
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    height: 200,
                    decoration: const BoxDecoration(
                        color: Color.fromRGBO(252, 242, 219, 1)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 30, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                        height: 25,
                                        width: 82,
                                        child: Image.asset(
                                            "assets/Avant_logo.jpeg")),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.25),
                                    Container(
                                        height: 30,
                                        width: 85,
                                        child: Image.asset(
                                            "assets/dartCRM_logo.jpeg")),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.black,
                                child: Icon(Icons.person,
                                    size: 40, color: Colors.white70),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    authState.loginResponse?.executiveBasicData
                                                ?.isNotEmpty ==
                                            true
                                        ? authState
                                                .loginResponse!
                                                .executiveBasicData![0]
                                                .executiveName ??
                                            'User'
                                        : 'User',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    authState.loginResponse?.executiveBasicData
                                                ?.isNotEmpty ==
                                            true
                                        ? ' ' +
                                            "(${authState.loginResponse!.executiveBasicData![0].executiveCode ?? ''})"
                                        : '',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                authState.loginResponse?.executiveBasicData
                                            ?.isNotEmpty ==
                                        true
                                    ? authState
                                            .loginResponse!
                                            .executiveBasicData![0]
                                            .profileName ??
                                        'Executive'
                                    : 'Executive',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 14),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 80,
                            right: 8,
                            child: ElevatedButton(
                              onPressed: _toggleCheckinCheckout,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: checkinState.isCheckedIn
                                    ? Colors.red[600]
                                    : Colors.green[600],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 9),
                                elevation: 2,
                                minimumSize: const Size(0, 36),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      checkinState.isCheckedIn
                                          ? Icons.logout
                                          : Icons.login,
                                      color: Colors.white,
                                      size: 22),
                                  const SizedBox(width: 6),
                                  Text(
                                    checkinState.isCheckedIn
                                        ? 'Clock Out'
                                        : 'Clock In',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...menuGroups.entries.map((entry) {
                    final groupName = entry.key;
                    final menus = entry.value;
                    return ExpansionTile(
                      minTileHeight: 50,
                      leading: Icon(_getIconForMenu(groupName),
                          color: Colors.blueGrey),
                      title: Text(groupName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      children: menus.isEmpty
                          ? [
                              const ListTile(
                                  title: Text('No Menus'),
                                  textColor: Colors.grey)
                            ]
                          : menus
                              .map(
                                (menu) => GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _getScreenFromLink(
                                            menu.linkUrl, menu.childMenuName),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 50, bottom: 15),
                                    child: Row(
                                      children: [
                                        Icon(
                                            _getIconForMenu(
                                                menu.childMenuName ?? ''),
                                            color: Colors.blueGrey[700]),
                                        SizedBox(width: 10),
                                        Text(
                                            menu.childMenuName ??
                                                'Unknown Menu',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    );
                  }).toList(),
                  const Divider(),
                  SizedBox(height: 10),
                  _buildDrawerItem(
                    icon: Icons.lock,
                    title: 'Change Password',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen()));
                    },
                  ),
                  SizedBox(height: 13),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      print('HomeScreen: Logout triggered');
                      ref.read(notificationProvider.notifier).reset();
                      ref.read(authProvider.notifier).logout();
                      Navigator.pop(context);
                    },
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey[50]!, Colors.white],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Welcome to CRM Dashboard',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (authState.isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? Colors.blueGrey[700],
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                  fontSize: 16,
                  color: color ?? Colors.blueGrey[900],
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMenu(String menuName) {
    switch (menuName.toLowerCase()) {
      case 'school list':
      case 'school sampling':
        return Icons.school;
      case 'trade list':
      case 'trade sampling':
        return Icons.store;
      case 'library list':
      case 'library sampling':
        return Icons.library_books;
      case 'today\'s plan':
      case 'tomorrow\'s plan':
        return Icons.calendar_today;
      case 'visit entry':
        return Icons.map;
      default:
        return Icons.list;
    }
  }
}
