import 'package:flutter/material.dart';
import '../screens/styles/text_style.dart';

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
            Text(title,style: TextStyles.bodyLarge,),
            const Spacer(),
            Text(
              value,
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
