import 'package:flutter/material.dart';

/// Displays the supplied wordmark, trimming only its surrounding whitespace.
class ArivoraLogo extends StatelessWidget {
  final double height;
  const ArivoraLogo({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Arivora logo',
    image: true,
    child: SizedBox(
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: ClipRect(
          child: Align(
            widthFactor: 0.66,
            heightFactor: 0.60,
            child: Image.asset(
              'assets/images/arivora_brand.jpg',
              width: 400,
              height: 400,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    ),
  );
}
