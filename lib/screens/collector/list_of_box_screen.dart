import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/box_model.dart';
import '../../providers/box_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/collector_model.dart';
import 'box_details_for_collector.dart';

class SelectBoxScreen extends StatefulWidget {
  final CollectorModel collector;
  const SelectBoxScreen({super.key, required this.collector});

  @override
  State<SelectBoxScreen> createState() => _SelectBoxScreenState();
}

class _SelectBoxScreenState extends State<SelectBoxScreen> {
  BoxStatus? filterStatus; // Current filter
  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

  Color _getStatusColor(BoxStatus status) {
    switch (status) {
      case BoxStatus.notCollected:
        return Colors.red;
      case BoxStatus.collected:
        return Colors.blue;
      case BoxStatus.sentReceipt:
        return Colors.green;
    }
  }

  String _getStatusLabel(BoxStatus status) {
    switch (status) {
      case BoxStatus.notCollected:
        return "Not Collected";
      case BoxStatus.collected:
        return "Collected";
      case BoxStatus.sentReceipt:
        return "Receipt Sent";
    }
  }

  List<BoxModel> _applyFilter(List<BoxModel> boxes) {
    if (filterStatus == null) return boxes;
    return boxes.where((box) => box.status == filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return WillPopScope(
      onWillPop: () async {
        context.read<BoxProvider>().clearSearch();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Light background
        body: Column(
          children: [
            // ---------------- Gradient Header ----------------
            Container(
              padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
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
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "List of Boxes",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
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
                          onChanged: provider.onSearchChanged,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Search Box ID or Venue...",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
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
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ---------------- Filter Chips ----------------
            Container(
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFilterChip("All", null),
                  _buildFilterChip("Not Collected", BoxStatus.notCollected),
                  _buildFilterChip("Collected", BoxStatus.collected),
                  _buildFilterChip("Receipt Sent", BoxStatus.sentReceipt),
                ],
              ),
            ),

            // ---------------- Boxes List ----------------
            Expanded(
              child: StreamBuilder<List<BoxModel>>(
                stream: firebaseService.getBoxesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: primaryColor));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState("No boxes added yet", Icons.inventory_2_outlined);
                  }

                  final provider = context.watch<BoxProvider>();
                  final allBoxes = snapshot.data!;
                  
                  // Filter by Search Query
                  final searchedBoxes = provider.searchQuery.isEmpty
                      ? allBoxes
                      : allBoxes.where((b) =>
                          b.boxSequence.toString().contains(provider.searchQuery) ||
                          b.venueName.toLowerCase().contains(provider.searchQuery.toLowerCase())
                        ).toList();

                  // Filter by Status
                  final boxes = _applyFilter(searchedBoxes)
                    ..sort((a, b) => a.boxSequence.compareTo(b.boxSequence));

                  if (boxes.isEmpty) {
                    return _buildEmptyState("No matching boxes found", Icons.search_off);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              "Total Boxes: ",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                            Text(
                              "${boxes.length}",
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            if (filterStatus != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(filterStatus!).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusLabel(filterStatus!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getStatusColor(filterStatus!),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          physics: const BouncingScrollPhysics(),
                          itemCount: boxes.length,
                          itemBuilder: (context, index) {
                            final box = boxes[index];
                            return _buildBoxCard(box, provider.searchQuery);
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

  Widget _buildBoxCard(BoxModel box, String query) {
    Color statusColor = _getStatusColor(box.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BoxDetailForCollectorScreen(box: box, collector: widget.collector),
              ),
            );
            if (mounted) context.read<BoxProvider>().clearSearch();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Indicator Strip
                Container(
                  width: 6,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _highlightBoxSequence(box.boxSequence, query),
                      const SizedBox(height: 4),
                      _highlightVenueName(box.venueName, query),
                    ],
                  ),
                ),
                
                // Chevron
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade300, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, BoxStatus? status) {
    final isSelected = filterStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
             // If clicking "All" (status == null), always select it. 
             // If clicking a specific status twice, we could toggle it off to show "All", 
             // but usually strictly selecting one filter is better UX.
             // Here we simple set the filter.
             filterStatus = status;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
        ),
        elevation: isSelected ? 2 : 0,
        pressElevation: 0,
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ---------------- Highlight matching Box ID ----------------
  Widget _highlightBoxSequence(int sequence, String query) {
    final baseStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87);
    final sequenceText = "Box ${sequence.toString().padLeft(3, '0')}";
    
    // We only highlight the number part generally if the user types "001" etc.
    // If the user types "Box", everything highlights. 
    // Let's stick to the previous simple logic but improved style.

    if (query.isEmpty) {
      return Text(sequenceText, style: baseStyle);
    }

    final lowerText = sequenceText.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
       // Also check if they just typed the number e.g. "1" matching "001"
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
            style: baseStyle.copyWith(color: secondaryColor, backgroundColor: secondaryColor.withOpacity(0.1)),
          ),
          TextSpan(text: sequenceText.substring(endIndex)),
        ],
      ),
    );
  }

  // ---------------- Highlight matching Venue Name ----------------
  Widget _highlightVenueName(String venueName, String query) {
    final baseStyle = TextStyle(fontSize: 14, color: Colors.grey.shade600);

    if (query.isEmpty) {
      return Text(venueName, style: baseStyle);
    }

     final lowerText = venueName.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);

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
             style: baseStyle.copyWith(color: Colors.black87, fontWeight: FontWeight.bold, backgroundColor: secondaryColor.withOpacity(0.2)),
          ),
          TextSpan(text: venueName.substring(endIndex)),
        ],
      ),
    );
  }
}
