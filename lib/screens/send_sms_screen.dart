import 'package:flutter/material.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

class SendSmsScreen extends StatefulWidget {
  const SendSmsScreen({super.key});

  @override
  State<SendSmsScreen> createState() => _SendSmsScreenState();
}

class _SendSmsScreenState extends State<SendSmsScreen> {
  late TwilioFlutter twilioFlutter;
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    twilioFlutter = TwilioFlutter(
      accountSid: 'ACb2de03afb31797babd208aa7b410eb69', // Add your Account SID
      authToken: '8d040ac39a47f7e219344b71fa533ec2', // Add your Auth Token
      twilioNumber: 'MarkazIslam', // Add your Twilio number
    );
  }

  void _sendSms() async {
    if (_phoneController.text.isEmpty || _messageController.text.isEmpty) {
      // Show error if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number and message')),
      );
      return;
    }

    try {
      await twilioFlutter.sendSMS(
        toNumber: _phoneController.text,
        messageBody: _messageController.text,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SMS Sent Successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending SMS: $e')));
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send SMS'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (with country code)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _sendSms, child: const Text('Send SMS')),
          ],
        ),
      ),
    );
  }
}
