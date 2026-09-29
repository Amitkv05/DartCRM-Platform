import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/data_cards.dart';
import 'package:flutter/material.dart';

class BookContainer extends StatelessWidget {
  final String seriesName;
  final List<Map<String, dynamic>> books;
  final Function(Map<String, dynamic>) onRemove;
  final Function(Map<String, dynamic>, int) onQuantityChange;
  final VoidCallback
      onRemoveContainer; // New callback for removing the entire container

  const BookContainer({
    super.key,
    required this.seriesName,
    required this.books,
    required this.onRemove,
    required this.onQuantityChange,
    required this.onRemoveContainer, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.collections_bookmark,
                      color: Colors.blueGrey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      seriesName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.blueGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[400],
                      size: 24,
                    ),
                    onPressed: onRemoveContainer, // Trigger container removal
                    tooltip: 'Delete Container',
                  ),
                ],
              ),
            ),
            ...books.map((data) => DataCard(
                  data: data,
                  seriesName: seriesName,
                  onRemove: onRemove,
                  onQuantityChange: onQuantityChange,
                )),
          ],
        ),
      ),
    );
  }
}
