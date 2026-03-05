import 'package:flutter/material.dart';

class TafseerScreen extends StatelessWidget {
  const TafseerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التفسير')),
      body: const Center(child: Text('صفحة التفسير')),
    );
  }
}
