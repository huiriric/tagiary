import 'package:flutter/material.dart';

class SlideUpContainer extends StatefulWidget {
  final double? width;
  final Widget child;
  const SlideUpContainer({super.key, this.width, required this.child});

  @override
  State<SlideUpContainer> createState() => _SlideContainerState();
}

class _SlideContainerState extends State<SlideUpContainer> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Container(
            width: widget.width ?? double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom - 60,
            ),
            child: SingleChildScrollView(child: widget.child),
          ),
        ),
      ),
    );
  }
}
