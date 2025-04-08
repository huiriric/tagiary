import 'package:flutter/material.dart';

class SlideUpContainer extends StatefulWidget {
  Widget child;
  SlideUpContainer({super.key, required this.child});

  @override
  State<SlideUpContainer> createState() => _SlideContainerState();
}

class _SlideContainerState extends State<SlideUpContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: widget.child,
    );
  }
}
