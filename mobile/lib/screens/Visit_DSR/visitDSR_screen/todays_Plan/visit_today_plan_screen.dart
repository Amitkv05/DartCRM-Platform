import 'package:dart_crm/models/planList/plan.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/plan_provider.dart';
import 'package:dart_crm/screens/Visit_DSR/DSR_entry/dsr_entry.dart';
import 'package:dart_crm/screens/Visit_DSR/visitDSR_screen/todays_Plan/visit_details_screen.dart';
import 'package:dart_crm/screens/homeScreen/widget/userHeader.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodayPlanScreen extends ConsumerStatefulWidget {
  const TodayPlanScreen({super.key});

  @override
  ConsumerState<TodayPlanScreen> createState() => _TodayPlanScreenState();
}

class _TodayPlanScreenState extends ConsumerState<TodayPlanScreen> {
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Today\'s Plan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: TColors.primary,
        elevation: 0,
      ),
      body: _buildPlanTab(planState, true),
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

    final plans = planState.planResponse!.todayPlan;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Userheader(),
          _buildPlanSection(plans),
        ],
      ),
    );
  }

  Widget _buildPlanSection(List<Plan> plans) {
    return Padding(
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
                      builder: (_) => VisitDetailsScreen(plan: plan),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DSREntryScreen(plan: plan),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        Icon(Icons.directions_bike,
                                            color: TColors.buttonPrimary,
                                            size: 30),
                                        Text(
                                          "DSR Entry",
                                          style: TextStyle(
                                            color: TColors.buttonPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
}
