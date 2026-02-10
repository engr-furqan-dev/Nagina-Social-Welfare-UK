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
import '../../models/collector_model.dart';
import '../../models/box_model.dart';
import '../../services/firebase_service.dart';
import 'enter_amount_for_collector.dart';

class BoxDetailForCollectorScreen extends StatefulWidget {
  final BoxModel box;
  final CollectorModel collector;
  const BoxDetailForCollectorScreen({super.key, required this.box, required this.collector});

  @override
  State<BoxDetailForCollectorScreen> createState() => _BoxDetailForCollectorScreenState();
}

class _BoxDetailForCollectorScreenState extends State<BoxDetailForCollectorScreen> {
  String? _currentCollectorName;

  final now = DateTime.now();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

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

    return '''
Dear ${widget.box.contactPersonName},

The collection box has been collected by ${widget.collector.name}.
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
    final TextEditingController collectorNameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Collector Name'),
          content: TextField(
            controller: collectorNameController,
            decoration: const InputDecoration(
              labelText: 'Enter collector name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                collectorNameController.clear();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (collectorNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter collector name'),
                    ),
                  );
                  return;
                }

                final collectorName = collectorNameController.text.trim();
                _currentCollectorName = collectorName;

                _messageController.text = _generateCollectionMessage();
                _sendMessageForCollection();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ✅ CONFIRMATION DIALOG
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == BoxStatus.sentReceipt ? Icons.check_circle : Icons.info,
            size: 16,
            color: _getStatusColor(status),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(status),
            style: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // open with feature
  Future<void> _openQrPdf() async {
    try {
      final pdfBytes = await _generateQrPdf();

      final dir = (await getExternalStorageDirectory()) ?? await getTemporaryDirectory();
      final filePath = '${dir.path}/box_qr_${widget.box.boxId}.pdf';
      final file = File(filePath);

      await file.writeAsBytes(pdfBytes, flush: true);

      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No app found to open PDF')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCollectEnabled = canCollectCash(widget.box);
    final isReceiptEnabled = canSendReceipt(widget.box);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ---------------- Gradient Header ----------------
          Container(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
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
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Box Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                children: [
                  // ---------------- Info Card ----------------
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _statusLabel(widget.box.status),
                        const SizedBox(height: 20),
                        _buildInfoRow(Icons.place, 'Venue Name', widget.box.venueName),
                        const Divider(height: 30),
                        _buildInfoRow(Icons.person, 'Contact Person', widget.box.contactPersonName),
                        const Divider(height: 30),
                        _buildInfoRow(Icons.phone, 'Phone Number', widget.box.contactPersonPhone),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- QR Code Card ----------------
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Box ${widget.box.boxSequence.toString().padLeft(3, '0')}',
                          style: TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.bold,
                             color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                           padding: const EdgeInsets.all(10),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(10),
                             border: Border.all(color: Colors.grey.shade200),
                           ),
                           child: QrImageView(
                            data: widget.box.boxId,
                            size: 160,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ID: ${widget.box.boxId}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openQrPdf,
                            icon: const Icon(Icons.file_open_outlined),
                            label: const Text("Open in PDF"),
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
                  ),

                  const SizedBox(height: 30),

                  // ---------------- Action Buttons ----------------
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          title: "Collect Cash",
                          icon: Icons.currency_pound,
                          color: secondaryColor,
                          isEnabled: isCollectEnabled,
                          onPressed: _sendMessageForCollection,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          title: "Send Receipt",
                          icon: Icons.receipt_long,
                          color: Colors.green, // Keep green as it implies success/completion
                          isEnabled: isReceiptEnabled,
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EnterAmountScreen(
                                  box: widget.box,
                                  collector: widget.collector,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade500,
        padding: const EdgeInsets.symmetric(vertical: 20),
        elevation: isEnabled ? 4 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: color.withOpacity(0.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
