import 'package:flutter/material.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

import 'collector_dashboard_screen.dart';
import '../../models/box_model.dart';
import '../../models/collection_model.dart';
import '../../services/firebase_service.dart';
import '../../models/collector_model.dart';

class EnterAmountScreen extends StatefulWidget {
  final BoxModel box;
  final CollectorModel collector;
  const EnterAmountScreen({super.key, required this.box, required this.collector});

  @override
  State<EnterAmountScreen> createState() => _EnterAmountScreenState();
}

class _EnterAmountScreenState extends State<EnterAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isSubmitting = false;
  final bool _mockSms = false;
  TwilioFlutter? _twilioFlutter;

  @override
  void initState() {
    super.initState();
    if (!_mockSms) {
      _twilioFlutter = TwilioFlutter(
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
        "${date.year} $hour:$minute $period";
  }

  String _adminReceiptMessage(double amount) {
    final timestamp = _formatDate(DateTime.now());
    return '''
Receipt sent successfully.

Box ID: ${widget.box.boxId}
Amount: £$amount
Collected By: ${widget.collector.name}

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
      final parsedAmount = double.tryParse(_amountController.text.trim());
      if (parsedAmount == null || parsedAmount <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }
      final double amount = parsedAmount;

      await FirebaseService().addCollection(
        CollectionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          boxId: widget.box.boxId,
          amount: amount,
          date: DateTime.now(),
          receiptSent: true,
          collectedBy: widget.collector.name,
        ),
      );

      await FirebaseService().completeBoxCycle(widget.box.boxId);

      if (_mockSms) {
        await Future.delayed(const Duration(seconds: 1));
        debugPrint('MOCK SMS SENT TO CONTACT PERSON');
      } else {
        await _twilioFlutter!.sendSMS(
          toNumber: widget.box.contactPersonPhone,
          messageBody: _generateReceiptMessage(amount),
        );
      }

      await FirebaseService().updateBoxStatus(
        widget.box.boxId,
        BoxStatus.sentReceipt,
      );

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
          content: Text('Receipt has been sent to ${widget.box.contactPersonName}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CollectorDashboardScreen(collector: widget.collector),
                  ),
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
    const Color primaryColor = Color(0xFF265d60);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withOpacity(0.85)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  offset: const Offset(0, 10),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.payments_outlined, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  "Enter Collection Amount",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          offset: const Offset(0, 4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _modernInfoRow(Icons.person_outline, "Collected By", widget.collector.name),
                        const SizedBox(height: 16),
                        _modernInfoRow(Icons.inventory_2_outlined, "Box ID", widget.box.boxId),
                        const SizedBox(height: 16),
                        _modernInfoRow(Icons.contact_phone_outlined, "Contact Person", widget.box.contactPersonName),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Amount Label
                  const Text(
                    "Collected Amount",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),

                  // Amount Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          offset: const Offset(0, 4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.currency_pound, color: primaryColor),
                        hintText: "Enter amount",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _sendReceipt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "SEND RECEIPT",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF265d60).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF265d60), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
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
