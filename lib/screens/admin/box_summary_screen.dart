import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/collection_provider.dart';
import '../../services/firebase_service.dart';
import '../../providers/box_provider.dart';
import '../../models/collection_model.dart';
import '../styles/text_style.dart';

class BoxSummaryScreen extends StatelessWidget {
  final String boxId; // pass the boxId to show details

  const BoxSummaryScreen({super.key, required this.boxId});

  @override
  Widget build(BuildContext context) {
    final collectionProvider = context.watch<CollectionProvider>();
    final boxProvider = context.watch<BoxProvider>();

    // Get box info
    final box = boxProvider.boxes.firstWhere((b) => b.boxId == boxId);

    // Totals
    final total = collectionProvider.totalForBox(boxId);
    final monthly = collectionProvider.monthlyTotalForBox(boxId);

    // Donation history
    final history = collectionProvider.historyForBox(boxId);

    return Scaffold(
      appBar: AppBar(
        title:  Center(
        child: Text(
          box.venueName,
          style: TextStyle(
              fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
        ),),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Donation summary cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green[500],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "This Month",
                            style: TextStyles.h3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "£${monthly.toStringAsFixed(2)}",
                            style: TextStyles.h1,)
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.deepOrange[200],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Total",
                            style: TextStyles.h4,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "£${total.toStringAsFixed(2)}",
                            style: TextStyles.h1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


              ],
            ),

            const SizedBox(height: 16),
            const Text(
              "Donation History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Donation history list
            Expanded(
              child: history.isEmpty
                  ? const Center(child: Text("No donations yet"))
                  : ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.payments),
                      title: Text("£${item.amount.toStringAsFixed(2)}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Date: ${item.date.toLocal().toString().split(' ')[0]}",
                          ),
                          Text(
                            "Collected by: ${item.collectedBy}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          item.receiptSent
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.cancel, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            item.receiptSent ? 'Receipt Sent' : 'Receipt Pending',
                            style: TextStyle(
                              color: item.receiptSent ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
