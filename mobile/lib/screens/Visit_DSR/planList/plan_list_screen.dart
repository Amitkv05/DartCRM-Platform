import 'package:dart_crm/models/planList/plan.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/plan_provider.dart';
import 'package:dart_crm/screens/Visit_DSR/planList/plan_list_details_screen.dart';
import 'package:dart_crm/screens/Visit_DSR/visitDSR_screen/todays_Plan/visit_details_screen.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanListScreen extends ConsumerStatefulWidget {
  final int initialTab; // New parameter for initial tab index

  const PlanListScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends ConsumerState<PlanListScreen> {
  @override
  void initState() {
    super.initState();
    // Delay the state modification until after the widget tree is built
    Future.microtask(() {
      final authState = ref.read(authProvider);
      final executiveId =
          authState.loginResponse?.executiveBasicData?[0].executiveId ?? 0;
      ref.read(planProvider.notifier).getPlanList(executiveId: executiveId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab, // Use initialTab to set the active tab
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
          elevation: 4,
          title: const Text(
            'Travel Plan',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black26,
            tabs: [
              Tab(text: "Today's Plan"),
              Tab(text: "Tomorrow's Plan"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPlanTab(planState, true),
            _buildPlanTab(planState, false),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTab(PlanState planState, bool isToday) {
    if (planState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (planState.errorMessage != null) {
      return Center(child: Text('Error: ${planState.errorMessage}'));
    } else if (planState.planResponse == null ||
        planState.planResponse!.status != 'Success') {
      return const Center(child: Text('No plans available'));
    }

    final plans = isToday
        ? planState.planResponse!.todayPlan
        : planState.planResponse!.tomorrowPlan;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanSection(isToday ? "Today's Plan" : "Tomorrow's Plan", plans,
              isToday: isToday),
        ],
      ),
    );
  }

  Widget _buildPlanSection(String title, List<Plan> plans,
          {required bool isToday}) =>
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (plans.isEmpty)
              const Text('No plans available')
            else
              ...plans.map((plan) => GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PlanListDetailsScreen(plan: plan),
                      ));
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
                        // boxShadow: [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    plan.customerName,
                                    style: TextStyle(
                                        color: TColors.headerText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  Text(
                                    " (${plan.customerCode})",
                                    style: TextStyle(
                                        color: TColors.headerText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // const Icon(Icons.location_history,
                                          //     color: Colors.black54, size: 16),
                                          // const SizedBox(width: 5),
                                          Text(
                                            plan.address,
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          // const Icon(Icons.location_pin,
                                          //     color: Colors.black54, size: 16),
                                          // const SizedBox(width: 5),
                                          Text(
                                            "${plan.city}, ${plan.state}",
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Text(
                                            'Mail:',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            plan.emailId,
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Text(
                                            'Type:',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            plan.customerType,
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      // const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Text(
                                            'Purpose:',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            plan.visitPurpose,
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      // const SizedBox(height: 4),
                                    ],
                                  ),
                                  // Spacer(),
                                  // Padding(
                                  //   padding: const EdgeInsets.only(right: 8),
                                  //   child: GestureDetector(
                                  //     onTap: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) =>
                                  //         DSREntryScreen(plan: plan),
                                  //   ),
                                  // );
                                  //     },
                                  //     child: Column(
                                  //       children: [
                                  //         Icon(Icons.directions_bike,
                                  //             color: TColors.buttonHover,
                                  //             size: 30),
                                  //         Text(
                                  //           "DSR Entry",
                                  //           style: TextStyle(
                                  //             color: TColors.buttonHover,
                                  //             fontWeight: FontWeight.w800,
                                  //             fontSize: 13,
                                  //           ),
                                  //         ),
                                  //       ],
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ],
                          ),
                          // Divider(),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      );
}
