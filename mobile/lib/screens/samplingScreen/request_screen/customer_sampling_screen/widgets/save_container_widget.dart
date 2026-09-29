import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/planList/dsr_sampling_details.dart'
    as dsrsampling;
import 'package:dart_crm/models/ship_to.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/dsr_entry_provider.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';

class SavedContainersWidget extends ConsumerWidget {
  final List<List<dsrsampling.TitleData>> selectedTitleGroups;
  final List<Map<String, dynamic>> containerDetails;
  final List<sampling.SamplingContact> sampleToList;
  final List<dsrsampling.Series> seriesList;
  final List<String> samplingTypeOptions;
  final Function(int) onRemoveContainer;
  final Function(int, String?, String?, String?, List<dsrsampling.TitleData>,
      List<ShipTo>) onContainerDetailsChanged;
  final Function(List<dsrsampling.TitleData>) onTitlesSelected;
  final String token;
  final int customerId;
  final String customerType;
  final int executiveId;
  final int customerContactId;
  final GlobalKey<FormState> formKey;
  final Function(int, String?, int?) onSearchPressed;

  const SavedContainersWidget({
    super.key,
    required this.selectedTitleGroups,
    required this.containerDetails,
    required this.sampleToList,
    required this.seriesList,
    required this.samplingTypeOptions,
    required this.onRemoveContainer,
    required this.onContainerDetailsChanged,
    required this.onTitlesSelected,
    required this.token,
    required this.customerId,
    required this.customerType,
    required this.executiveId,
    required this.customerContactId,
    required this.formKey,
    required this.onSearchPressed,
  });

  Future<List<ShipTo>> _fetchShipToList(String? sampleTo, WidgetRef ref,
      BuildContext context, int groupIndex) async {
    if (sampleTo == null || groupIndex >= containerDetails.length) {
      if (groupIndex < containerDetails.length) {
        containerDetails[groupIndex]['shipTo'] = null;
        containerDetails[groupIndex]['shipToList'] = <ShipTo>[];
        containerDetails[groupIndex]['isLoadingShipTo'] = false;
        onContainerDetailsChanged(
          groupIndex,
          null,
          null,
          containerDetails[groupIndex]['samplingType'],
          selectedTitleGroups[groupIndex],
          <ShipTo>[],
        );
      }
      return [];
    }

    containerDetails[groupIndex]['isLoadingShipTo'] = true;

    try {
      final request = ShipToRequest(
        executiveId: executiveId,
        customerId: customerId,
        customerType: customerType,
        customerContactId: int.tryParse(sampleTo) ??
            (customerContactId > 0 ? customerContactId : 0),
        sampleGiven: 'TO_BE_DISPATCHED',
      );

      final response = await ref.read(dsrEntryProvider.notifier).fetchShipTo(
            request: request,
            token: token,
          );

      List<ShipTo> shipToList = [];
      if (response.status == 'Success' && response.shipTo!.isNotEmpty) {
        // Deduplicate shipToList by shipToId
        final uniqueShipTo = <String, ShipTo>{};
        for (var shipTo in response.shipTo!) {
          uniqueShipTo[shipTo.shipToId] = shipTo;
        }
        shipToList = uniqueShipTo.values.toList();
      } else {
        shipToList = <ShipTo>[];
      }

      if (groupIndex < containerDetails.length) {
        containerDetails[groupIndex]['isLoadingShipTo'] = false;
        containerDetails[groupIndex]['shipToList'] = shipToList;
        final currentShipTo = containerDetails[groupIndex]['shipTo'] as String?;
        if (currentShipTo == null ||
            !shipToList.any((shipTo) => shipTo.shipToId == currentShipTo)) {
          containerDetails[groupIndex]['shipTo'] = null;
        }
        onContainerDetailsChanged(
          groupIndex,
          containerDetails[groupIndex]['sampleTo'],
          containerDetails[groupIndex]['shipTo'],
          containerDetails[groupIndex]['samplingType'],
          selectedTitleGroups[groupIndex],
          List<ShipTo>.from(containerDetails[groupIndex]['shipToList']),
        );
      }

      if (response.status != 'Success' || response.shipTo!.isEmpty) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.status != 'Success'
                    ? 'Failed to fetch ship to options: ${response.status}'
                    : 'No shipping address is available for this customer/contact',
              ),
              backgroundColor: Colors.red,
            ),
          );
        });
      }

      return shipToList;
    } catch (e) {
      if (groupIndex < containerDetails.length) {
        containerDetails[groupIndex]['isLoadingShipTo'] = false;
        containerDetails[groupIndex]['shipToList'] = <ShipTo>[];
        onContainerDetailsChanged(
          groupIndex,
          containerDetails[groupIndex]['sampleTo'],
          null,
          containerDetails[groupIndex]['samplingType'],
          selectedTitleGroups[groupIndex],
          <ShipTo>[],
        );
      }
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching ship to options: $e')),
        );
      });
      return [];
    }
  }

  void _updateTitleQuantity(
      BuildContext context, int groupIndex, int titleIndex, int newQuantity) {
    // Validate indices to prevent RangeError
    if (groupIndex >= selectedTitleGroups.length ||
        groupIndex >= containerDetails.length ||
        titleIndex >= selectedTitleGroups[groupIndex].length) {
      print('Invalid indices: groupIndex=$groupIndex, titleIndex=$titleIndex, '
          'selectedTitleGroups.length=${selectedTitleGroups.length}, '
          'containerDetails.length=${containerDetails.length}');
      return;
    }

    if (newQuantity <= 0) {
      // Remove the title
      selectedTitleGroups[groupIndex].removeAt(titleIndex);
      if (selectedTitleGroups[groupIndex].isEmpty) {
        // If the container is empty, remove it
        SchedulerBinding.instance.addPostFrameCallback((_) {
          onRemoveContainer(groupIndex);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Series removed')),
          );
        });
      } else {
        // Update titles and container details
        final allTitles = selectedTitleGroups.expand((group) => group).toList();
        onTitlesSelected(allTitles);
        if (groupIndex < containerDetails.length) {
          onContainerDetailsChanged(
            groupIndex,
            containerDetails[groupIndex]['sampleTo'],
            containerDetails[groupIndex]['shipTo'],
            containerDetails[groupIndex]['samplingType'],
            selectedTitleGroups[groupIndex],
            List<ShipTo>.from(containerDetails[groupIndex]['shipToList']),
          );
        }
      }
    } else {
      // Update quantity
      final updatedTitle = dsrsampling.TitleData(
        bookId: selectedTitleGroups[groupIndex][titleIndex].bookId,
        title: selectedTitleGroups[groupIndex][titleIndex].title,
        quantity: newQuantity,
        isbn: selectedTitleGroups[groupIndex][titleIndex].isbn,
        price: selectedTitleGroups[groupIndex][titleIndex].price,
        listPrice: selectedTitleGroups[groupIndex][titleIndex].listPrice,
        bookNum: selectedTitleGroups[groupIndex][titleIndex].bookNum,
        image: selectedTitleGroups[groupIndex][titleIndex].image,
        physicalStock:
            selectedTitleGroups[groupIndex][titleIndex].physicalStock,
        author: selectedTitleGroups[groupIndex][titleIndex].author,
        imageUrl: selectedTitleGroups[groupIndex][titleIndex].imageUrl,
        bookType: selectedTitleGroups[groupIndex][titleIndex].bookType,
        seriesId: selectedTitleGroups[groupIndex][titleIndex].seriesId,
        subjectId: selectedTitleGroups[groupIndex][titleIndex].subjectId,
        seriesName: selectedTitleGroups[groupIndex][titleIndex].seriesName,
      );
      selectedTitleGroups[groupIndex][titleIndex] = updatedTitle;
      final allTitles = selectedTitleGroups.expand((group) => group).toList();
      onTitlesSelected(allTitles);
      if (groupIndex < containerDetails.length) {
        onContainerDetailsChanged(
          groupIndex,
          containerDetails[groupIndex]['sampleTo'],
          containerDetails[groupIndex]['shipTo'],
          containerDetails[groupIndex]['samplingType'],
          selectedTitleGroups[groupIndex],
          List<ShipTo>.from(containerDetails[groupIndex]['shipToList']),
        );
      }
    }
    print('SavedContainersWidget: After update - groupIndex=$groupIndex, '
        'titles=${selectedTitleGroups.length > groupIndex ? selectedTitleGroups[groupIndex].length : 0}, '
        'containerDetails.length=${containerDetails.length}');
  }

  bool _isSampleToValidForSeries(
      String? sampleTo, String? seriesId, int currentGroupIndex) {
    if (sampleTo == null) {
      return true;
    }
    // Treat seriesId == '0' as non-series titles, but still check for duplicates
    for (int i = 0; i < containerDetails.length; i++) {
      if (i != currentGroupIndex &&
          containerDetails[i]['seriesId'] == seriesId &&
          containerDetails[i]['sampleTo'] == sampleTo) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Normalize and deduplicate samplingTypeOptions
    final uniqueSamplingTypeOptions = samplingTypeOptions
        .map((type) => type.trim().toLowerCase())
        .toSet()
        .map((type) => samplingTypeOptions.firstWhere(
              (original) => original.trim().toLowerCase() == type,
              orElse: () => type,
            ))
        .toList();
    print('Raw samplingTypeOptions: $samplingTypeOptions');
    print('Unique samplingTypeOptions: $uniqueSamplingTypeOptions');
    print('containerDetails: $containerDetails');

    // Check for duplicates and schedule SnackBar if needed
    if (uniqueSamplingTypeOptions.length != samplingTypeOptions.length) {
      print(
          'Warning: Duplicates or case variations found in samplingTypeOptions. '
          'Original: $samplingTypeOptions, Unique: $uniqueSamplingTypeOptions');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Duplicate sampling types detected, using unique values'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }

    // If either selectedTitleGroups or containerDetails is empty, return empty widget
    if (selectedTitleGroups.isEmpty || containerDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ensure lists are synchronized
    if (selectedTitleGroups.length != containerDetails.length) {
      print(
          'Warning: Mismatch between selectedTitleGroups.length=${selectedTitleGroups.length} '
          'and containerDetails.length=${containerDetails.length}');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected Title data mismatch, please try again'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: formKey,
            child: Column(
              children: [
                ...selectedTitleGroups.asMap().entries.map((groupEntry) {
                  final groupIndex = groupEntry.key;
                  final titles = groupEntry.value;
                  // Skip rendering if titles are empty or groupIndex is invalid
                  if (titles.isEmpty || groupIndex >= containerDetails.length) {
                    print('Skipping render for groupIndex=$groupIndex: '
                        'titles.isEmpty=${titles.isEmpty}, '
                        'containerDetails.length=${containerDetails.length}');
                    return const SizedBox.shrink();
                  }
                  final container = containerDetails[groupIndex];
                  final sampleToName = sampleToList
                      .firstWhere(
                        (contact) =>
                            contact.customerContactId.toString() ==
                            container['sampleTo'],
                        orElse: () => sampling.SamplingContact(
                            customerContactId: 0, customerName: 'Unknown'),
                      )
                      .customerName;
                  final shipToList = container['shipToList'] as List<ShipTo>;
                  final selectedShipTo = (container['shipTo'] != null &&
                          shipToList.any((shipTo) =>
                              shipTo.shipToId == container['shipTo']))
                      ? container['shipTo']
                      : null;
                  final shipTo = shipToList.firstWhere(
                    (shipTo) => shipTo.shipToId == container['shipTo'],
                    orElse: () => ShipTo(
                      shipToId: '0_default',
                      shipToName: 'No address available',
                      shipToAddress: null,
                    ),
                  );
                  final shipToName = shipTo.shipToName;
                  final shipToAddress =
                      shipTo.shipToAddress ?? 'No address provided';
                  final seriesId = container['seriesId'] as String?;
                  final classLevelId = container['classLevelId'] as int?;
                  final seriesName = seriesId == null || seriesId == '0'
                      ? 'Non-Series Titles'
                      : titles.isNotEmpty && titles[0].seriesName != null
                          ? titles[0].seriesName!
                          : seriesList
                              .firstWhere(
                                (series) =>
                                    series.seriesId.toString() == seriesId,
                                orElse: () => dsrsampling.Series(
                                    seriesId: 0, seriesName: 'Unknown Series'),
                              )
                              .seriesName;

                  // Sanitize selectedSamplingType only if samplingTypeOptions is not empty
                  final selectedSamplingType =
                      container['samplingType'] as String?;
                  String? normalizedSelectedSamplingType = selectedSamplingType;
                  if (samplingTypeOptions.isNotEmpty &&
                      selectedSamplingType != null) {
                    normalizedSelectedSamplingType =
                        uniqueSamplingTypeOptions.firstWhere(
                      (type) =>
                          type.trim().toLowerCase() ==
                          selectedSamplingType.trim().toLowerCase(),
                      orElse: () => "Not Selected",
                    );
                    if (selectedSamplingType !=
                        normalizedSelectedSamplingType) {
                      print(
                          'Warning: Invalid samplingType "$selectedSamplingType" for groupIndex=$groupIndex, '
                          'resetting to $normalizedSelectedSamplingType');
                      container['samplingType'] =
                          normalizedSelectedSamplingType;
                      onContainerDetailsChanged(
                        groupIndex,
                        container['sampleTo'],
                        container['shipTo'],
                        normalizedSelectedSamplingType,
                        titles,
                        List<ShipTo>.from(container['shipToList']),
                      );
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Invalid sampling type "$selectedSamplingType" reset to '
                                '${normalizedSelectedSamplingType ?? "Not Selected"}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      });
                    }
                  }

                  // Fetch class level name
                  final authState = ref.read(authProvider);
                  final classLevelFuture = ref
                      .read(dsrEntryProvider.notifier)
                      .fetchSeriesAndClassLevel(
                        request: sampling.SeriesAndClassLevelRequest(
                          profileId: authState.loginResponse!
                                  .executiveBasicData?[0].profileId ??
                              5,
                          executiveId: executiveId,
                        ),
                        token: token,
                      )
                      .then((response) => response.classLevelList
                          .firstWhere(
                            (level) => level.classLevelId == classLevelId,
                            orElse: () => sampling.ClassLevel(
                                classLevelId: 0, classLevelName: 'Unknown'),
                          )
                          .classLevelName);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: TColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  seriesName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[900],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red[400],
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    SchedulerBinding.instance
                                        .addPostFrameCallback((_) {
                                      onRemoveContainer(groupIndex);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Series removed')),
                                      );
                                    });
                                  },
                                  tooltip: 'Delete Container',
                                ),
                              ],
                            ),
                            const Divider(color: Colors.black),
                            const SizedBox(height: 10),
                            Visibility(
                              visible: false, // Hides the TextFormField
                              maintainState:
                                  true, // Keeps the widget state alive
                              maintainAnimation:
                                  true, // Maintains animations (if any)
                              maintainSize: false,
                              child: TextFormField(
                                initialValue:
                                    selectedSamplingType ?? 'Not Selected',
                                enabled: false,
                                decoration: InputDecoration(
                                  label: RichText(
                                    text: TextSpan(
                                      text: "Sampling Type",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text: ' *',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: TColors.borderColor),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: TColors.borderColor),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                ),
                                style: TextStyle(color: Colors.grey[800]),
                                validator: (value) =>
                                    value == null || value == 'Not Selected'
                                        ? 'Please select a sampling type'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: container['sampleTo'],
                              decoration: InputDecoration(
                                label: RichText(
                                  text: TextSpan(
                                    text: "Sample To",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: ' *',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text("Select"),
                                ),
                                ...sampleToList.map((sampleTo) {
                                  return DropdownMenuItem<String>(
                                    value:
                                        sampleTo.customerContactId.toString(),
                                    child: Text(sampleTo.customerName),
                                  );
                                }).toList(),
                              ],
                              onChanged: container['isLoadingShipTo']
                                  ? null
                                  : (value) {
                                      if (value != null &&
                                          !_isSampleToValidForSeries(
                                              value, seriesId, groupIndex)) {
                                        container['shipTo'] = null;
                                        container['shipToList'] = <ShipTo>[];
                                        onContainerDetailsChanged(
                                          groupIndex,
                                          container['sampleTo'],
                                          null,
                                          container['samplingType'],
                                          titles,
                                          <ShipTo>[],
                                        );
                                        SchedulerBinding.instance
                                            .addPostFrameCallback((_) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                seriesId == '0' ||
                                                        seriesId == null
                                                    ? 'This Sample To is already used in another non-series titles'
                                                    : 'This Sample To is already used in another series',
                                                // : 'This Sample To is already used in another series "$seriesName"',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        });
                                        formKey.currentState?.validate();
                                        return;
                                      }
                                      if (value != null) {
                                        SchedulerBinding.instance
                                            .addPostFrameCallback((_) {
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                        });
                                      }
                                      container['sampleTo'] = value;
                                      container['shipTo'] = null;
                                      container['shipToList'] = <ShipTo>[];
                                      if (value != null) {
                                        _fetchShipToList(
                                            value, ref, context, groupIndex);
                                      }
                                      formKey.currentState?.validate();
                                    },
                              hint: Text(
                                container['isLoadingShipTo']
                                    ? "Loading sample to options..."
                                    : "Select a sample to",
                              ),
                              validator: (value) => value == null
                                  ? 'Please select a sample to'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: selectedShipTo,
                              decoration: InputDecoration(
                                label: RichText(
                                  text: TextSpan(
                                    text: "Ship To",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: ' *',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.white),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                              ),
                              menuMaxHeight: 150,
                              dropdownColor: Colors.white,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text("Select",
                                      style: TextStyle(fontSize: 14)),
                                ),
                                ...shipToList.map((shipTo) {
                                  return DropdownMenuItem<String>(
                                    value: shipTo.shipToId,
                                    child: Text(
                                      shipTo.shipToName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: container['isLoadingShipTo'] ||
                                      shipToList.isEmpty
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        SchedulerBinding.instance
                                            .addPostFrameCallback((_) {
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                        });
                                      }
                                      container['shipTo'] = value;
                                      onContainerDetailsChanged(
                                        groupIndex,
                                        container['sampleTo'],
                                        value,
                                        container['samplingType'],
                                        titles,
                                        List<ShipTo>.from(
                                            container['shipToList']),
                                      );
                                      formKey.currentState?.validate();
                                    },
                              hint: Text(
                                container['isLoadingShipTo']
                                    ? "Loading ship to options..."
                                    : shipToList.isEmpty
                                        ? "No ship to options available"
                                        : "Select a ship to",
                                style: const TextStyle(fontSize: 14),
                              ),
                              validator: (value) => value == null
                                  ? 'Please select a ship to'
                                  : null,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black),
                              isDense: true,
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                text: "Address: ",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: shipToAddress,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: titles.length == 1
                                  ? MediaQuery.of(context).size.height * 0.12
                                  : titles.length == 2
                                      ? MediaQuery.of(context).size.height *
                                          0.28
                                      : MediaQuery.of(context).size.height *
                                          0.41,
                              child: ListView.builder(
                                physics: titles.length <= 3
                                    ? const NeverScrollableScrollPhysics()
                                    : const AlwaysScrollableScrollPhysics(),
                                itemCount: titles.length,
                                itemBuilder: (context, index) {
                                  final title = titles[index];
                                  return Card(
                                    color: Colors.white,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Container(
                                              width: 50,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                image: DecorationImage(
                                                  image: title.imageUrl !=
                                                              null &&
                                                          title.imageUrl!
                                                              .isNotEmpty
                                                      ? NetworkImage(
                                                          title.imageUrl!)
                                                      : const AssetImage(
                                                          'assets/books/book.avif'),
                                                  fit: BoxFit.cover,
                                                  onError: (exception,
                                                          stackTrace) =>
                                                      const AssetImage(
                                                          'assets/books/book.avif'),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title.title!,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[900],
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                RichText(
                                                  text: TextSpan(
                                                    text: "Book Type: ",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[800],
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            "${title.bookType}",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[700],
                                                          fontWeight:
                                                              FontWeight.normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        text: "Quantity: ",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[800],
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        children: [
                                                          TextSpan(
                                                            text:
                                                                "${title.quantity}",
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[700],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10),
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[300],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(50),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          InkWell(
                                                            onTap: () {
                                                              _updateTitleQuantity(
                                                                context,
                                                                groupIndex,
                                                                index,
                                                                title.quantity -
                                                                    1,
                                                              );
                                                            },
                                                            child: Icon(
                                                                Icons.remove,
                                                                size: 25,
                                                                color:
                                                                    Colors.red),
                                                          ),
                                                          const SizedBox(
                                                              width: 5),
                                                          Text(
                                                            title.quantity
                                                                .toString(),
                                                            style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          const SizedBox(
                                                              width: 5),
                                                          InkWell(
                                                            onTap: () {
                                                              if (title
                                                                      .quantity <
                                                                  10) {
                                                                _updateTitleQuantity(
                                                                  context,
                                                                  groupIndex,
                                                                  index,
                                                                  title.quantity +
                                                                      1,
                                                                );
                                                              } else {
                                                                SchedulerBinding
                                                                    .instance
                                                                    .addPostFrameCallback(
                                                                        (_) {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    const SnackBar(
                                                                      content: Text(
                                                                          "Cannot exceed limit of 10"),
                                                                    ),
                                                                  );
                                                                });
                                                              }
                                                            },
                                                            child: Icon(
                                                                Icons.add,
                                                                size: 25,
                                                                color: Colors
                                                                    .green),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<String>(
                              future: Future.value(seriesName),
                              builder: (context, snapshot) {
                                return Visibility(
                                  visible: false, // Hides the TextFormField
                                  maintainState:
                                      true, // Keeps the widget state alive
                                  maintainAnimation:
                                      true, // Maintains animations (if any)
                                  maintainSize: false,
                                  child: TextFormField(
                                    initialValue:
                                        snapshot.data ?? 'Non-Series Titles',
                                    enabled: false,
                                    decoration: InputDecoration(
                                      labelText: 'Series',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: TColors.borderColor),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: TColors.borderColor),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                    ),
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                );
                              },
                            ),
                            FutureBuilder<String>(
                              future: classLevelFuture,
                              builder: (context, snapshot) {
                                return Visibility(
                                  visible: false, // Hides the TextFormField
                                  maintainState:
                                      true, // Keeps the widget state alive
                                  maintainAnimation:
                                      true, // Maintains animations (if any)
                                  maintainSize: false,
                                  child: TextFormField(
                                    initialValue:
                                        snapshot.data ?? 'All Class Levels',
                                    enabled: false,
                                    decoration: InputDecoration(
                                      labelText: 'Class Level',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: TColors.borderColor),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: TColors.borderColor),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                    ),
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                );
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (container['isLoadingShipTo']) {
                                    SchedulerBinding.instance
                                        .addPostFrameCallback((_) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please wait, loading ship to options')),
                                      );
                                    });
                                    return;
                                  }
                                  onSearchPressed(
                                      groupIndex, seriesId, classLevelId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TColors.buttonPrimary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'Add More',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
