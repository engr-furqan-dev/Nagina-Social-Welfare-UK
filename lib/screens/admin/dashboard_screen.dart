import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/box_model.dart';
import '../../models/collection_model.dart';
import '../../providers/box_provider.dart';
import '../../providers/collection_provider.dart';
import '../../services/firebase_service.dart';
import '../onboarding_screen.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_information_screen.dart';
import 'monthly_summary_screen.dart';

import 'all_boxes_screen.dart';
import 'collector_list_screen.dart';
import 'box_detail_screen.dart';
import 'qr_scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFF265d60);
  final Color secondaryColor = const Color(0xFFd5a148);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔴 RESET CONFIRMATION
  Future<void> _confirmResetAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Reset All Boxes'),
        content: const Text(
          'This will reset ALL boxes to "Not Collected".\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = FirebaseService();
        if (mounted) {
          final boxProvider = context.read<BoxProvider>();
          await service.resetAllBoxesStatus();
          boxProvider.resetAllBoxesLocally();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All boxes reset successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ---------------- Header with Gradient ----------------
          Container(
            padding: const EdgeInsets.only(
              top: 50, // For status bar
              left: 24,
              right: 24,
              bottom: 30,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.85),
                ],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      "Dashboard",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:  Text(
                        "Administrator Panel",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign out'),
                        content: const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // ---------------- Body ----------------
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------------- Live Stats Section ----------------
                      StreamBuilder<List<BoxModel>>(
                        stream: firebaseService.getBoxesStream(),
                        builder: (context, boxSnapshot) {
                          final boxes = boxSnapshot.hasData ? boxSnapshot.data! : <BoxModel>[];
                          
                          // Sync with Provider
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Provider.of<BoxProvider>(context, listen: false).setBoxes(boxes);
                          });

                          return StreamBuilder<List<CollectionModel>>(
                            stream: firebaseService.getCollections(),
                            builder: (context, colSnapshot) {
                              final collections = colSnapshot.hasData ? colSnapshot.data! : <CollectionModel>[];
                              
                              // Sync with Provider
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Provider.of<CollectionProvider>(context, listen: false).setCollections(collections);
                              });
                              
                              final colProvider = context.read<CollectionProvider>(); // Read current state calculated from setCollections if immediate, or wait for next frame. 
                              // Actually, standard provider pattern: updates to provider trigger rebuilds of consumers. 
                              // Here were getting streams directly. Let's calculate stats directly from streams for immediate UI feedback.
                              
                              // Calculate stats manually here to be responsive without waiting for Provider notify
                              double todayTotal = 0;
                              double monthTotal = 0;
                              final now = DateTime.now();
                              
                              for (var col in collections) {
                                if (col.date.year == now.year && col.date.month == now.month) {
                                  monthTotal += col.amount;
                                  if (col.date.day == now.day) {
                                    todayTotal += col.amount;
                                  }
                                }
                              }

                              return SizedBox(
                                height: 130, // Fixed height for carousel
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    _StatCard(
                                      title: "Total Boxes",
                                      value: boxes.length.toString(),
                                      icon: Icons.inventory_2,
                                      color: Colors.blue.shade700,
                                      delay: 0,
                                    ),
                                    const SizedBox(width: 12),
                                    _StatCard(
                                      title: "Collected Today",
                                      value: "£${todayTotal.toStringAsFixed(0)}",
                                      icon: Icons.today,
                                      color: Colors.orange.shade700,
                                      delay: 100,
                                    ),
                                    const SizedBox(width: 12),
                                    _StatCard(
                                      title: "This Month",
                                      value: "£${monthTotal.toStringAsFixed(0)}",
                                      icon: Icons.calendar_month,
                                      color: Colors.teal.shade700,
                                      delay: 200,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      Text(
                        "MENU",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ---------------- Menu Tiles ----------------
                      _DashboardTile(
                        title: "DONATION BOXES",
                        subtitle: "Manage and track all donation boxes",
                        icon: Icons.inventory_2_outlined,
                        color: primaryColor,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllBoxesScreen())),
                        delay: 300,
                      ),
                      const SizedBox(height: 16),
                      _DashboardTile(
                        title: "DONATION SUMMARY",
                        subtitle: "View detailed donation reports",
                        icon: Icons.bar_chart_outlined,
                        color: primaryColor,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlySummaryScreen())),
                        delay: 400,
                      ),
                      const SizedBox(height: 16),
                      _DashboardTile(
                        title: "SCAN BOX QR",
                        subtitle: "Identify boxes via QR code",
                        icon: Icons.qr_code_scanner,
                        color: primaryColor,
                        onTap: () async {
                          final boxId = await Navigator.push(context, MaterialPageRoute(builder: (_) => QRScanScreen()));
                          if (boxId != null) {
                            final box = await FirebaseService().getBoxByBoxId(boxId);
                            if (mounted) {
                              if (box != null) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => BoxDetailScreen(box: box)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Box not found in database!')));
                              }
                            }
                          }
                        },
                        delay: 500,
                      ),
                      const SizedBox(height: 16),
                      _DashboardTile(
                        title: "COLLECTORS",
                        subtitle: "Manage collector accounts",
                        icon: Icons.people_outline,
                        color: primaryColor,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectorListScreen())),
                        delay: 600,
                      ),
                       const SizedBox(height: 16),
                      _DashboardTile(
                        title: "ADMIN PROFILE",
                        subtitle: "Manage profile details",
                        icon: Icons.admin_panel_settings_outlined,
                        color: primaryColor,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminInformationScreen())),
                        delay: 700,
                      ),

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 20),

                      // ---------------- Danger Zone ----------------
                       TweenAnimationBuilder<double>(
                         tween: Tween(begin: 0, end: 1),
                         duration: const Duration(milliseconds: 800),
                         curve: Curves.easeOut,
                         builder: (context, value, child) => Opacity(
                           opacity: value,
                           child: Transform.translate(
                             offset: Offset(0, 20 * (1-value)),
                             child: child,
                           ),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               'DANGER ZONE',
                               style: GoogleFonts.poppins(
                                 fontSize: 14,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.red.shade700,
                                 letterSpacing: 1.0,
                               ),
                             ),
                             const SizedBox(height: 12),
                             Container(
                               decoration: BoxDecoration(
                                 color: Colors.white,
                                 borderRadius: BorderRadius.circular(16),
                                 border: Border.all(color: Colors.red.shade100),
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.red.withOpacity(0.05),
                                     offset: const Offset(0, 4),
                                     blurRadius: 12,
                                   ),
                                 ],
                               ),
                               child: Material(
                                 color: Colors.transparent,
                                 child: InkWell(
                                   onTap: () => _confirmResetAll(context),
                                   borderRadius: BorderRadius.circular(16),
                                   child: Padding(
                                     padding: const EdgeInsets.all(20),
                                     child: Row(
                                       children: [
                                         Container(
                                           padding: const EdgeInsets.all(12),
                                           decoration: BoxDecoration(
                                             color: Colors.red.withOpacity(0.1),
                                             borderRadius: BorderRadius.circular(12),
                                           ),
                                           child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                         ),
                                         const SizedBox(width: 16),
                                         Expanded(
                                           child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                                Text(
                                                 'Reset Monthly Collection',
                                                 style: GoogleFonts.poppins(
                                                   fontWeight: FontWeight.bold,
                                                   fontSize: 16,
                                                   color: Colors.red,
                                                 ),
                                               ),
                                               const SizedBox(height: 4),
                                               Text(
                                                 'Set all boxes to "Not Collected"',
                                                 style: GoogleFonts.poppins(
                                                   fontSize: 13,
                                                   color: Colors.grey.shade600,
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
                                         const Icon(Icons.chevron_right, color: Colors.red),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: child,
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   value,
                   style:  GoogleFonts.poppins(
                     fontSize: 20,
                     fontWeight: FontWeight.bold,
                     color: Colors.white,
                   ),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   title,
                   style: GoogleFonts.poppins(
                     fontSize: 12,
                     color: Colors.white.withOpacity(0.8),
                   ),
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final int delay;

  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
         return Opacity(
           opacity: value,
           child: Transform.translate(
             offset: Offset(0, 50 * (1 - value)),
             child: child,
           ),
         );
      },
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey[300]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
