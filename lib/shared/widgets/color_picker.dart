import 'package:flutter/material.dart';
import 'package:mrplando/core/constants/colors.dart';
import 'package:mrplando/features/settings/screens/color_management_page.dart';

class ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorChanged;
  final double padding;
  final double colorSize;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.padding = 20,
    this.colorSize = 35,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            '색상',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Wrap(
            spacing: (MediaQuery.of(context).size.width -
                    (padding * 4 + colorSize * 6)) /
                5,
            runSpacing: 12,
            children: [
              ...scheduleColors.map((color) {
                return GestureDetector(
                  onTap: () => onColorChanged(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: colorSize,
                    height: colorSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selectedColor == color
                          ? Border.all(color: Colors.black, width: 2.5)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha((255 * 0.3).toInt()),
                          blurRadius: selectedColor == color ? 8 : 6,
                          offset: Offset(0, selectedColor == color ? 3 : 2),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ColorManagementPage(),
                    ),
                  );
                },
                child: Container(
                  width: colorSize,
                  height: colorSize,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
