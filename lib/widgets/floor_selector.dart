import 'package:flutter/material.dart';

class FloorSelector extends StatelessWidget {
  const FloorSelector({
    super.key,
    required this.selectedFloor,
    required this.onChanged,
  });

  final int selectedFloor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 1, label: Text('1st floor')),
        ButtonSegment(value: 2, label: Text('2nd floor')),
        ButtonSegment(value: 3, label: Text('3rd floor')),
      ],
      selected: {selectedFloor},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}