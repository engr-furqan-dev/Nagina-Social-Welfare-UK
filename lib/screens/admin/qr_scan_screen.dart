import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'box_action_screen.dart';
import '../../models/box_model.dart';
import '../../services/firebase_service.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool isScanned = false;
  final FirebaseService _firebaseService = FirebaseService();
  final MobileScannerController controller = MobileScannerController();

  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (isScanned) return;

    final String? code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => isScanned = true);

    // Provide visual feedback (vibrate or sound could be added here)
    
    try {
      final BoxModel? box = await _firebaseService.getBoxByBoxId(code);

      if (!mounted) return;

      if (box == null) {
        _showErrorAndReset('Box not found');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BoxActionScreen(box: box),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorAndReset('Error: $e');
    }
  }

  void _showErrorAndReset(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Delay slightly before re-enabling scan to avoid rapid loops
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => isScanned = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Scanner Camera
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),

          // 2. Value Overlay (Darkened Background + cutout)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstIn,
                  ),
                ),
                Center(
                  child: Container(
                    height: 280,
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Scan Border UI
          Center(
            child: Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: secondaryColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                   // Corners (optional decorative corners could go here)
                   // Loading indicator if scanned
                   if (isScanned)
                     const Center(
                       child: CircularProgressIndicator(color: Colors.white),
                     ),
                ],
              ),
            ),
          ),

          // 4. Header & Controls
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                       Text(
                        "Scan QR Code",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.toggleTorch(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: ValueListenableBuilder(
                            valueListenable: controller,
                            builder: (context, state, child) {
                              final torchState = state.torchState;
                              return Icon(
                                torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                                color: torchState == TorchState.on ? secondaryColor : Colors.white,
                                size: 20,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Instruction
                Text(
                  "Align the QR code within the frame",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                 isScanned ? "Processing..." : "Scanning...",
                  style: GoogleFonts.poppins(
                    color: secondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
