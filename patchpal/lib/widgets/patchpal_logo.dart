import 'package:flutter/material.dart';

class PatchPalLogo extends StatelessWidget {
  final double size;

  const PatchPalLogo({
    Key? key,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/patchpal_logo.png', // Make sure this path matches your actual image location
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
