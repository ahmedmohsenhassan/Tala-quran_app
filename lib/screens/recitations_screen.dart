import 'package:flutter/material.dart';

class RecitationsScreen extends StatelessWidget {
  const RecitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التلاوات')),
      body: const Center(child: Text('صفحة التلاوات')),
    );
  }
}
