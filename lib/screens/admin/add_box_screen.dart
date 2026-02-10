import 'dart:math';
import 'dart:ui' as ui;

import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/box_model.dart';
import '../../providers/box_provider.dart';
import 'all_boxes_screen.dart'; // adjust path if needed
import 'box_detail_screen.dart';
import '../styles/text_style.dart';

class AddBoxScreen extends StatefulWidget {
  const AddBoxScreen({super.key});

  @override
  State<AddBoxScreen> createState() => _AddBoxScreenState();
}

class _AddBoxScreenState extends State<AddBoxScreen> {
  final venueController = TextEditingController();
  final contactPersonNameController = TextEditingController();
  final contactPersonPhoneController = TextEditingController();
  late String boxId;
  bool isQrGenerated = false;
  bool isSaving = false;
  final GlobalKey qrKey = GlobalKey();

  // NEW: error flags
  bool venueError = false;
  bool nameError = false;
  bool phoneError = false;

  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

  @override
  void initState() {
    super.initState();
    boxId = generateBoxId();
  }

  /// Unique Box ID: timestamp + random
  String generateBoxId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(900) + 100; // 3-digit random
    return 'BOX$timestamp$random';
  }

  /// Save box to Firebase + Provider
  Future<void> saveBox(BuildContext context) async {
    final phoneNumber = contactPersonPhoneController.text.trim();
    final contactPersonName = contactPersonNameController.text.trim();

    // VALIDATION with error highlights
    if (venueController.text.isEmpty ||
        contactPersonName.isEmpty ||
        contactPersonName.length > 255 ||
        phoneNumber.length != 10) {
      setState(() {
        venueError = venueController.text.isEmpty;
        nameError = contactPersonName.isEmpty || contactPersonName.length > 255;
        phoneError = phoneNumber.length != 10;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please, Fill All the required Fields')),
      );
      return;
    }

    try {
      // Clear errors on success
      setState(() {
        venueError = false;
        nameError = false;
        phoneError = false;
      });

      //final qrCodeUrl = await _uploadQrToFirebase();

      final box = BoxModel(
        id: '', // Firestore auto-generates ID
        boxId: boxId,
        venueName: venueController.text.trim(),
        contactPersonName: contactPersonName,
        contactPersonPhone: '+44$phoneNumber', // prepend UK code
        totalCollected: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // qrCodeUrl: qrCodeUrl,
        boxSequence: 0, // TEMP – actual value set in provider
      );

      await Provider.of<BoxProvider>(context, listen: false).addBox(box);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Box added successfully!')),
        );
      }

      // Clear inputs and generate new Box ID
      venueController.clear();
      contactPersonNameController.clear();
      contactPersonPhoneController.clear();
      setState(() {
        boxId = generateBoxId();
      });

      //push to All Boxes Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AllBoxesScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving box: $e')));
      }
    }
  }


  @override
  void dispose() {
    venueController.dispose();
    contactPersonNameController.dispose();
    contactPersonPhoneController.dispose();
    super.dispose();
  }

  Widget _qrPreview() {
    return Column(
      children: [
        const SizedBox(height: 20),
        RepaintBoundary(
          key: qrKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: boxId,
                  size: 150,
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                ),
                const SizedBox(height: 15),
                Text(
                  boxId,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onGenerateQr() {
    setState(() {
      isQrGenerated = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _uploadQrToFirebase();
    });
  }



  Future<void> generateQrAndSave(BuildContext context) async {
    if (isSaving) return; // HARD BLOCK multiple taps

    final phoneNumber = contactPersonPhoneController.text.trim();
    final contactPersonName = contactPersonNameController.text.trim();

    // Validation
    if (venueController.text.isEmpty ||
        contactPersonName.isEmpty ||
        contactPersonName.length > 255 ||
        phoneNumber.length != 10) {
      setState(() {
        venueError = venueController.text.isEmpty;
        nameError = contactPersonName.isEmpty || contactPersonName.length > 255;
        phoneError = phoneNumber.length != 10;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please, Fill All the required Fields')),
      );
      return;
    }

    setState(() {
      isSaving = true;       // LOCK button
      isQrGenerated = true; // Show QR
      venueError = false;
      nameError = false;
      phoneError = false;
    });

    try {
      final box = BoxModel(
        id: '',
        boxId: boxId,
        venueName: venueController.text.trim(),
        contactPersonName: contactPersonName,
        contactPersonPhone: '+44$phoneNumber',
        totalCollected: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        boxSequence: 0, // TEMP – actual value set in provider
      );

      final newBox =
      await Provider.of<BoxProvider>(context, listen: false).addBox(box);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Box added successfully!')),
        );
      }

      // Clear inputs and generate new Box ID
      venueController.clear();
      contactPersonNameController.clear();
      contactPersonPhoneController.clear();
      setState(() {
        boxId = generateBoxId();
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>  BoxDetailScreen(box: newBox)),
      );

    } catch (e) {
      setState(() {
        isSaving = false; // unlock on failure
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving box: $e')),
      );
    }
  }

  //share with feature
  Future<Uint8List> _generateQrPdf() async {
    final doc = pw.Document();

    final qrImage = await QrPainter(
      data: boxId,
      version: QrVersions.auto,
      gapless: false,
    ).toImageData(200);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Image(pw.MemoryImage(qrImage!.buffer.asUint8List())),
                pw.SizedBox(height: 20),
                pw.Text(
                  boxId,
                  style: pw.TextStyle(fontSize: 20),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  Future<void> _shareQrCode() async {
    final pdfBytes = await _generateQrPdf();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'box_qr_$boxId.pdf',
    );
  }


  @override
  Widget build(BuildContext context) {
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
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 15),
                 Text(
                  "Add New Box",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ---------------- Scrollable Form ----------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Venue Details",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),

                         // Venue Name
                        _buildTextField(
                          controller: venueController,
                          label: "Venue Name",
                          icon: Icons.store_mall_directory_outlined,
                          error: venueError,
                          errorText: "Venue name is required",
                          enabled: !isQrGenerated,
                        ),

                        const SizedBox(height: 20),

                        // Contact Person Name
                        _buildTextField(
                          controller: contactPersonNameController,
                          label: "Contact Person Name",
                          icon: Icons.person_outline,
                          error: nameError,
                          errorText: "Valid name is required",
                          enabled: !isQrGenerated,
                          maxLength: 255,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Contact Person Phone
                        _buildTextField(
                          controller: contactPersonPhoneController,
                          label: "Contact Person Phone",
                          icon: Icons.phone_outlined,
                          error: phoneError,
                          errorText: "Enter exactly 10 digits",
                          enabled: !isQrGenerated,
                          keyboardType: TextInputType.number,
                          prefixText: "+44 ",
                          maxLength: 10,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Action Button
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (isSaving || isQrGenerated)
                          ? null
                          : () => generateQrAndSave(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shadowColor: primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: isSaving
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: primaryColor,
                              ),
                            )
                          :  Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.qr_code_2, size: 24),
                                 SizedBox(width: 10),
                                 Text(
                                   "GENERATE QR & SAVE",
                                   style: GoogleFonts.poppins(
                                     fontSize: 16,
                                     fontWeight: FontWeight.bold,
                                     letterSpacing: 1,
                                   ),
                                 ),
                               ],
                            ),
                    ),
                  ),

                  if (isQrGenerated) _qrPreview(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool error = false,
    String? errorText,
    bool enabled = true,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
            prefixIcon: Icon(icon, color: error ? Colors.red : primaryColor),
            prefixText: prefixText,
            prefixStyle: GoogleFonts.poppins(color: Colors.grey[800], fontSize: 16),
            filled: true,
            fillColor: Colors.grey[50], // Slightly darker than white
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorText: error ? errorText : null,
            counterText: "", // Hide character counter
          ),
          onChanged: (_) {
            if (error) {
              setState(() {
                // We'd need to lift state up for specific field error reset if we want strict field-only reset
                // For now, simpler to just trigger rebuild or use specific error flags
                if (controller == venueController) venueError = false;
                if (controller == contactPersonNameController) nameError = false;
                if (controller == contactPersonPhoneController) phoneError = false;
              });
            }
          },
        ),
      ],
    );
  }
}
