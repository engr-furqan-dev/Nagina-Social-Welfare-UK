import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/box_model.dart';
import '../../providers/box_provider.dart';
import '../../services/firebase_service.dart';
import 'add_box_screen.dart';
import 'box_detail_screen.dart';
import '../styles/text_style.dart';

class AllBoxesScreen extends StatefulWidget {
  const AllBoxesScreen({super.key});

  @override
  State<AllBoxesScreen> createState() => _AllBoxesScreenState();
}

class _AllBoxesScreenState extends State<AllBoxesScreen> {
  BoxStatus? filterStatus; // Current filter
  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

  Color _getBoxColor(BoxStatus status) {
    switch (status) {
      case BoxStatus.notCollected:
        return Colors.red.shade50;
      case BoxStatus.collected:
        return Colors.green.shade50;
      case BoxStatus.sentReceipt:
        return Colors.blue.shade50;
    }
  }

  Color _getBoxBorderColor(BoxStatus status) {
    switch (status) {
      case BoxStatus.notCollected:
        return Colors.red.shade200;
      case BoxStatus.collected:
        return Colors.green.shade200;
      case BoxStatus.sentReceipt:
        return Colors.blue.shade200;
    }
  }

  Color _getBoxTextColor(BoxStatus status) {
    switch (status) {
      case BoxStatus.notCollected:
        return Colors.red.shade800;
      case BoxStatus.collected:
        return Colors.green.shade800;
      case BoxStatus.sentReceipt:
        return Colors.blue.shade800;
    }
  }

  List<BoxModel> _applyFilter(List<BoxModel> boxes) {
    if (filterStatus == null) return boxes;
    return boxes.where((box) => box.status == filterStatus).toList();
  }

  String _getStatusLabel(BoxStatus status) {
    switch (status) {
      case BoxStatus.notCollected:
        return "Not Collected";
      case BoxStatus.collected:
        return "Collected";
      case BoxStatus.sentReceipt:
        return "Sent Receipt";
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return WillPopScope(
      onWillPop: () async {
        context.read<BoxProvider>().clearSearch(); // ✅ CLEAR SEARCH
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // ---------------- Custom Gradient Header ----------------
            Container(
              padding: const EdgeInsets.only(
                top: 50, // For status bar
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<BoxProvider>().clearSearch();
                          Navigator.pop(context);
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        ),
                      ),
                       Text(
                        "All Boxes",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                       IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddBoxScreen()),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ---------------- Search Field ----------------
                  Consumer<BoxProvider>(
                    builder: (context, provider, _) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: provider.searchController,
                          decoration: InputDecoration(
                            hintText: "Search by Box ID or Shop Name",
                            hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: primaryColor),
                            suffixIcon: provider.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: provider.clearSearch,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                          onChanged: provider.onSearchChanged,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- Filter Buttons ----------------
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFilterButton("All", null),
                  _buildFilterButton("Not Collected", BoxStatus.notCollected),
                  _buildFilterButton("Collected", BoxStatus.collected),
                  _buildFilterButton("Sent Receipt", BoxStatus.sentReceipt),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- Boxes List ----------------
            Expanded(
              child: StreamBuilder<List<BoxModel>>(
                stream: firebaseService.getBoxesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: primaryColor));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(
                            'No boxes added yet',
                            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  final provider = context.watch<BoxProvider>();

                  final allBoxes = snapshot.data!;
                  final searchedBoxes = provider.searchQuery.isEmpty
                      ? allBoxes
                      : allBoxes
                            .where(
                              (b) =>
                              b.boxSequence
                                  .toString().padLeft(3, '0')
                                  .contains(provider.searchQuery)
                                  ||
                                  b.venueName.toLowerCase().contains(
                                    provider.searchQuery.toLowerCase(),
                                  ),
                            )
                            .toList();

                  final boxes = _applyFilter(searchedBoxes)
                    ..sort((a, b) => a.boxSequence.compareTo(b.boxSequence));


                  if (boxes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(
                            "No matching boxes found",
                            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Boxes: ${allBoxes.length}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (filterStatus != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getBoxColor(filterStatus!),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _getBoxBorderColor(filterStatus!)),
                                ),
                                child: Text(
                                  "${_getStatusLabel(filterStatus!)}: ${boxes.length}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getBoxTextColor(filterStatus!),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          physics: const BouncingScrollPhysics(),
                          itemCount: boxes.length,
                          itemBuilder: (context, index) {
                            final box = boxes[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    offset: const Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                                border: Border.all(
                                  color: _getBoxBorderColor(box.status).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BoxDetailScreen(box: box),
                                      ),
                                    );
                                    if (mounted) {
                                      context.read<BoxProvider>().clearSearch();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Box Number Circle
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: _getBoxColor(box.status),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _getBoxBorderColor(box.status),
                                              width: 2,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: _highlightBoxSequence(
                                            box.boxSequence,
                                            provider.searchQuery,
                                            _getBoxTextColor(box.status),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Box Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _highlightVenueName(
                                                box.venueName,
                                                provider.searchQuery,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_outline,
                                                    size: 14,
                                                    color: Colors.grey[500],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      box.contactPersonName,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Status Indicator
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 16,
                                              color: Colors.grey[300],
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: _getBoxTextColor(box.status),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Filter Button Builder ----------------
  Widget _buildFilterButton(String label, BoxStatus? status) {
    final isSelected = filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            filterStatus = selected ? status : null;
            // If selecting "All" (status is null), actually logic is:
            // if we tap the same implementation logic again, maybe clear?
            // simpler: clicking a button sets the status.
            if (status == null) filterStatus = null; // for "All" button
          });
        },
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withOpacity(0.1),
        labelStyle: GoogleFonts.poppins(
          color: isSelected ? primaryColor : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // ---------------- Highlight matching Box ID ----------------
  Widget _highlightBoxSequence(int sequence, String query, Color textColor) {
    final baseStyle = GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    final sequenceText = sequence.toString().padLeft(3, '0');

    if (query.isEmpty) {
      return Text(sequenceText, style: baseStyle);
    }

    final startIndex = sequenceText.indexOf(query);

    if (startIndex == -1) {
      return Text(sequenceText, style: baseStyle);
    }

    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: sequenceText.substring(0, startIndex)),
          TextSpan(
            text: sequenceText.substring(startIndex, endIndex),
            style: baseStyle.copyWith(
              decoration: TextDecoration.underline,
              backgroundColor: Colors.yellow.withOpacity(0.3),
            ),
          ),
          TextSpan(text: sequenceText.substring(endIndex)),
        ],
      ),
    );
  }
}

// ---------------- Highlight matching Venue Name ----------------
Widget _highlightVenueName(String venueName, String query) {
  final baseStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.grey[800],
  );

  if (query.isEmpty) {
    return Text(venueName, style: baseStyle);
  }

  final lowerVenue = venueName.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final startIndex = lowerVenue.indexOf(lowerQuery);

  if (startIndex == -1) {
    return Text(venueName, style: baseStyle);
  }

  final endIndex = startIndex + query.length;

  return RichText(
    text: TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: venueName.substring(0, startIndex)),
        TextSpan(
          text: venueName.substring(startIndex, endIndex),
          style: baseStyle.copyWith(
            backgroundColor: const Color(0xFFd5a148).withOpacity(0.3),
            color: const Color(0xFF265d60),
          ),
        ),
        TextSpan(text: venueName.substring(endIndex)),
      ],
    ),
  );
}
