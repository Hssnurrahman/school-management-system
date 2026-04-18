import 'package:flutter/material.dart';

class LegendItem extends StatelessWidget {
  const LegendItem({
    super.key,
    required this.color,
    required this.label,
    this.value,
    this.useCircle = false,
  });

  final Color color;
  final String label;
  final String? value;
  final bool useCircle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: useCircle ? null : BorderRadius.circular(2),
            shape: useCircle ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value != null ? '$label: $value' : label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
