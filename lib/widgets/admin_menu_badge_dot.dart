import 'package:flutter/material.dart';

Widget adminMenuBadgeDot({required bool visible}) {
  if (!visible) return const SizedBox.shrink();
  return Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
      color: Colors.red,
      shape: BoxShape.circle,
    ),
  );
}
