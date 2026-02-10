import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';

class AdminInformationScreen extends StatefulWidget {
  const AdminInformationScreen({super.key});

  @override
  State<AdminInformationScreen> createState() =>
      _AdminInformationScreenState();
}

class _AdminInformationScreenState extends State<AdminInformationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _smsEnabled = false;
  bool _isLoading = true;
  bool _nameError = false;
  bool _phoneError = false;
  bool _hasChanges = false;
  bool _isSaving = false;

  String _initialName = '';
  String _initialPhone = '';
  String _initialAddress = '';
  bool _initialSmsEnabled = false;

  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  /// 🔹 Load admin info from Firebase
  Future<void> _loadAdminInfo() async {
    try {
      final adminData = await FirebaseService.getAdminInfo();

      if (adminData != null) {
        _initialName = adminData['name'] ?? '';
        _initialPhone = adminData['phone'] ?? '';
        _initialAddress = adminData['address'] ?? '';
        _initialSmsEnabled = adminData['smsEnabled'] ?? false;

        _nameController.text = _initialName;
        _phoneController.text = _initialPhone;
        _addressController.text = _initialAddress;
        _smsEnabled = _initialSmsEnabled;
      }
    } catch (e) {
      debugPrint('Error loading admin info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkForChanges() {
    final hasChanged =
        _nameController.text.trim() != _initialName ||
            _phoneController.text.trim() != _initialPhone ||
            _addressController.text.trim() != _initialAddress ||
            _smsEnabled != _initialSmsEnabled;

    if (_hasChanges != hasChanged) {
      setState(() {
        _hasChanges = hasChanged;
      });
    }
  }

  /// 🔹 Save admin info
  Future<void> _saveAdminInfo() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    bool hasError = false;

    setState(() {
      _nameError = false;
      _phoneError = false;
    });

    // Name validation
    if (name.isEmpty) {
      _nameError = true;
      hasError = true;
    }

    // Phone validation: UK format +44XXXXXXXXXX
    final phoneRegex = RegExp(r'^\+44\d{10}$');
    if (phone.isEmpty || !phoneRegex.hasMatch(phone)) {
      _phoneError = true;
      hasError = true;
    }

    if (hasError) {
      setState(() {}); // update UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fix the errors in the form'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; // stop saving
    }

    setState(() {
      _isSaving = true;
    });

    // ✅ Save data
    final data = {
      'name': name,
      'phone': phone,
      'address': address,
      'smsEnabled': _smsEnabled,
      'updatedAt': DateTime.now(),
    };

    try {
      await FirebaseService.saveAdminInfo(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Admin info saved successfully'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Reset baseline after successful save
      _initialName = name;
      _initialPhone = phone;
      _initialAddress = address;
      _initialSmsEnabled = _smsEnabled;

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save admin info: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF265d60))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                    "Admin Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // ---------------- Content ----------------
            Padding(
               padding: const EdgeInsets.all(24),
               child: Form(
                 key: _formKey,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     // Profile Icon (Decorative)
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
                          child: Icon(Icons.admin_panel_settings, size: 40, color: secondaryColor),
                        ),
                     ),
            
                     // Name
                     _buildModernTextField(
                       controller: _nameController,
                       label: 'Admin Name',
                       icon: Icons.person_outline,
                       errorText: _nameError ? 'Admin name is required' : null,
                     ),
                     const SizedBox(height: 16),
            
                     // Phone Number
                     _buildModernTextField(
                       controller: _phoneController,
                       label: 'Phone Number',
                       icon: Icons.phone_outlined,
                       hint: '+44XXXXXXXXXX',
                       keyboardType: TextInputType.phone,
                       errorText: _phoneError ? 'Enter valid UK number (+44...)' : null,
                     ),
                     const SizedBox(height: 16),
            
                     // Address
                     _buildModernTextField(
                       controller: _addressController,
                       label: 'Address (Optional)',
                       icon: Icons.location_on_outlined,
                     ),
                     const SizedBox(height: 24),
            
                     // SMS Switch
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
                       ),
                       child: SwitchListTile(
                         activeColor: secondaryColor,
                         activeTrackColor: secondaryColor.withOpacity(0.3),
                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         secondary: Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(
                             color: _smsEnabled ? primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                             _smsEnabled ? Icons.notifications_active : Icons.notifications_off_outlined, 
                             color: _smsEnabled ? primaryColor : Colors.grey,
                           ),
                         ),
                         title:  Text(
                           'Transaction Alerts',
                           style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                         ),
                         subtitle: Text(
                           'Receive SMS alerts for collections',
                           style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12),
                         ),
                         value: _smsEnabled,
                         onChanged: (value) {
                           setState(() {
                             _smsEnabled = value;
                           });
                           _checkForChanges();
                         },
                       ),
                     ),
                     
                     const SizedBox(height: 32),
                     
                     // Save Button
                     SizedBox(
                       height: 55,
                        child: ElevatedButton(
                          onPressed: _hasChanges && !_isSaving ? _saveAdminInfo : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: _hasChanges ? 5 : 0,
                          ),
                          child: _isSaving 
                            ? const SizedBox(
                                height: 24, 
                                width: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            :  Text(
                                'SAVE PROFILE',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                        ),
                     ),
                   ],
                 ),
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
    TextInputType? keyboardType,
    int maxLines = 1,
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
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: ((_) {
              if (errorText != null) {
                // We handle error clearing in setState above, 
                // but need to ensure checkChanges always runs
              }
               _checkForChanges();
            }),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
              prefixText: prefixText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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



