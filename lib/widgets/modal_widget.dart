import 'package:flutter/material.dart';

class ModalWidget extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final bool isScrollable;

  const ModalWidget({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.isScrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: isScrollable ? SingleChildScrollView(child: content) : content,
      actions: actions,
    );
  }
}
