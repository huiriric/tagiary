import 'package:flutter/material.dart';

class SlideUpContainer extends StatefulWidget {
  double? height;
  Widget child;
  SlideUpContainer({super.key, this.height, required this.child});

  @override
  State<SlideUpContainer> createState() => _SlideContainerState();
}

class _SlideContainerState extends State<SlideUpContainer> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: widget.height,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
