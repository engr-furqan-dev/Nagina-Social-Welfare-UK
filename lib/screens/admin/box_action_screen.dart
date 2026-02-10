import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

import '../../models/box_model.dart';
import '../../services/firebase_service.dart';
import 'enter_amount_screen.dart';
import '../styles/text_style.dart';

class BoxActionScreen extends StatefulWidget {
  final BoxModel box;

  const BoxActionScreen({super.key, required this.box});

  @override
  State<BoxActionScreen> createState() => _BoxActionScreenState();
}

class _BoxActionScreenState extends State<BoxActionScreen> {
  String? _currentCollectorName; // add at the top of _BoxActionScreenState

  final now = DateTime.now();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  //final TextEditingController _collectorNameController = TextEditingController();

  bool canCollectCash(BoxModel box) {
    return box.status == BoxStatus.notCollected;
  }

  bool canSendReceipt(BoxModel box) {
    return box.status == BoxStatus.collected;
  }

  /// 🔹 MOCK SWITCH (true = NO real SMS)
  final bool _mockSms = false;

  TwilioFlutter? twilioFlutter;

  @override
  void initState() {
    super.initState();

    _phoneController.text = widget.box.contactPersonPhone;
    _messageController.text = _generateCollectionMessage();

    /// Initialize Twilio ONLY when real SMS is required
    if (!_mockSms) {
      twilioFlutter = TwilioFlutter(
        accountSid: 'ACb2de03afb31797babd208aa7b410eb69',
        authToken: '8d040ac39a47f7e219344b71fa533ec2',
        twilioNumber: 'MarkazIslam',
      );
      /*
      twilioFlutter = TwilioFlutter(
      accountSid: 'ACb2de03afb31797babd208aa7b410eb69',
      authToken: '8d040ac39a47f7e219344b71fa533ec2',
      twilioNumber: 'MarkazIslam',
       );
      */
    }
  }

  String _formatDate(DateTime date) {
    int hour = date.hour % 12;
    if (hour == 0) hour = 12;
    String minute = date.minute.toString().padLeft(2, '0');
    String period = date.hour >= 12 ? 'PM' : 'AM';

    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year} "
        "$hour:$minute $period";
  }

  //------ admin--------
  Future<Map<String, dynamic>?> _getAdminConfig() async {
    return await FirebaseService.getAdminInfo();
  }

  String _adminCashCollectedMessage() {
    final timestamp = _formatDate(DateTime.now());
    return '''
Cash collected from box.

Box ID: ${widget.box.boxId}
Collected By: $_currentCollectorName

$timestamp
''';
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

  // ✅ SEND MESSAGE FOR COLLECTION (MOCKED)
  Future<void> _sendMessageForCollection() async {
    try {
      // 🔹 MOCK OR REAL SMS
      if (_mockSms) {
        await Future.delayed(const Duration(seconds: 1));
        debugPrint('MOCK COLLECTION MESSAGE SENT');
      } else {
        await twilioFlutter!.sendSMS(
          toNumber: _phoneController.text,
          messageBody: _messageController.text,
        );
      }

      // ✅ Update box status in Firebase (UNCHANGED)
      await FirebaseService().updateBoxStatus(
        widget.box.boxId,
        BoxStatus.collected,
      );

      if (!mounted) return;
      _showMessageSentDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
    // admin
    // 🔔 ADMIN SMS (ONLY IF ENABLED)
    final admin = await FirebaseService.getAdminInfo();

    if (admin != null &&
        admin['smsEnabled'] == true &&
        admin['phone'] != null &&
        !_mockSms) {
      await twilioFlutter!.sendSMS(
        toNumber: admin['phone'],
        messageBody: _adminCashCollectedMessage(),
      );
    }




  }

  void _showCollectorNameDialog() {
    final TextEditingController _collectorNameController =
        TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Collector Name'),
          content: TextField(
            controller: _collectorNameController,
            decoration: const InputDecoration(
              labelText: 'Enter collector name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _collectorNameController.clear();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate that a name has been entered.
                if (_collectorNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter collector name'),
                    ),
                  );
                  return; // Keep the dialog open for the user to enter a name.
                }

                // Save the collector's name from the text field.
                final collectorName = _collectorNameController.text.trim();
                _currentCollectorName = collectorName;

                // Now, regenerate the message content with the collector's name.
                _messageController.text = _generateCollectionMessage();

                // Send the updated message.
                _sendMessageForCollection();

                // Close the name entry dialog.
                Navigator.of(dialogContext).pop();

                // Navigate to the screen for entering the collected amount.
                /*
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EnterAmountScreen(
                      box: widget.box,
                      collectorName: _currentCollectorName!,
                    ),
                  ),
                );

                 */
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ✅ CONFIRMATION DIALOG (UNCHANGED)
  void _showMessageSentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Message Sent'),
          content: Text(
            'Message for collection of box has been sent to ${widget.box.contactPersonName}',
          ),
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
        );
      },
    );
  }







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

  //status label
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyles.bodyMedium.copyWith(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // open with feature
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Action', style: TextStyles.h1),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.green.shade50,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ STATUS LABEL
                    Align(
                      alignment: Alignment.center,
                      child: _statusLabel(widget.box.status),
                    ),

                    const SizedBox(height: 12),

                    infoRow('Venue Name', widget.box.venueName),
                    const Divider(height: 20, thickness: 2),
                    infoRow('Contact Person', widget.box.contactPersonName),
                    const Divider(height: 20, thickness: 2),
                    infoRow('Phone Number', widget.box.contactPersonPhone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                //height: 250,
                width: 1000,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    Text(
                      'Box ${widget.box.boxSequence.toString().padLeft(3, '0')}',
                      style: TextStyles.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: widget.box.boxId,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text('Box ID: ${widget.box.boxId}', style: TextStyles.best),
                    const SizedBox(height: 12),
                    Center(
                      child: FilledButton.icon(
                        onPressed: _openQrPdf,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text("OPEN WITH"),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: canCollectCash(widget.box)
                      ? _showCollectorNameDialog
                      : null,
                  icon: const Icon(Icons.currency_pound),
                  label: const Text('Collect Cash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: canSendReceipt(widget.box)
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EnterAmountScreen(
                                box: widget.box,
                                collectorName:
                                    _currentCollectorName ??
                                    'Unknown', // ✅ pass it here
                              ),
                            ),
                          );
                        }
                      : null,

                  icon: const Icon(Icons.mail_outline_outlined),
                  label: const Text('Send Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text('$label:', style: TextStyles.bodyMedium),
          ),
          Expanded(flex: 4, child: Text(value, style: TextStyles.bodyLarge)),
        ],
      ),
    );
  }
}
