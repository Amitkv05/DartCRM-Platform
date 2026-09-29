import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/planList/dsr_sampling_details.dart'
    as dsrsampling;
import 'package:dart_crm/models/setup_value.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class selfStockBookSearchDialog extends ConsumerStatefulWidget {
  final List<dsrsampling.TitleData> titles;
  final Function(List<dsrsampling.TitleData>) onConfirmSelection;
  final String contextType; // 'dsr', 'selfStock', or 'customer'
  final String? sampleGiven;

  const selfStockBookSearchDialog({
    super.key,
    required this.titles,
    required this.onConfirmSelection,
    required this.contextType,
    this.sampleGiven,
  });

  @override
  _selfStockBookSearchDialogState createState() =>
      _selfStockBookSearchDialogState();
}

class _selfStockBookSearchDialogState
    extends ConsumerState<selfStockBookSearchDialog>
    with SingleTickerProviderStateMixin {
  late List<dsrsampling.TitleData> titles;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late int maxQuantityAllowed;
  late int maxSamplingTitles;

  @override
  void initState() {
    super.initState();
    // Deep copy titles with subjectId
    titles = List.from(widget.titles.map((title) => dsrsampling.TitleData(
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
          seriesId: title.seriesId,
          subjectId: title.subjectId, // Explicitly copy subjectId
          quantity: title.quantity,
          price: title.price,
          maxSamplingQty: title.maxSamplingQty,
          seriesName: title.seriesName,
        )));
    // Debug logging
    print('selfStockBookSearchDialog: sampleGiven=${widget.sampleGiven}');
    print(
        'Titles: ${titles.map((t) => "${t.title}: stock=${t.physicalStock}, subjectId=${t.subjectId}").toList()}');
    // No filtering for "To Be Dispatched" to allow zero-stock books
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
    _loadSetupValues();
  }

  void _loadSetupValues() {
    final authState = ref.read(authProvider);
    final setupValues = authState.setupValues ?? [];

    setState(() {
      int samplingSelfStockMaxQtyAllowed =
          _getSetupInt(setupValues, 'SamplingSelfStockMaxQtyAllowed', 10);
      int samplingCustomerMaxQtyAllowed =
          _getSetupInt(setupValues, 'SamplingCustomerMaxQtyAllowed', 10);
      maxSamplingTitles =
          _getSetupInt(setupValues, 'DSR_MAX_SAMPLING_TITLES', 10);

      switch (widget.contextType) {
        case 'selfStock':
          maxQuantityAllowed = samplingSelfStockMaxQtyAllowed;
          break;
        case 'customer':
          maxQuantityAllowed = samplingCustomerMaxQtyAllowed;
          break;
        case 'dsr':
        default:
          maxQuantityAllowed = samplingCustomerMaxQtyAllowed;
          break;
      }
    });
  }

  int _getSetupInt(List<SetupValue> setupValues, String key, int defaultValue) {
    final value = setupValues
        .firstWhere(
          (setup) => setup.keyName == key,
          orElse: () => SetupValue(
              id: 0,
              keyName: key,
              keyValue: defaultValue.toString(),
              keyStatus: true,
              keyDescription: ''),
        )
        .keyValue;
    return int.tryParse(value) ?? defaultValue;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.8;

    final bool hasTitles = titles.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.search, color: Colors.blueGrey, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Search Results (${titles.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.blueGrey, height: 24),
              if (!hasTitles)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No titles found.',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: titles.length,
                  itemBuilder: (context, index) {
                    final title = titles[index];
                    final stock = title.physicalStock ?? 0;
                    // Enable buttons for all titles, no stock restriction
                    final isEnabled = true;
                    print(
                        'Rendering title: ${title.title}, stock: $stock, isEnabled: $isEnabled, quantity: ${title.quantity}');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.title!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 55,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: title.imageUrl != null &&
                                            title.imageUrl!.isNotEmpty
                                        ? NetworkImage(title.imageUrl!)
                                        : const AssetImage(
                                            'assets/books/book.avif'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Author: ${title.author ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Book Type: ${title.bookType ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'ISBN: ${title.isbn ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Price: ₹${title.listPrice!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Avail.Stock: $stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: stock > 0
                                      ? Colors.redAccent
                                      : Colors.red[700],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle,
                                      color: title.quantity > 0
                                          ? Colors.red[700]
                                          : Colors.grey[400],
                                    ),
                                    onPressed: title.quantity > 0
                                        ? () {
                                            setState(() {
                                              title.quantity--;
                                              print(
                                                  'Decremented: ${title.title}, quantity: ${title.quantity}');
                                            });
                                          }
                                        : null,
                                  ),
                                  Text(
                                    '${title.quantity}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle,
                                      color: Colors.green[700],
                                    ),
                                    onPressed: () {
                                      final maxLimit = [
                                        maxQuantityAllowed,
                                        title.maxSamplingQty ?? double.infinity
                                      ].reduce((a, b) => a < b ? a : b);
                                      if (title.quantity < maxLimit) {
                                        setState(() {
                                          title.quantity++;
                                          print(
                                              'Incremented: ${title.title}, quantity: ${title.quantity}');
                                        });
                                      } else {
                                        AppUtils.showTop(
                                            'Cannot exceed limit of $maxQuantityAllowed');
                                        // ScaffoldMessenger.of(context)
                                        //     .showSnackBar(
                                        //   SnackBar(
                                        //     content: Text(
                                        //       'Cannot exceed limit of $maxQuantityAllowed ',
                                        //     ),
                                        //     duration:
                                        //         const Duration(seconds: 3),
                                        // ),
                                        // );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: TColors.cancelButton,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Include all titles, regardless of quantity
                      final selected =
                          titles; // Changed from titles.where((t) => t.quantity > 0).toList()
                      // Validate subjectId for selected titles with quantity > 0
                      final invalidTitles = selected
                          .where((t) =>
                              t.quantity > 0 &&
                              (t.subjectId == null || t.subjectId == 0))
                          .toList();
                      if (invalidTitles.isNotEmpty) {
                        print(
                            'ERROR: Invalid subjectId for titles: ${invalidTitles.map((t) => "${t.title}: subjectId=${t.subjectId}").toList()}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Invalid subjectId for ${invalidTitles.length} title(s). Contact support.',
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      if (widget.contextType == 'dsr' &&
                          selected.where((t) => t.quantity > 0).length >
                              maxSamplingTitles) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cannot select more than $maxSamplingTitles titles for DSR entry',
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      print(
                          'Confirmed titles: ${selected.map((t) => "${t.title}: ${t.quantity}/${t.physicalStock}, subjectId=${t.subjectId}").toList()}');
                      widget.onConfirmSelection(selected);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.buttonPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Confirm',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
