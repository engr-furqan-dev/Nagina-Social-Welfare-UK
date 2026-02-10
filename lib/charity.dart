import 'package:flutter/material.dart';

class CharityApp extends StatelessWidget {
  const CharityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Charity Box App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const LoginScreen(),
    );
  }
}

/* ---------------- LOGIN SCREEN ---------------- */

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volunteer_activism,
                size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text("Charity Collection",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            const TextField(
              decoration: InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                },
                child: const Text("LOGIN"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/* ---------------- DASHBOARD ---------------- */

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard", style: TextStyle(fontSize: 24, color: Colors.white)),
          backgroundColor: Colors.green,),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

                const InfoCard("Total Boxes", "1"),
                SizedBox(height: 12),
                const InfoCard("This Month", "£300"),

            const SizedBox(height: 16),
            const InfoCard("Last Collection", "Today"),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("COLLECT CASH"),
            )
          ],
        ),
      ),
    );
  }
}

/* ---------------- ADD BOX ---------------- */

class AddBoxScreen extends StatelessWidget {
  const AddBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Box",style: TextStyle(fontSize: 24, color: Colors.white)),
        backgroundColor: Colors.green,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            TextField(decoration: InputDecoration(labelText: "Venue Name")),
            SizedBox(height: 16),
            TextField(decoration: InputDecoration(labelText: "Owner Phone")),
            SizedBox(height: 16),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Box ID",
                hintText: "BOX123",
              ),
            ),
            SizedBox(height: 32),
            FilledButton(child: Text("SAVE BOX"), onPressed: null),
          ],
        ),
      ),
    );
  }
}

/* ---------------- SCAN SCREEN ---------------- */

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Box",style: TextStyle(fontSize: 24, color: Colors.white)),
        backgroundColor: Colors.green,),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code, size: 120, color: Colors.green),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EnterAmountScreen()),
                );
              },
              child: const Text("SIMULATE SCAN"),
            )
          ],
        ),
      ),
    );
  }
}

/* ---------------- ENTER AMOUNT ---------------- */

class EnterAmountScreen extends StatelessWidget {
  const EnterAmountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Amount",style: TextStyle(fontSize: 24, color: Colors.white)),
        backgroundColor: Colors.green,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Mall Entrance",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: "£ ",
                labelText: "Collected Amount",
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.popUntil(context, (r) => r.isFirst);
                },
                child: const Text("SUBMIT"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/* ---------------- View list of all Boxes ---------------- */
class AllBoxesScreen extends StatelessWidget {
  const AllBoxesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("List of All Boxes",style: TextStyle(fontSize: 24, color: Colors.white)),
        backgroundColor: Colors.green,),
      body: ListView(
        children: const [
          ListTile(title: Text("Mall Entrance"), trailing: Text("£1200")),
          ListTile(title: Text("Supermarket"), trailing: Text("£850")),
          ListTile(title: Text("Station"), trailing: Text("£1100")),
        ],
      ),
    );
  }
}

/* ---------------- MONTHLY SUMMARY ---------------- */

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Summary",style: TextStyle(fontSize: 24, color: Colors.white)),
      backgroundColor: Colors.green,),
      body: ListView(
        children: const [
          ListTile(title: Text("Mall Entrance"), trailing: Text("£1200")),
          ListTile(title: Text("Supermarket"), trailing: Text("£850")),
          ListTile(title: Text("Station"), trailing: Text("£1100")),
        ],
      ),
    );
  }
}

/* ---------------- DRAWER ---------------- */

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
      child: Center(
            child: Text("Charity App",
                style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
          ),decoration: BoxDecoration(color: Colors.green),),
          ListTile(
            leading: Icon(Icons.home_filled, color: Colors.green),
            title: const Text("Dashboard"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.add_box_rounded, color: Colors.green),
            title: const Text("Add Box"),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddBoxScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.view_list, color: Colors.green),
            title: const Text("View All Boxes"),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AllBoxesScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.summarize_rounded, color: Colors.green),
            title: const Text("Monthly Summary"),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SummaryScreen()));
            },
          ),
        ],
      ),
    );
  }
}

/* ---------------- REUSABLE CARD ---------------- */

class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(title),
            const SizedBox(height: 8),
            Spacer(),
            Text(value,
                textAlign: TextAlign.left,
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,)),
          ],
        ),
      ),
    );
  }
}
