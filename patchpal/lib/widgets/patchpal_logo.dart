import 'package:flutter/material.dart';

class PatchPalLogo extends StatelessWidget {
  final double size;
  
  const PatchPalLogo({
    Key? key,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: size / 4,
            top: 0,
            child: Container(
              width: size / 2,
              height: size / 2,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade200,
                borderRadius: BorderRadius.circular(size / 15),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: size / 4,
            child: Container(
              width: size / 2,
              height: size / 2,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade300,
                borderRadius: BorderRadius.circular(size / 15),
              ),
            ),
          ),
          Positioned(
            left: size / 4,
            top: size / 2,
            child: Container(
              width: size / 2,
              height: size / 2,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade400,
                borderRadius: BorderRadius.circular(size / 15),
              ),
            ),
          ),
          Positioned(
            left: size / 2,
            top: size / 4,
            child: Container(
              width: size / 2,
              height: size / 2,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade200,
                borderRadius: BorderRadius.circular(size / 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}