import 'package:flutter/material.dart';

class AdminSubPageScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const AdminSubPageScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: child,
      ),
    );
  }
}
