import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/request_model.dart';

class RequestThumbnail extends StatelessWidget {
  const RequestThumbnail({
    super.key,
    required this.request,
    this.width = 58,
    this.height = 58,
  });

  final RequestModel request;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final issueType = request.issueType.toLowerCase();
    final (icon, backgroundColor, iconColor) = switch (issueType) {
      'spill' => (
        Icons.water_drop_outlined,
        const Color(0xFFDCEEFF),
        const Color(0xFF3888C7),
      ),
      'restroom' => (
        Icons.wc_outlined,
        const Color(0xFFEDE5F5),
        const Color(0xFF76569B),
      ),
      'trash' => (
        Icons.delete_outline,
        const Color(0xFFECE8DF),
        const Color(0xFF74654E),
      ),
      _ => (
        Icons.cleaning_services_outlined,
        const Color(0xFFE4E1D8),
        const Color(0xFF66756D),
      ),
    };

    Widget categoryIcon() => ColoredBox(
      color: backgroundColor,
      child: Center(child: Icon(icon, size: 31, color: iconColor)),
    );

    final imageUrl = request.imageUrl;
    final encodedPhoto = request.photoBase64;
    final Uint8List? photoBytes;
    try {
      photoBytes = encodedPhoto == null || encodedPhoto.isEmpty
          ? null
          : base64Decode(encodedPhoto);
    } on FormatException {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(width: width, height: height, child: categoryIcon()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: height,
        child: photoBytes != null
            ? Image.memory(
                photoBytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => categoryIcon(),
              )
            : imageUrl == null || imageUrl.isEmpty
            ? categoryIcon()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => categoryIcon(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return categoryIcon();
                },
              ),
      ),
    );
  }
}
