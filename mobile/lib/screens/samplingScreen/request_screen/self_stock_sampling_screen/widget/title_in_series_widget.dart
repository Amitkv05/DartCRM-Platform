import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/planList/dsr_sampling_details.dart'
    as dsrsampling;
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/dsr_entry_provider.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/self_stock_book_search_popup.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TitleInSeriesPage extends ConsumerStatefulWidget {
  final String contextType;
  final sampling.SeriesAndClassLevelResponse? classLevelResponse;
  final Function(List<Map<String, dynamic>>) onSelection;
  final List<Map<String, dynamic>> currentSelected;

  const TitleInSeriesPage({
    super.key,
    this.classLevelResponse,
    required this.contextType,
    required this.onSelection,
    required this.currentSelected,
  });

  @override
  _TitleInSeriesPageState createState() => _TitleInSeriesPageState();
}

class _TitleInSeriesPageState extends ConsumerState<TitleInSeriesPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  List<dsrsampling.TitleData> selectedTitles = [];
  int? selectedClassLevel;
  String? selectedSeriesId;
  List<sampling.Series> seriesList = [];
  bool isLoadingSeries = false;
  bool showLoadingHint = false;
  bool isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();

    if (widget.classLevelResponse != null &&
        widget.classLevelResponse!.classLevelList.isNotEmpty) {
      selectedClassLevel = -1;
      _fetchSeriesList();
    } else {
      selectedClassLevel = null;
      seriesList = [];
      selectedSeriesId = null;
    }
  }

  @override
  void didUpdateWidget(TitleInSeriesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.classLevelResponse != oldWidget.classLevelResponse) {
      setState(() {
        if (widget.classLevelResponse != null &&
            widget.classLevelResponse!.classLevelList.isNotEmpty) {
          selectedClassLevel = -1;
          seriesList = [];
          selectedSeriesId = null;
          _fetchSeriesList();
        } else {
          selectedClassLevel = null;
          seriesList = [];
          selectedSeriesId = null;
        }
      });
    }
  }

  void _fetchSeriesList() async {
    print('Fetching series list for classLevel: $selectedClassLevel');
    print('Current selectedSeriesId before fetch: $selectedSeriesId');
    setState(() {
      isLoadingSeries = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && isLoadingSeries) {
        setState(() {
          showLoadingHint = true;
        });
      }
    });

    final authState = ref.read(authProvider);
    final executiveId =
        authState.loginResponse?.executiveBasicData?[0].executiveId;
    final token = authState.token ?? '';

    try {
      final response =
          await ref.read(dsrEntryProvider.notifier).fetchSeriesAndClassLevel(
                request: sampling.SeriesAndClassLevelRequest(
                  profileId: authState
                          .loginResponse?.executiveBasicData?[0].profileId ??
                      5,
                  executiveId: executiveId,
                  classLevelId:
                      selectedClassLevel == -1 ? null : selectedClassLevel,
                ),
                token: token,
              );

      if (mounted) {
        setState(() {
          isLoadingSeries = false;
          showLoadingHint = false;
          if (response.status == 'Success' && response.seriesList.isNotEmpty) {
            final uniqueSeries = response.seriesList
                .fold<Map<String, sampling.Series>>(
                  {},
                  (map, series) => map..[series.seriesId.toString()] = series,
                )
                .values
                .toList();
            seriesList = uniqueSeries;
            print(
                'New Series List: ${seriesList.map((s) => 'ID: ${s.seriesId}, Name: ${s.seriesName}').toList()}');
            if (selectedSeriesId != null &&
                !seriesList.any((series) =>
                    series.seriesId.toString() == selectedSeriesId)) {
              print(
                  'Selected series ID $selectedSeriesId not found in new series list, resetting to null');
              selectedSeriesId = null;
            } else {
              print(
                  'Retained selectedSeriesId: $selectedSeriesId in new series list');
            }
          } else {
            print('Failed to load series');
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load series')),
            );
            seriesList = [];
            selectedSeriesId = null;
          }
          print('Selected Series ID after fetch: $selectedSeriesId');
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoadingSeries = false;
          showLoadingHint = false;
          seriesList = [];
          selectedSeriesId = null;
          print('Error fetching series: $error');
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching series: $error')),
          );
        });
      }
    }
  }

  void _showBookSearchDialog() {
    if (selectedClassLevel == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class level first')),
      );
      return;
    }
    if (selectedSeriesId == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a series')),
      );
      return;
    }

    setState(() {
      isSearching = true;
    });

    final authState = ref.read(authProvider);
    final executiveId =
        authState.loginResponse?.executiveBasicData?[0].executiveId ?? 0;
    final token = authState.token ?? '';

    final request = dsrsampling.FetchTitlesRequest(
      executiveId: executiveId,
      seriesId: selectedSeriesId,
      classLevel: selectedClassLevel == -1 ? null : selectedClassLevel,
    );

    ref
        .read(dsrEntryProvider.notifier)
        .fetchTitles(request: request, token: token)
        .then((response) {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
        print('fetchTitles response: ${response.toString()}');
        if (response.status == 'Success' && response.titleList.isNotEmpty) {
          print('Titles fetched: ${response.titleList.map((t) => {
                'BookId': t.bookId,
                'Title': t.title,
                'SeriesId': t.seriesId,
                'SubjectId': t.subjectId,
                'ISBN': t.isbn
              }).toList()}');
          // Pre-fill quantities from currentSelected
          for (var title in response.titleList) {
            final matching = widget.currentSelected.firstWhere(
              (data) =>
                  data['bookId'] == title.bookId &&
                  data['seriesId'] == title.seriesId,
              orElse: () => <String, dynamic>{},
            );
            if (matching != null) {
              title.quantity =
                  int.tryParse(matching['qty']?.toString() ?? '0') ?? 0;
            }
          }
          _showTitlesDialog(response.titleList);
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No titles found for this series')),
          );
        }
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    });
  }

  void _showTitlesDialog(List<dsrsampling.TitleData> titles) {
    showDialog(
      context: context,
      builder: (context) => selfStockBookSearchDialog(
        contextType: widget.contextType,
        titles: titles,
        onConfirmSelection: (selected) {
          setState(() {
            final currentSeries = seriesList.firstWhere(
              (s) => s.seriesId.toString() == selectedSeriesId,
              orElse: () =>
                  sampling.Series(seriesId: 0, seriesName: 'Unknown Series'),
            );
            selectedTitles = selected
                .map((title) {
                  final subjectId = title.subjectId;
                  if (subjectId == null || subjectId == 0) {
                    print(
                        'ERROR: Invalid subjectId for book: ${title.title}, ISBN: ${title.isbn}, SubjectId: $subjectId');
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Invalid subjectId for ${title.title}. Please check the book data.',
                        ),
                      ),
                    );
                    return null; // Skip invalid titles
                  }
                  print(
                      'Adding title: ${title.title}, subjectId: $subjectId, seriesId: ${title.seriesId ?? int.parse(selectedSeriesId ?? '0')}');
                  return dsrsampling.TitleData(
                    image: title.image,
                    bookNum: title.bookNum,
                    bookType: title.bookType,
                    bookId: title.bookId,
                    title: title.title,
                    isbn: title.isbn,
                    listPrice: title.listPrice,
                    physicalStock: title.physicalStock,
                    author: title.author,
                    imageUrl: title.imageUrl,
                    seriesId:
                        title.seriesId ?? int.parse(selectedSeriesId ?? '0'),
                    subjectId: subjectId,
                    quantity: title.quantity,
                    price: title.price,
                    maxSamplingQty: title.maxSamplingQty,
                    seriesName: currentSeries.seriesName,
                  );
                })
                .where((title) => title != null)
                .cast<dsrsampling.TitleData>()
                .toList();
            print('Selected titles: ${selectedTitles.map((t) => {
                  'BookId': t.bookId,
                  'Title': t.title,
                  'SeriesId': t.seriesId,
                  'SubjectId': t.subjectId,
                  'ISBN': t.isbn
                }).toList()}');
            widget.onSelection(_prepareResult());
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _prepareResult() {
    return selectedTitles
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key + 1;
          final t = entry.value;
          final seriesId = t.seriesId is int
              ? t.seriesId ?? 0
              : int.tryParse(t.seriesId?.toString() ?? '0') ?? 0;
          final subjectId = t.subjectId is int
              ? t.subjectId
              : int.tryParse(t.subjectId?.toString() ?? '0');
          if (t.quantity > 0 && (subjectId == null || subjectId == 0)) {
            print(
                'ERROR: Invalid subjectId for book: ${t.title}, ISBN: ${t.isbn}, SubjectId: ${t.subjectId}');
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Invalid subjectId for ${t.title}. Please check the book data.',
                ),
              ),
            );
            return null; // Skip invalid entries with quantity > 0
          }
          print(
              'Preparing result for book: ${t.title}, seriesId: $seriesId, subjectId: $subjectId, ISBN: ${t.isbn}, quantity: ${t.quantity}');
          return {
            'sno': index.toString(),
            'series': t.seriesName ?? 'Unknown Series',
            'subject': '',
            'title': t.title,
            'bookType': t.bookType,
            'bookId':
                t.bookId is int ? t.bookId : int.parse(t.bookId.toString()),
            'seriesId': seriesId,
            'subjectId': subjectId,
            'qty': t.quantity.toString(),
            'price': t.price.toString(),
            'imageUrl': t.imageUrl,
            'ISBN': t.isbn?.toString() ?? '',
          };
        })
        .where((item) => item != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classLevels = widget.classLevelResponse?.classLevelList ?? [];
    final uniqueClassLevels = classLevels
        .fold<Map<int, sampling.ClassLevel>>(
          {},
          (map, level) => map..[level.classLevelId] = level,
        )
        .values
        .toList();

    if (selectedClassLevel != null &&
        !uniqueClassLevels
            .any((level) => level.classLevelId == selectedClassLevel)) {
      print(
          'Resetting selectedClassLevel to ${uniqueClassLevels.isNotEmpty ? -1 : null} as $selectedClassLevel is invalid');
      selectedClassLevel = uniqueClassLevels.isNotEmpty ? -1 : null;
    }

    final validSelectedSeriesId = selectedSeriesId != null &&
            seriesList
                .any((series) => series.seriesId.toString() == selectedSeriesId)
        ? selectedSeriesId
        : null;
    print('Building with selectedSeriesId: $selectedSeriesId');
    print('Using validSelectedSeriesId for dropdown: $validSelectedSeriesId');
    print(
        'Class Levels: ${uniqueClassLevels.map((level) => 'ID: ${level.classLevelId}, Name: ${level.classLevelName}').toList()}');
    print('Selected Class Level: $selectedClassLevel');
    print(
        'Series List: ${seriesList.map((s) => 'ID: ${s.seriesId}, Name: ${s.seriesName}').toList()}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: validSelectedSeriesId,
                    decoration: InputDecoration(
                      labelText: 'Series',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.blueGrey),
                    dropdownColor: Colors.white,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            'Select',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      ...seriesList.map((series) {
                        return DropdownMenuItem<String>(
                          value: series.seriesId.toString(),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              "${series.seriesName}",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSeriesId = value;
                        selectedClassLevel = -1;
                        print('Series dropdown changed to: $selectedSeriesId');
                        print('Class Level reset to: $selectedClassLevel');
                      });
                    },
                    hint: showLoadingHint
                        ? const Text("Loading series...")
                        : seriesList.isEmpty && !isLoadingSeries
                            ? const Text("No series available")
                            : null,
                    validator: (value) =>
                        value == null ? 'Please select a series' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedClassLevel,
                          decoration: InputDecoration(
                            labelText: 'Class Level',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.blueGrey),
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
                          items: [
                            const DropdownMenuItem<int>(
                              value: -1,
                              child: Text(
                                'All Class Levels',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            ...uniqueClassLevels.map((level) {
                              return DropdownMenuItem<int>(
                                value: level.classLevelId,
                                child: Text(
                                  level.classLevelName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedClassLevel = value;
                              print(
                                  'Class Level changed to: $selectedClassLevel');
                              _fetchSeriesList();
                            });
                          },
                          validator: (value) => value == null
                              ? 'Please select a class level'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isSearching ? null : _showBookSearchDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.buttonPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Search',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
