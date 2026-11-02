import 'package:flutter/material.dart';
import 'first_floor.dart';
import 'second_floor.dart';
import 'third_floor.dart';

class TestRoomScreen extends StatefulWidget {
  const TestRoomScreen({super.key});

  @override
  State<TestRoomScreen> createState() => _TestRoomScreenState();
}

class _TestRoomScreenState extends State<TestRoomScreen> {
  // Stores the currently selected floor
  int selectedFloor = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text('Test Room'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Floor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // FLOOR DROPDOWN
            DropdownButtonFormField<int>(
              key: ValueKey(selectedFloor),
              initialValue: selectedFloor,

              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: Colors.white,

              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.teal,
              ),

              style: const TextStyle(fontSize: 16, color: Colors.black87),

              decoration: InputDecoration(
                labelText: 'Select Floor',

                prefixIcon: const Icon(
                  Icons.layers_outlined,
                  color: Colors.teal,
                ),

                filled: true,
                fillColor: Colors.white,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),

              items: const [
                DropdownMenuItem<int>(value: 1, child: Text('Floor 1')),
                DropdownMenuItem<int>(value: 2, child: Text('Floor 2')),
                DropdownMenuItem<int>(value: 3, child: Text('Floor 3')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFloor = value;
                  });
                }
              },
            ),

            const SizedBox(height: 30),
            
            if(selectedFloor == 1)
              FirstFloorMapScreen(),
              
            if(selectedFloor == 2)
              SecondFloorMapScreen(),

            if(selectedFloor == 3)
              ThirdFloorMapScreen(),
          ]
        ),
      ),
    );
  }
}
