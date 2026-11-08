import 'dart:convert';

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
    final imageData = imageUrl == null
        ? null
        : imageUrl.startsWith('data:')
        ? imageUrl.substring(imageUrl.indexOf(',') + 1)
        : imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: height,
        child: imageData == null || imageData.isEmpty
            ? categoryIcon()
            : _requestImage(imageUrl!, imageData, categoryIcon),
      ),
    );
  }

  Widget _requestImage(
    String source,
    String imageData,
    Widget Function() categoryIcon,
  ) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => categoryIcon(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : categoryIcon(),
      );
    }
    try {
      return Image.memory(
        base64Decode(imageData),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => categoryIcon(),
      );
    } on FormatException {
      return categoryIcon();
    }
  }
}
