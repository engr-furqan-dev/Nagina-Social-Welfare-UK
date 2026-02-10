import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CollectorDetailScreen extends StatefulWidget {
  final String collectorId;
  const CollectorDetailScreen({super.key, required this.collectorId});

  @override
  State<CollectorDetailScreen> createState() => _CollectorDetailScreenState();
}

class _CollectorDetailScreenState extends State<CollectorDetailScreen> {
  bool isLoading = true;
  bool hasChanges = false;
  bool nameError = false;
  bool phoneError = false;
  bool usernameError = false;
  bool passwordError = false;
  bool _obscurePassword = true;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  Map<String, dynamic>? _initialData;
  DocumentReference? _collectorDoc;
  
  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

  @override
  void initState() {
    super.initState();
    _loadCollector();
  }

  Future<void> _loadCollector() async {
    final doc = FirebaseFirestore.instance.collection('collectors').doc(widget.collectorId);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collector not found')),
        );
        Navigator.pop(context);
      }
      return;
    }

    final data = snapshot.data()!;
    _collectorDoc = doc;

    _nameController = TextEditingController(text: data['name']);
    _phoneController = TextEditingController(
        text: data['phone'].toString().startsWith('+44')
            ? data['phone'].toString().substring(3)
            : data['phone'].toString());
    _addressController = TextEditingController(text: data['address'] ?? '');
    _usernameController = TextEditingController(text: data['username']);
    _passwordController = TextEditingController(text: data['password']);

    _initialData = data;

    setState(() {
      isLoading = false;
    });
  }

  void _checkForChanges() {
    final changed = _nameController.text.trim() != (_initialData?['name'] ?? '') ||
        _phoneController.text.trim() != (_initialData?['phone'] ?? '').toString().replaceFirst('+44', '') ||
        _addressController.text.trim() != (_initialData?['address'] ?? '') ||
        _usernameController.text.trim() != (_initialData?['username'] ?? '') ||
        _passwordController.text.trim() != (_initialData?['password'] ?? '');

    setState(() {
      hasChanges = changed;
    });
  }

  bool _validateFields() {
    bool hasError = false;
    setState(() {
      nameError = _nameController.text.trim().isEmpty || _nameController.text.trim().length > 255;
      phoneError = !RegExp(r'^\d{10}$').hasMatch(_phoneController.text.trim());
      usernameError = _usernameController.text.trim().isEmpty;
      passwordError = _passwordController.text.trim().isEmpty;

      hasError = nameError || phoneError || usernameError || passwordError;
    });

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fix the highlighted fields'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return !hasError;
  }

  Future<void> _updateCollector() async {
    if (!_validateFields() || _collectorDoc == null) return;

    try {
      await _collectorDoc!.update({
        'name': _nameController.text.trim(),
        'phone': '+44${_phoneController.text.trim()}',
        'address': _addressController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Collector updated successfully'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating collector: $e')),
      );
    }
  }

  Future<void> _deleteCollector() async {
    if (_collectorDoc == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Delete Collector'),
        content: const Text('Are you sure you want to delete this collector?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child:  Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _collectorDoc!.delete();
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collector deleted successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting collector: $e')),
        );
      }
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final date = ts.toDate();
    int hour = date.hour % 12;
    if (hour == 0) hour = 12;
    String minute = date.minute.toString().padLeft(2, '0');
    String period = date.hour >= 12 ? 'PM' : 'AM';
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year} $hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
                    "Collector Details",
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar with Edit Badge
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          height: 90,
                          width: 90,
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
                          child: Icon(Icons.person, size: 45, color: secondaryColor),
                        ),
                        // Badge
                         Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Name
                  _buildModernTextField(
                    controller: _nameController,
                    label: "Name",
                    icon: Icons.person_outline,
                    errorText: nameError ? "Name is required (max 255 chars)" : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  _buildModernTextField(
                    controller: _phoneController,
                    label: "Contact Phone",
                     icon: Icons.phone_outlined,
                     prefixText: "+44 ",
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    errorText: phoneError ? "Enter exactly 10 digits" : null,
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
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow("Created On", _formatDate(_initialData?['createdAt'])),
                        const SizedBox(height: 4),
                        _buildInfoRow("Last Updated", _formatDate(_initialData?['updatedAt'])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  /// ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _deleteCollector,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.red.withOpacity(0.05),
                             shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Delete Account"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2, // Give more space to update
                        child: ElevatedButton(
                          onPressed: hasChanges ? _updateCollector : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: hasChanges ? 5 : 0,
                          ),
                          child:  Text("Update Changes", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: GoogleFonts.poppins(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
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
               // Notify change detection
               _checkForChanges();
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
