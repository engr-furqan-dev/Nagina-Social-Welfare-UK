import 'package:flutter/material.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

import 'dashboard_screen.dart';
import '../../models/box_model.dart';
import '../../models/collection_model.dart';
import '../../services/firebase_service.dart';

class EnterAmountScreen extends StatefulWidget {
  final BoxModel box;
  final String collectorName;
  const EnterAmountScreen({super.key, required this.box, required this.collectorName});

  @override
  State<EnterAmountScreen> createState() => _EnterAmountScreenState();
}

class _EnterAmountScreenState extends State<EnterAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
 // final TextEditingController _collectorNameController = TextEditingController();


  bool _isSubmitting = false;

  /// 🔹 MOCK SWITCH (true = NO real SMS)
  final bool _mockSms = false;

  TwilioFlutter? _twilioFlutter;

  @override
  void initState() {
    super.initState();

    /// Initialize Twilio ONLY if real SMS is required
    if (!_mockSms) {
      _twilioFlutter = TwilioFlutter(
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
  String _adminReceiptMessage(double amount) {
    final timestamp = _formatDate(DateTime.now());
    return '''
Receipt sent successfully.

Box ID: ${widget.box.boxId}
Amount: £$amount
Collected By: ${widget.collectorName}

$timestamp
''';
  }



  String _generateReceiptMessage(double amount) {
    final timestamp = _formatDate(DateTime.now());
    return '''
Dear ${widget.box.contactPersonName},

£$amount has been collected from your donation box.
Thank you for your support.

Markaz-e-Islam
$timestamp
''';
  }

  Future<void> _sendReceipt() async {
    setState(() => _isSubmitting = true);

    try {
      // 1️⃣ Parse and validate amount
      final parsedAmount = double.tryParse(_amountController.text.trim());
      if (parsedAmount == null || parsedAmount <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }
      final double amount = parsedAmount; // ✅ now safe non-nullable

      // 2️⃣ Add collection
      await FirebaseService().addCollection(
        CollectionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          boxId: widget.box.boxId,
          amount: amount,
          date: DateTime.now(),
          receiptSent: true,
          collectedBy: widget.collectorName,
        ),
      );

      // 3️⃣ Update box status → collected
      await FirebaseService().completeBoxCycle(widget.box.boxId);

      // 4️⃣ Send SMS to contact person
      if (_mockSms) {
        await Future.delayed(const Duration(seconds: 1));
        debugPrint('MOCK SMS SENT TO CONTACT PERSON');
      } else {
        await _twilioFlutter!.sendSMS(
          toNumber: widget.box.contactPersonPhone,
          messageBody: _generateReceiptMessage(amount),
        );
      }

      // 5️⃣ Update box status → sentReceipt
      await FirebaseService().updateBoxStatus(
        widget.box.boxId,
        BoxStatus.sentReceipt,
      );

      // 6️⃣ Send SMS to admin (if enabled)
      final admin = await FirebaseService.getAdminInfo();
      if (admin != null &&
          admin['smsEnabled'] == true &&
          admin['phone'] != null &&
          !_mockSms) {
        await _twilioFlutter!.sendSMS(
          toNumber: admin['phone'],
          messageBody: _adminReceiptMessage(amount),
        );
      }

      // 7️⃣ Show confirmation dialog
      if (!mounted) return;
      _showReceiptSentDialog();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending receipt: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  void _showReceiptSentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Receipt Sent'),
          content: Text(
            'Receipt has been sent to ${widget.box.contactPersonName}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Enter Amount"),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Card with Box Details
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow("Collected By", widget.collectorName),
                      const SizedBox(height: 8),
                      _infoRow("Box ID", widget.box.boxId),
                      const SizedBox(height: 8),
                      _infoRow("Contact Person", widget.box.contactPersonName),
                    ],
                  ),
                ),
              ),

              // Amount Input
              Text(
                "Collected Amount",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: "£ ",
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Enter amount",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _sendReceipt,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    "SEND RECEIPT",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
