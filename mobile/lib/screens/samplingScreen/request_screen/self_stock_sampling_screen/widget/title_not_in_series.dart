import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/planList/dsr_sampling_details.dart'
    as dsrsampling;
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/dsr_entry_provider.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/self_stock_book_search_popup.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TitleNotInSeriesPage extends ConsumerStatefulWidget {
  final String contextType;
  final Function(List<Map<String, dynamic>>) onSelection;
  final List<Map<String, dynamic>> currentSelected;

  const TitleNotInSeriesPage({
    super.key,
    required this.contextType,
    required this.onSelection,
    required this.currentSelected,
  });

  @override
  _TitleNotInSeriesPageState createState() => _TitleNotInSeriesPageState();
}

class _TitleNotInSeriesPageState extends ConsumerState<TitleNotInSeriesPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  List<dsrsampling.TitleData> selectedTitles = [];
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

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {}

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showBookSearchDialog() {
    final authState = ref.read(authProvider);
    final executiveId =
        authState.loginResponse?.executiveBasicData?[0].executiveId ?? 0;
    final token = authState.token ?? '';
    final searchText = _searchController.text.trim();

    if (searchText.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search term')),
      );
      return;
    }

    final request = sampling.TitleNotInSeriesRequest(
      executiveId: executiveId,
      titleOrISBN: searchText,
    );

    ref
        .read(dsrEntryProvider.notifier)
        .fetchTitlesNotInSeries(request: request, token: token)
        .then((response) {
      if (mounted) {
        if (response.status == 'Success' && response.titleList.isNotEmpty) {
          print(
              'Titles fetched (not in series): ${response.titleList.map((t) => {
                    'BookId': t.bookId,
                    'Title': t.title,
                    'SeriesId': t.seriesId,
                    'SubjectId': t.subjectId,
                    'ISBN': t.isbn
                  }).toList()}');
          // Pre-fill quantities from currentSelected
          for (var title in response.titleList) {
            final matching = widget.currentSelected.firstWhere(
              (data) => data['bookId'] == title.bookId,
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
            const SnackBar(
                content: Text('No titles found for this ISBN/Title')),
          );
        }
      }
    }).catchError((error) {
      if (mounted) {
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
            selectedTitles = selected
                .map((title) {
                  final subjectId = title.subjectId;
                  if (subjectId == null || subjectId == 0) {
                    print(
                        'Warning: Invalid subjectId for book: ${title.title}, ISBN: ${title.isbn}');
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
                      'Adding title: ${title.title}, subjectId: $subjectId, seriesId: 0');
                  return title.copyWith(
                    seriesName: title.title,
                    subjectId: subjectId,
                    seriesId: 0,
                  );
                })
                .where((title) => title != null)
                .cast<dsrsampling.TitleData>()
                .toList();
            print(
                'Selected titles (not in series): ${selectedTitles.map((t) => {
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
          if (subjectId == null || subjectId == 0) {
            print(
                'Warning: subjectId is null or 0 for book: ${t.title}, ISBN: ${t.isbn}');
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Invalid subjectId for ${t.title}. Please check the book data.'),
              ),
            );
            return null; // Skip invalid entries
          }
          print(
              'Preparing result for book: ${t.title}, seriesId: $seriesId, subjectId: $subjectId, ISBN: ${t.isbn}');
          return {
            'sno': index.toString(),
            'series': t.seriesName ?? t.title ?? 'Unknown Series',
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
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.only(top: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'ISBN or Title',
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                    style: const TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: ElevatedButton(
                      onPressed: _showBookSearchDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.buttonPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Search',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
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
