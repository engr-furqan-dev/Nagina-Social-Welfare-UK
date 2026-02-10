import 'package:flutter/material.dart';
import '../screens/admin/add_box_screen.dart';
import '../screens/admin/all_boxes_screen.dart';
import '../screens/admin/monthly_summary_screen.dart';
import '../screens/styles/text_style.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Center(
              child: Text(
                "Charity Collection",
                style: TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_filled, color: Colors.green),
            title: const Text("Dashboard",style: TextStyles.h2,),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.add_box_rounded, color: Colors.green),
            title: const Text("Add New Box",style: TextStyles.h2,),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddBoxScreen(),));
            },
          ),
          ListTile(
            leading: const Icon(Icons.view_list, color: Colors.green),
            title: const Text("View All Boxes",style: TextStyles.h2,),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AllBoxesScreen()));
            },
          ),
          ListTile(
            leading:
            const Icon(Icons.summarize_rounded, color: Colors.green),
            title: const Text("Monthly Summary",style: TextStyles.h2,),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MonthlySummaryScreen()));
            },
          ),
        ],
      ),
    );
  }
}
