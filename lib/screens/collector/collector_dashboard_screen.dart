import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/box_model.dart';
import '../../models/collection_model.dart';
import '../../providers/box_provider.dart';
import '../../providers/collection_provider.dart';
import '../../models/collector_model.dart';
import '../../services/firebase_service.dart';

import '../onboarding_screen.dart';
import 'list_of_box_screen.dart';
import 'box_details_for_collector.dart';
import 'collector_info.dart';
import 'qr_collector.dart';

class CollectorDashboardScreen extends StatefulWidget {
  final CollectorModel collector;
  const CollectorDashboardScreen({super.key, required this.collector});

  @override
  State<CollectorDashboardScreen> createState() =>
      _CollectorDashboardScreenState();
}

class _CollectorDashboardScreenState extends State<CollectorDashboardScreen> {
  final firebaseService = FirebaseService();
  String collectorName = "";
  
  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

  @override
  void initState() {
    super.initState();
    loadCollectorName();
  }

  Future<void> loadCollectorName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      collectorName = prefs.getString('collectorName') ?? widget.collector.name;
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to log out of your account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnBoardingScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.collector.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _handleLogout,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---------------- Data Logic (Hidden) ----------------
          Offstage(
            offstage: true,
            child: Column(
              children: [
                StreamBuilder<List<BoxModel>>(
                  stream: firebaseService.getBoxesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    final boxes = snapshot.hasData ? snapshot.data! : <BoxModel>[];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                       if (context.mounted) {
                          Provider.of<BoxProvider>(context, listen: false).setBoxes(boxes);
                       }
                    });
                    return const SizedBox.shrink();
                  },
                ),
                StreamBuilder<List<CollectionModel>>(
                  stream: firebaseService.getCollections(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    final collections = snapshot.hasData ? snapshot.data! : <CollectionModel>[];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        Provider.of<CollectionProvider>(context, listen: false).setCollections(collections);
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // ---------------- Dashboard Tiles ----------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Overview",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.grey.shade800
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _DashboardTile(
                    title: "Donation Boxes",
                    subtitle: "View and manage assigned boxes",
                    icon: Icons.inventory_2_outlined,
                    color: Colors.blue.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectBoxScreen(collector: widget.collector),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _DashboardTile(
                    title: "Scan Box QR",
                    subtitle: "Scan to identify and update a box",
                    icon: Icons.qr_code_scanner,
                    color: secondaryColor,
                    onTap: () async {
                      final boxId = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QRScanScreen(collector: widget.collector),
                        ),
                      );

                      if (boxId != null && context.mounted) {
                        final box = await FirebaseService().getBoxByBoxId(boxId);

                        if (box != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BoxDetailForCollectorScreen(
                                box: box, 
                                collector: widget.collector,
                              ),
                            ),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Box not found in database!')),
                          );
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  
                  _DashboardTile(
                    title: "My Profile",
                    subtitle: "View your personal information",
                    icon: Icons.person_outline,
                    color: primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CollectorInformationScreen(collector: widget.collector),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Center(
                    child: Text(
                      "Markaz-e-Islam © ${DateTime.now().year}",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
}

class _DashboardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade300, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
