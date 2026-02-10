import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/box_provider.dart';
import '../../providers/collection_provider.dart';
import '../../widgets/info_card.dart';
import 'box_summary_screen.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  DateTime selectedMonth = DateTime.now();
  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

  double _totalForSelectedMonth(CollectionProvider provider) {
    return provider.collections
        .where(
          (c) =>
              c.date.month == selectedMonth.month &&
              c.date.year == selectedMonth.year,
        )
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  @override
  Widget build(BuildContext context) {
    final collectionProvider = context.watch<CollectionProvider>();
    final boxProvider = context.watch<BoxProvider>();

    final isCurrentMonth =
        selectedMonth.month == DateTime.now().month &&
        selectedMonth.year == DateTime.now().year;

    final boxes = boxProvider.boxes;

    final Map<String, double> monthlyTotals = {};
    for (final box in boxes) {
      final total = collectionProvider.monthlyTotalForBox(
        box.boxId,
        month: selectedMonth.month,
        year: selectedMonth.year,
      );
      if (total > 0) {
        monthlyTotals[box.boxId] = total;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: Column(
        children: [
          // ---------------- Custom Gradient Header ----------------
          Container(
            padding: const EdgeInsets.only(
              top: 50, // For status bar
              left: 20,
              right: 20,
              bottom: 25,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 15),
                     Text(
                      "Monthly Summary",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _showExportConfirmationDialog(context, selectedMonth),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.download, color: Colors.white, size: 20),
                  ),
                  tooltip: "Export to Excel",
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
               physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // ---------------- Month Selector ----------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Material(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showMonthPicker(
                            context: context,
                            initialDate: selectedMonth,
                          );
                          if (picked != null) {
                            setState(() => selectedMonth = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_month_outlined, color: primaryColor),
                                  const SizedBox(width: 10),
                                  Text(
                                    DateFormat.yMMMM().format(selectedMonth),
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- Totals Cards ----------------
                  Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 20),
                     child: Column(
                       children: [
                          _buildSummaryCard(
                            "Total for ${DateFormat.MMMM().format(selectedMonth)}",
                            "£${_totalForSelectedMonth(collectionProvider).toStringAsFixed(2)}",
                            primaryColor,
                            Icons.currency_pound,
                            isMain: true,
                          ),
                          if (isCurrentMonth) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    "Today",
                                    "£${collectionProvider.totalToday.toStringAsFixed(2)}",
                                    secondaryColor,
                                    Icons.today,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    "Last Collection",
                                     collectionProvider.lastCollection == null
                                        ? "£0.00"
                                        : "£${collectionProvider.lastCollection!.amount.toStringAsFixed(2)}",
                                    Colors.orange.shade400,
                                    Icons.access_time,
                                  ),
                                ),
                              ],
                            ),
                          ],
                       ],
                     ),
                  ),

                  const SizedBox(height: 25),
                  
                  // ---------------- Donation History List ----------------
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Donation History",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (monthlyTotals.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(
                            "No collections found for this month",
                            style: GoogleFonts.poppins(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: monthlyTotals.length,
                      itemBuilder: (context, index) {
                        final entry = monthlyTotals.entries.elementAt(index);
                        final boxName = boxes
                            .firstWhere((b) => b.boxId == entry.key)
                            .venueName;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                               BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                offset: const Offset(0, 4),
                                blurRadius: 10,
                               ),
                            ],
                          ),
                          child: Material(
                             color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BoxSummaryScreen(boxId: entry.key),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            boxName,
                                            style:  GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            entry.key,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "£${entry.value.toStringAsFixed(2)}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]),
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
                    const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon, {bool isMain = false}) {
    return Container(
      padding: EdgeInsets.all(isMain ? 20 : 15),
      decoration: BoxDecoration(
        color: isMain ? color : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: isMain ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                  fontSize: isMain ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: isMain ? Colors.white.withOpacity(0.5) : color.withOpacity(0.5), size: 20),
            ],
          ),
          SizedBox(height: isMain ? 10 : 8),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: isMain ? Colors.white : Colors.black87,
              fontSize: isMain ? 28 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _exportMonthlyExcel(
  BuildContext context,
  DateTime selectedMonth,
) async {
  final collectionProvider = Provider.of<CollectionProvider>(
    context,
    listen: false,
  );
  final boxProvider = Provider.of<BoxProvider>(context, listen: false);

  if (collectionProvider.collections.isEmpty || boxProvider.boxes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No data available to export.")),
    );
    return;
  }

  final excel = xl.Excel.createExcel();

  final sheetName = DateFormat('MMMM yyyy').format(selectedMonth);
  final defaultSheetName = excel.sheets.keys.first;
  excel.rename(defaultSheetName, sheetName);
  final sheet = excel[sheetName];

  /// Header row
  sheet.appendRow([
    xl.TextCellValue('Date'),
    xl.TextCellValue('Box ID'),
    xl.TextCellValue('Box Name'),
    xl.TextCellValue('Collector'),
    xl.TextCellValue('Amount'),
  ]);

  double totalAmount = 0;

  final filteredCollections = collectionProvider.collections.where(
    (c) =>
        c.date.month == selectedMonth.month &&
        c.date.year == selectedMonth.year,
  );

  for (final c in filteredCollections) {
    final box = boxProvider.boxes.firstWhere(
      (b) => b.boxId == c.boxId,
      orElse: () => boxProvider.boxes.first,
    );

    totalAmount += c.amount;

    sheet.appendRow([
      xl.TextCellValue(DateFormat('dd-MM-yyyy').format(c.date)),
      xl.TextCellValue(c.boxId),
      xl.TextCellValue(box.venueName),
      xl.TextCellValue(c.collectedBy),
      xl.DoubleCellValue(c.amount),
    ]);
  }

  /// Empty row
  sheet.appendRow([xl.TextCellValue('')]);

  sheet.appendRow([
    xl.TextCellValue('Total Collections'),
    xl.DoubleCellValue(filteredCollections.length.toDouble()),
  ]);

  sheet.appendRow([
    xl.TextCellValue('Total Amount'),
    xl.DoubleCellValue(totalAmount),
  ]);

  sheet.appendRow([xl.TextCellValue('Month'), xl.TextCellValue(sheetName)]);

  final startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final endDate = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

  sheet.appendRow([
    xl.TextCellValue('Date Range'),
    xl.TextCellValue(
      '${DateFormat('dd-MM-yyyy').format(startDate)} to ${DateFormat('dd-MM-yyyy').format(endDate)}',
    ),
  ]);

  /// File naming
  final fileName =
      '${DateFormat('MMMM_yyyy').format(selectedMonth)}_'
      '${DateFormat('yyyy-MM-dd').format(startDate)}_to_'
      '${DateFormat('yyyy-MM-dd').format(endDate)}.xlsx';

  final dir = await getTemporaryDirectory();

  final file = File('${dir.path}/$fileName');

  file.writeAsBytesSync(excel.encode()!);

  await Share.shareXFiles([
    XFile(file.path),
  ], text: 'Monthly Donation Summary - $sheetName');
}

void _showExportConfirmationDialog(
  BuildContext context,
  DateTime selectedMonth,
) {
  final monthName = DateFormat('MMMM yyyy').format(selectedMonth);
  final startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final endDate = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

  final fileName =
      '${DateFormat('MMMM_yyyy').format(selectedMonth)}_'
      '${DateFormat('yyyy-MM-dd').format(startDate)}_to_'
      '${DateFormat('yyyy-MM-dd').format(endDate)}.xlsx';

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title:  Text("Export Summary", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.calendar_today, "Month", monthName),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.date_range, "Range", "${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM').format(endDate)}"),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.file_present, "File", fileName),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text("Cancel"),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.download, size: 18),
          label: const Text("Export"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF265d60),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            Navigator.pop(context);
            await _exportMonthlyExcel(context, selectedMonth);
            if (context.mounted) {
              _showExportSuccessDialog(context, fileName);
            }
          },
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: const Color(0xFF265d60)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            Text(value, style:  GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      ),
    ],
  );
}

void _showExportSuccessDialog(BuildContext context, String fileName) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text("Export Successful"),
        ],
      ),
      content: Text(
        "Your Excel file has been exported successfully.\n\nFile:\n$fileName",
        style: GoogleFonts.poppins(color: Colors.grey[700]),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF265d60),
            foregroundColor: Colors.white,
          ),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

/// Custom Month Picker
Future<DateTime?> showMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
}) async {
  DateTime selectedDate = initialDate;
  return showDialog<DateTime>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:  Text("Select Month", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 250,
          child: YearMonthPicker(
            initialDate: initialDate,
            onChanged: (date) {
              selectedDate = date;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedDate),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF265d60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Select"),
          ),
        ],
      );
    },
  );
}

/// Simple Year & Month Picker Widget
class YearMonthPicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onChanged;

  const YearMonthPicker({
    super.key,
    required this.initialDate,
    required this.onChanged,
  });

  @override
  State<YearMonthPicker> createState() => _YearMonthPickerState();
}

class _YearMonthPickerState extends State<YearMonthPicker> {
  late int selectedYear;
  late int selectedMonth;
  final int minYear = 2026;
  final int maxYear = DateTime.now().year + 10; // allow future years

  @override
  void initState() {
    super.initState();

    selectedYear = widget.initialDate.year < 2026
        ? 2026
        : widget.initialDate.year;

    selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedMonth,
              isExpanded: true,
              items: List.generate(12, (index) {
                final monthNum = index + 1;
                return DropdownMenuItem(
                  value: monthNum,
                  child: Text(DateFormat.MMMM().format(DateTime(0, monthNum))),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedMonth = value;
                    widget.onChanged(DateTime(selectedYear, selectedMonth));
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Year Dropdown
        Container(
           padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedYear,
              isExpanded: true,
              items:
                  List.generate(maxYear - minYear + 1, (index) => minYear + index)
                      .map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      )
                      .toList(),
          
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedYear = value;
                    widget.onChanged(DateTime(selectedYear, selectedMonth));
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
