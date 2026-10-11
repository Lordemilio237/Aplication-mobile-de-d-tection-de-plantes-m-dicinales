import 'package:flutter/material.dart';

Widget buildPlantImage(
  String imageUrl, {
  double? height,
  double? width,
  BoxFit fit = BoxFit.cover,
}) {
  Widget placeholder = Container(
    height: height ?? 100,
    width: width ?? 140,
    color: const Color(0xFFE8F5E9),
    child: const Icon(Icons.eco, size: 40, color: Color(0xFF4CAF50)),
  );

  if (imageUrl.isEmpty) return placeholder;

  if (imageUrl.startsWith('assets/')) {
    return Image.asset(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );
  } else {
    return Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}