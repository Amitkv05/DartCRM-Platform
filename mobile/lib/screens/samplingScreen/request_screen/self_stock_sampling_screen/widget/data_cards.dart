import 'package:flutter/material.dart';

class DataCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String seriesName;
  final Function(Map<String, dynamic>) onRemove;
  final Function(Map<String, dynamic>, int) onQuantityChange;

  const DataCard({
    super.key,
    required this.data,
    required this.seriesName,
    required this.onRemove,
    required this.onQuantityChange,
  });

  @override
  Widget build(BuildContext context) {
    print(
        'Rendering book: ${data['title']}, series: $seriesName, ISBN: ${data['ISBN']}');
    return GestureDetector(
      onTap: () {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Viewing details for ${data['title']}')),
        // );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: data['imageUrl'] != null && data['imageUrl'].isNotEmpty
                      ? NetworkImage(data['imageUrl'])
                      : const AssetImage('assets/books/book.avif'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Unknown Title',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data['ISBN']?.toString().isNotEmpty == true &&
                      data['ISBN'] != 'Unknown')
                    RichText(
                      text: TextSpan(
                        text: 'ISBN: ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: data['ISBN'].toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (data['ISBN']?.toString().isNotEmpty == true &&
                      data['ISBN'] != 'Unknown')
                    const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['bookType']?.isNotEmpty == true)
                            RichText(
                              text: TextSpan(
                                text: 'Book Type: ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: data['bookType'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (data['bookType']?.isNotEmpty == true)
                            const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              text: 'Qty: ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: data['qty']?.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      Spacer(),
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove,
                                  size: 20, color: Colors.redAccent),
                              tooltip: 'Decrease quantity or remove book',
                              onPressed: () {
                                final currentQty = int.tryParse(
                                        data['qty']?.toString() ?? '1') ??
                                    1;
                                if (currentQty > 1) {
                                  onQuantityChange(data, currentQty - 1);
                                } else {
                                  onRemove(data);
                                }
                              },
                            ),
                            // Text('|', style: TextStyle(color: Colors.black, fontSize: 26)),
                            Text(
                              "${data['qty']?.toString()}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              tooltip: 'Increase quantity',
                              onPressed: () {
                                final currentQty = int.tryParse(
                                        data['qty']?.toString() ?? '1') ??
                                    1;
                                final maxQty = data['maxSamplingQty'] != null
                                    ? int.tryParse(data['maxSamplingQty']
                                            .toString()) ??
                                        5
                                    : 5;
                                if (currentQty < maxQty) {
                                  onQuantityChange(data, currentQty + 1);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Cannot exceed limit of $maxQty')),
                                  );
                                }
                              },
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
  }
}
