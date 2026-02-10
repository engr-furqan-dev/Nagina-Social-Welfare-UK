import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AddCollectorScreen extends StatefulWidget {
  const AddCollectorScreen({super.key});

  @override
  State<AddCollectorScreen> createState() => _AddCollectorScreenState();
}

class _AddCollectorScreenState extends State<AddCollectorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  // Error flags
  bool nameError = false;
  bool phoneError = false;
  bool usernameError = false;
  bool passwordError = false;

  bool isSaving = false;
  
  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);


  Future<void> _saveCollector() async {
    if (isSaving) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // VALIDATION
    setState(() {
      nameError = name.isEmpty || name.length > 255;
      phoneError = phone.length != 10;
      usernameError = username.isEmpty;
      passwordError = password.isEmpty;
    });

    if (nameError || phoneError || usernameError || passwordError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please check the highlighted fields'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('collectors').add({
        'name': name,
        'phone': '+44$phone',
        'address': _addressController.text.trim(),
        'username': username,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Collector added successfully'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Clear inputs
      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();
      _usernameController.clear();
      _passwordController.clear();

      setState(() {
        isSaving = false;
      });

      Navigator.pop(context);

    } catch (e) {
      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving collector: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                   Text(
                    "Add New Collector",
                    style: GoogleFonts.poppins(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- Form Content ----------------
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Avatar/Icon placeholder (Optional visual flair)
                   Center(
                     child: Container(
                       height: 80,
                       width: 80,
                       margin: const EdgeInsets.only(bottom: 24),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         shape: BoxShape.circle,
                         boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.05),
                             blurRadius: 10,
                             spreadRadius: 2,
                           ),
                         ],
                       ),
                       child: Icon(Icons.person_add, size: 40, color: secondaryColor),
                     ),
                   ),

                  // Name
                  _buildModernTextField(
                    controller: _nameController,
                    label: "Collector Name",
                    icon: Icons.person_outline,
                    errorText: nameError ? "Name is required (max 255 chars)" : null,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]'))],
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  _buildModernTextField(
                    controller: _phoneController,
                    label: "Phone Number",
                    icon: Icons.phone_outlined,
                    hint: "Enter 10-digit number",
                    prefixText: "+44 ",
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    errorText: phoneError ? "Enter exactly 10 digits" : null,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),

                  // Address
                  _buildModernTextField(
                    controller: _addressController,
                    label: "Address (Optional)",
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Username
                  _buildModernTextField(
                    controller: _usernameController,
                    label: "Username",
                    icon: Icons.alternate_email,
                    errorText: usernameError ? "Username is required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _buildModernTextField(
                    controller: _passwordController,
                    label: "Password",
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    errorText: passwordError ? "Password is required" : null,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveCollector,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shadowColor: primaryColor.withOpacity(0.4),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          :  Text(
                              "SAVE COLLECTOR",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                   const SizedBox(height: 20), // Bottom padding
                ],
              ),
            ),
          ],
        ),
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
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style:  GoogleFonts.poppins(
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
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLength: maxLength,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            onChanged: (_) {
               // Simple clearing of error state on type is handled by parent rebuilding with boolean flags,
               // but here we just need to ensure the TextField isn't blocking updates.
               // The parent setState handles the logic.
               if (errorText != null) {
                  // In a real optimized scenario, we would callback up. 
                  // For now, we rely on the submit validation to re-show errors or state updates elsewhere.
               }
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
              prefixText: prefixText,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              counterText: "", // Hide character counter
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
