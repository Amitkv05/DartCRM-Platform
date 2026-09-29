import 'package:dart_crm/models/planList/sampling_details.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/title_in_series_widget.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/title_not_in_series.dart';
import 'package:flutter/material.dart';

class TabBarViewWidget extends StatelessWidget {
  final TabController tabController;
  final SeriesAndClassLevelResponse? classLevelResponse;
  final Function(List<Map<String, dynamic>>) onSelectionSeries;
  final Function(List<Map<String, dynamic>>) onSelectionNotInSeries;
  final List<Map<String, dynamic>> currentSeriesData;
  final List<Map<String, dynamic>> currentNotSeriesData;

  const TabBarViewWidget({
    super.key,
    required this.tabController,
    required this.classLevelResponse,
    required this.onSelectionSeries,
    required this.onSelectionNotInSeries,
    required this.currentSeriesData,
    required this.currentNotSeriesData,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      controller: tabController,
      children: [
        TitleInSeriesPage(
          classLevelResponse: classLevelResponse,
          contextType: 'selfStock',
          onSelection: onSelectionSeries,
          currentSelected: currentSeriesData,
        ),
        TitleNotInSeriesPage(
          contextType: 'selfStock',
          onSelection: onSelectionNotInSeries,
          currentSelected: currentNotSeriesData,
        ),
      ],
    );
  }
}
