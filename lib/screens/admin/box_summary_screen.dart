import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/collection_provider.dart';
import '../../providers/box_provider.dart';

class BoxSummaryScreen extends StatelessWidget {
  final String boxId;

  const BoxSummaryScreen({super.key, required this.boxId});

  @override
  Widget build(BuildContext context) {
    final collectionProvider = context.watch<CollectionProvider>();
    final boxProvider = context.watch<BoxProvider>();

    final primaryColor = const Color(0xFF265d60);
    final secondaryColor = const Color(0xFFd5a148);

    final box = boxProvider.boxes.firstWhere((b) => b.boxId == boxId);

    final total = collectionProvider.totalForBox(boxId);
    final monthly = collectionProvider.monthlyTotalForBox(boxId);
    final history = collectionProvider.historyForBox(boxId);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ---------- Gradient Header ----------
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 25,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.85),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  offset: const Offset(0, 5),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        box.venueName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Box ${box.boxSequence.toString().padLeft(3, '0')}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- Summary Cards ----------
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          "This Month",
                          "£${monthly.toStringAsFixed(2)}",
                          primaryColor,
                          Icons.calendar_month,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          "Total",
                          "£${total.toStringAsFixed(2)}",
                          secondaryColor,
                          Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Text(
                    "Donation History",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ---------- History List ----------
                  history.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(Icons.history_toggle_off,
                              size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(
                            "No donations yet",
                            style: GoogleFonts.poppins(
                                color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                  primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.payments,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "£${item.amount.toStringAsFixed(2)}",
                                      style:
                                      GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy')
                                          .format(item.date),
                                      style:
                                      GoogleFonts.poppins(
                                        fontSize: 12,
                                        color:
                                        Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Collected by: ${item.collectedBy}",
                                      style:
                                      GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(item.receiptSent),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool sent) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: sent ? Colors.green[50] : Colors.red[50],
        shape: BoxShape.circle,
      ),
      child: Icon(
        sent ? Icons.check_circle : Icons.cancel,
        color: sent ? Colors.green : Colors.red,
        size: 20,
      ),
    );
  }

}
