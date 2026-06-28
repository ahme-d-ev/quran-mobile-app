import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عن التطبيق')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
            'تطبيق بسيط لعرض سور وآيات القرآن مع إمكانيات المفضلة، حفظ آخر موضع، وتعديل حجم الخط.'),
      ),
    );
  }
}
