import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().isEmpty
        ? 'unknown'
        : status.toLowerCase().replaceAll('_', ' ');
    final color = switch (normalized) {
      'pending' => const Color(0xFFFFE6B3),
      'in progress' || 'accepted' => const Color(0xFFD8E8FF),
      'completed' => const Color(0xFFD8F3E7),
      'cancelled' => const Color(0xFFFFDAD6),
      _ => const Color(0xFFE7E7E7),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalized[0].toUpperCase() + normalized.substring(1),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}