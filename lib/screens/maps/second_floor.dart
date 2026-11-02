import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class SecondFloorMapScreen extends StatefulWidget {
  const SecondFloorMapScreen({super.key});

  @override
  State<SecondFloorMapScreen> createState() => _SecondFloorMapScreenState();
}

class _SecondFloorMapScreenState extends State<SecondFloorMapScreen> {
  @override
  Future<void> getRoom() async {
    final room = await FirebaseFirestore.instance
        .collection('facilities')
        .doc('K-101')
        .get();
  }

  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [Column(children: [])]),
    );
  }
}
