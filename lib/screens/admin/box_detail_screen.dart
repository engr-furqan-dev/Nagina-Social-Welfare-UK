import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

import '../../models/box_model.dart';
import '../../providers/box_provider.dart';
import '../../services/firebase_service.dart';
import 'enter_amount_screen.dart';

class BoxDetailScreen extends StatefulWidget {
  final BoxModel box;

  const BoxDetailScreen({super.key, required this.box});

  @override
  State<BoxDetailScreen> createState() => _BoxDetailScreenState();
}

class _BoxDetailScreenState extends State<BoxDetailScreen> {
  late TextEditingController venueController;
  late TextEditingController contactPersonNameController;
  late TextEditingController contactPersonPhoneController;
  late TextEditingController boxIdController;
  final now = DateTime.now();

  final bool _mockSms = false;
  bool venueError = false;
  bool nameError = false;
  bool phoneError = false;
  late BoxStatus _selectedStatus;

  late TwilioFlutter twilioFlutter;
  late String initialVenue;
  late String initialContactPersonName;
  late String initialContactPersonPhone;
  late BoxStatus initialStatus;
  bool hasChanges = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _currentCollectorNameCon =
      TextEditingController();
  String? _currentCollectorName;
  
  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

  final FirebaseService _service = FirebaseService();

  bool canCollectCash(BoxModel box) {
    return box.status == BoxStatus.notCollected;
  }

  bool canSendReceipt(BoxModel box) {
    return box.status == BoxStatus.collected;
  }

  @override
  void initState() {
    super.initState();

    venueController = TextEditingController(text: widget.box.venueName);

    contactPersonNameController = TextEditingController(
      text: widget.box.contactPersonName,
    );

    String phoneText = widget.box.contactPersonPhone.startsWith('+44')
        ? widget.box.contactPersonPhone.substring(3)
        : widget.box.contactPersonPhone;

    contactPersonPhoneController = TextEditingController(text: phoneText);

    boxIdController = TextEditingController(text: widget.box.boxId);
    _selectedStatus = widget.box.status;

    // Store initial values
    initialVenue = widget.box.venueName;
    initialContactPersonName = widget.box.contactPersonName;
    initialContactPersonPhone = phoneText;
    initialStatus = widget.box.status;

    _phoneController.text = widget.box.contactPersonPhone;
    _messageController.text = _generateCollectionMessage();
    if (!_mockSms) {
      twilioFlutter = TwilioFlutter(
        accountSid: 'ACb2de03afb31797babd208aa7b410eb69',
        authToken: '8d040ac39a47f7e219344b71fa533ec2',
        twilioNumber: 'MarkazIslam',
      );
    }
  }

  void _checkForChanges() {
    final changed =
        venueController.text.trim() != initialVenue ||
        contactPersonNameController.text.trim() != initialContactPersonName ||
        contactPersonPhoneController.text.trim() != initialContactPersonPhone ||
        _selectedStatus != initialStatus;

    setState(() {
      hasChanges = changed;
    });
  }

  @override
  void dispose() {
    venueController.dispose();
    contactPersonNameController.dispose();
    contactPersonPhoneController.dispose();
    boxIdController.dispose();
    super.dispose();
  }

  bool isValidUKPhone(String phone) {
    return RegExp(r'^\d{10}$').hasMatch(phone);
  }

  bool _validateFields() {
    bool hasError = false;

    setState(() {
      venueError = venueController.text.trim().isEmpty;
      nameError =
          contactPersonNameController.text.trim().isEmpty ||
          contactPersonNameController.text.trim().length > 255;
      phoneError = !RegExp(
        r'^\d{10}$',
      ).hasMatch(contactPersonPhoneController.text.trim());

      hasError = venueError || nameError || phoneError;
    });

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please correct the highlighted errors'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return !hasError;
  }

  Future<void> updateBox() async {
    if (!_validateFields()) return; // Stop if validation fails

    final updatedBox = BoxModel(
      id: widget.box.id,
      boxId: widget.box.boxId,
      venueName: venueController.text.trim(),
      contactPersonName: contactPersonNameController.text.trim(),
      contactPersonPhone: '+44${contactPersonPhoneController.text.trim()}',
      totalCollected: widget.box.totalCollected,
      status: _selectedStatus,
      createdAt: widget.box.createdAt,
      updatedAt: DateTime.now(),
      boxSequence: 0, // TEMP – actual value set in provider
    );

    try {
      await _service.updateBox(updatedBox);

      final boxProvider = Provider.of<BoxProvider>(context, listen: false);
      final index = boxProvider.boxes.indexWhere((b) => b.id == updatedBox.id);

      if (index != -1) {
        boxProvider.boxes[index] = updatedBox;
        boxProvider.setBoxes(List.from(boxProvider.boxes));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Box updated successfully!'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating box: $e')));
    }
  }

  String _formatDate(DateTime date) {
    // Convert to 12-hour format
    int hour = date.hour % 12;
    if (hour == 0) hour = 12; // midnight or noon
    String minute = date.minute.toString().padLeft(2, '0');
    String period = date.hour >= 12 ? 'PM' : 'AM';

    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year} "
        "$hour:$minute $period";
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Box'),
          content: const Text(
            'Are you sure you want to delete this box? Existing donation records will not be affected.',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteBox();
    }
  }

  Future<void> _deleteBox() async {
    try {
      await _service.deleteBox(widget.box.id);

      final boxProvider = Provider.of<BoxProvider>(context, listen: false);
      boxProvider.setBoxes(
        boxProvider.boxes.where((b) => b.id != widget.box.id).toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Box deleted successfully'),
          duration: Duration(seconds: 1),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting box: $e')));
    }
  }

  //System “Share with” dialog opens
  Future<Uint8List> _generateQrPdf() async {
    final doc = pw.Document();

    final qrImage = await QrPainter(
      data: widget.box.boxId,
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
                pw.Text('Box ${widget.box.boxSequence.toString().padLeft(3, '0')}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text(widget.box.venueName, style: pw.TextStyle(fontSize: 20,fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Image(pw.MemoryImage(qrImage!.buffer.asUint8List())),
                pw.SizedBox(height: 20),
                pw.Text(widget.box.boxId, style: pw.TextStyle(fontSize: 20)),
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
      filename: 'box_qr_${widget.box.boxId}.pdf',
    );
  }

  String _generateCollectionMessage() {
    final timestamp = _formatDate(DateTime.now());
    final collector = _currentCollectorName ?? 'Unknown';

    return '''
Dear ${widget.box.contactPersonName},

The collection box has been collected by $collector.
The collected amount and receipt will be shared after counting.

Markaz-e-Islam
$timestamp

''';
  }

  Future<void> _sendMessageForCollection() async {
    try {
      // 🔹 MOCK OR REAL SMS
      if (_mockSms) {
        await Future.delayed(const Duration(seconds: 1));
        debugPrint('MOCK COLLECTION MESSAGE SENT');
      } else {
        await twilioFlutter.sendSMS(
          toNumber: _phoneController.text,
          messageBody: _messageController.text,
        );
      }

      // ✅ UPDATE FIREBASE
      await FirebaseService().updateBoxStatus(
        widget.box.boxId,
        BoxStatus.collected,
        collectorName: _currentCollectorName,
      );

      if (!mounted) return;
      _showMessageSentDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  void _showCollectorNameDialog() {
    final TextEditingController collectorController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Collector Name'),
          content: TextField(
            controller: collectorController,
            decoration: const InputDecoration(
              labelText: 'Enter collector name',
              border: OutlineInputBorder(),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () {
                collectorController.clear();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                if (collectorController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter collector name'),
                    ),
                  );
                  return;
                }

                final collectorName = collectorController.text.trim();
                _currentCollectorName = collectorName;

                _messageController.text = _generateCollectionMessage();

                _sendMessageForCollection();

                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ✅ Confirmation dialog
  void _showMessageSentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Sent'),
        content: Text(
          'Message for collection has been sent to ${widget.box.contactPersonName}',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.box.status = BoxStatus.collected;
                // widget.box.updatedAt = DateTime.now();
              });
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openQrPdf() async {
    try {
      final pdfBytes = await _generateQrPdf();

      // Use external storage so "open with" works reliably
      final dir =
          (await getExternalStorageDirectory()) ??
          await getTemporaryDirectory();
      final filePath = '${dir.path}/box_qr_${widget.box.boxId}.pdf';
      final file = File(filePath);

      await file.writeAsBytes(pdfBytes, flush: true);

      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app found to open PDF')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening PDF: $e')));
    }
  }

  String _getStatusText(BoxStatus status) {
    switch (status) {
      case BoxStatus.notCollected:
        return 'Not Collected';
      case BoxStatus.collected:
        return 'Collected';
      case BoxStatus.sentReceipt:
        return 'Receipt Sent';
    }
  }

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

  Widget _statusLabel(BoxStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: _getStatusColor(status), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(status),
            style: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SingleChildScrollView(
         child: Column(
          children: [
            // ---------------- Gradient Header ----------------
            Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
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
                  Expanded(
                    child: Text(
                      'Box ${widget.box.boxSequence.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // ---------------- Content ----------------
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // ✅ STATUS LABEL
                  Center(child: _statusLabel(widget.box.status)),
                  const SizedBox(height: 24),

                  // ---------------- Main Form ----------------
                  _buildSectionHeader("Box Information"),
                  const SizedBox(height: 16),
                  
                  // Venue Name
                  _buildModernTextField(
                    controller: venueController,
                    label: "Venue Name",
                    icon: Icons.store_mall_directory_outlined,
                    errorText: venueError ? "Venue name is required" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Contact Person Name
                  _buildModernTextField(
                    controller: contactPersonNameController,
                    label: "Contact Person Name",
                    icon: Icons.person_outline,
                    maxLength: 255,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]'))],
                    errorText: nameError ? "Valid name is required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Contact Person Phone
                  _buildModernTextField(
                    controller: contactPersonPhoneController,
                    label: "Contact Phone",
                    icon: Icons.phone_outlined,
                    prefixText: "+44 ",
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: phoneError ? "Enter exactly 10 digits" : null,
                  ),

                  const SizedBox(height: 32),

                  // ---------------- QR Section ----------------
                  _buildSectionHeader("Identification"),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                         BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                             Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: QrImageView(
                                data: widget.box.boxId,
                                size: 100,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Box ID", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.box.boxId, 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _openQrPdf,
                                      icon: const Icon(Icons.print_outlined, size: 18),
                                      label: const Text("Print / View QR"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: BorderSide(color: primaryColor),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // ---------------- Status & Operations ----------------
                   _buildSectionHeader("Operations"),
                   const SizedBox(height: 16),
                   
                   _statusDropdown(),
                   const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildOperationButton(
                          label: "Collect Cash",
                          icon: Icons.payments_outlined,
                          color: Colors.blue.shade700,
                          onPressed: canCollectCash(widget.box) ? _showCollectorNameDialog : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOperationButton(
                          label: "Send Receipt",
                          icon: Icons.receipt_long_outlined,
                          color: secondaryColor,
                          onPressed: canSendReceipt(widget.box)
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EnterAmountScreen(
                                        box: widget.box,
                                        collectorName: widget.box.collectorName ?? 'Unknown',

                                      ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // ---------------- Metadata ----------------
                   Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow("Created On", _formatDate(widget.box.createdAt)),
                        const Divider(height: 24),
                        _buildInfoRow("Last Updated", _formatDate(widget.box.updatedAt)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                   // ---------------- Actions ----------------
                   
                   SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: hasChanges ? updateBox : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: hasChanges ? 5 : 0,
                      ),
                      child: const Text(
                        "SAVE UPDATES",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Center(
                    child: TextButton(
                      onPressed: _confirmDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 20),
                          SizedBox(width: 8),
                          Text("Delete Box Permanently"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: secondaryColor),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
      ],
    );
  }

  Widget _statusDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<BoxStatus>(
        value: _selectedStatus,
        decoration: const InputDecoration(
          labelText: "Current Status",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(Icons.info_outline, color: Colors.grey),
        ),
        items: BoxStatus.values.map((status) {
          return DropdownMenuItem(
            value: status,
            child: Text(_getStatusText(status)),
          );
        }).toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _selectedStatus = value;
            _checkForChanges();
          });
        },
      ),
    );
  }

  Widget _buildOperationButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? Colors.grey.shade200 : color.withOpacity(0.1),
        foregroundColor: isDisabled ? Colors.grey : color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
             color: isDisabled ? Colors.transparent : color.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? errorText,
    String? prefixText,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: errorText != null 
                ? Border.all(color: Colors.red.shade300) 
                : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            onChanged: (_) {
               _checkForChanges();
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
              prefixText: prefixText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              counterText: "",
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}