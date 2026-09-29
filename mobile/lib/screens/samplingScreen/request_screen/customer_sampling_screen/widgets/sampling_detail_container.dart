import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/planList/dsr_sampling_details.dart'
    as dsrsampling;
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';

class SamplingDetailsContainer extends StatelessWidget {
  final dsrsampling.dsrSamplingDetailsResponse samplingResponse;
  final String? localSelectedSamplingType;
  final Function(String?) onSamplingTypeChanged;
  final TabController tabController;
  final List<dsrsampling.Series> seriesList;
  final bool isLoadingSeries;
  final String? selectedSeriesId;
  final Function(String?) onSeriesChanged;
  final dsrsampling.dsrSeriesAndClassLevelResponse? classLevelResponse;
  final int? seriesClassLevel;
  final Function(int?) onClassLevelChanged;
  final bool isLoadingSampleTo;
  final bool isLoadingSearch;
  final Function(bool) onSearchPressed;
  final TextEditingController isbnSearchController;

  const SamplingDetailsContainer({
    super.key,
    required this.samplingResponse,
    required this.localSelectedSamplingType,
    required this.onSamplingTypeChanged,
    required this.tabController,
    required this.seriesList,
    required this.isLoadingSeries,
    required this.selectedSeriesId,
    required this.onSeriesChanged,
    required this.classLevelResponse,
    required this.seriesClassLevel,
    required this.onClassLevelChanged,
    required this.isLoadingSampleTo,
    required this.isLoadingSearch,
    required this.onSearchPressed,
    required this.isbnSearchController,
  });

  void _showSnackBar(BuildContext context, String message) {
    // Clear any existing snack bars to prevent stacking
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show new snack bar only if none is currently visible
    if (ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: TColors.icon),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sampling Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.black),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: localSelectedSamplingType,
              decoration: InputDecoration(
                labelText: "Sampling Type",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: TColors.borderColor),
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
              ),
              dropdownColor: Colors.white,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Select'),
                ),
                ...samplingResponse.samplingType.map((type) {
                  return DropdownMenuItem<String>(
                    value: type.samplingType,
                    child: Text(type.samplingType),
                  );
                }).toList(),
              ],
              onChanged: (String? value) {
                print('Selected Sampling Type: $value');
                onSamplingTypeChanged(value);
                ScaffoldMessenger.of(context).clearSnackBars();
                final formState = Form.of(context);
                formState?.validate();
              },
              validator: (value) {
                print('SamplingType Validator: value=$value');
                if (value == null || value.isEmpty) {
                  return 'Please select a sampling type';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TabBar(
              controller: tabController,
              tabs: const [
                Tab(text: "Titles in Series"),
                Tab(text: "Titles not in Series"),
              ],
              labelColor: TColors.icon,
              unselectedLabelColor: Colors.grey,
            ),
            SizedBox(
              height: 150,
              child: TabBarView(
                controller: tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedSeriesId,
                          decoration: InputDecoration(
                            labelText: "Select Series",
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: TColors.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: TColors.borderColor),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text("Select"),
                            ),
                            ...seriesList.map((series) {
                              return DropdownMenuItem<String>(
                                value: series.seriesId.toString(),
                                child: Text(
                                  series.seriesName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: onSeriesChanged,
                          hint: isLoadingSeries
                              ? const Text("Loading series...")
                              : const Text("Select a series"),
                        ),
                        const SizedBox(height: 10),
                        if (classLevelResponse != null)
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: seriesClassLevel,
                                  decoration: InputDecoration(
                                    labelText: "Class Level",
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: TColors.borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: TColors.borderColor),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                  dropdownColor: Colors.white,
                                  items: [
                                    const DropdownMenuItem<int>(
                                      value: null,
                                      child: Text("Select"),
                                    ),
                                    ...classLevelResponse!.classLevelList
                                        .map((level) {
                                      return DropdownMenuItem<int>(
                                        value: level.classLevelId,
                                        child: Text(level.classLevelName),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: onClassLevelChanged,
                                  hint: const Text("Select a class level"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed:
                                    !isLoadingSampleTo && !isLoadingSearch
                                        ? () {
                                            if (selectedSeriesId == null) {
                                              _showSnackBar(context,
                                                  'Please select a series');
                                              return;
                                            }
                                            onSearchPressed(true);
                                          }
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TColors.buttonPrimary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: isLoadingSearch
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text("Search",
                                        style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: TextFormField(
                            controller: isbnSearchController,
                            decoration: InputDecoration(
                              labelText: "Search ISBN/Title",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: TColors.icon),
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: !isLoadingSampleTo && !isLoadingSearch
                              ? () {
                                  if (isbnSearchController.text.isEmpty) {
                                    _showSnackBar(context,
                                        'Please enter an ISBN or Title');
                                    return;
                                  }
                                  onSearchPressed(false);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.buttonPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoadingSearch
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Search",
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ],
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
}
