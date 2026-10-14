import 'package:flutter/material.dart';

/// Company attribution using the existing AuxiumSoft monogram asset.
class AuxiumSoftBrand extends StatelessWidget {
  const AuxiumSoftBrand({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'An AuxiumSoft product',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'An AuxiumSoft product',
          style: TextStyle(color: Color(0xff64748b), fontSize: 13),
        ),
        const SizedBox(height: 10),
        Image.asset(
          'assets/images/logo.png',
          width: 52,
          height: 52,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          cacheWidth: 208,
        ),
        const SizedBox(height: 8),
        const Text(
          'AuxiumSoft',
          style: TextStyle(
            color: Color(0xff4338ca),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    ),
  );
}
