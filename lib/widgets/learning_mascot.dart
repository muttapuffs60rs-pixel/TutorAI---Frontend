import 'package:flutter/material.dart';

/// Decorative artwork stays out of screen-reader navigation.
class LearningMascot extends StatelessWidget {
  final double size;
  const LearningMascot({super.key, this.size = 100});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/images/learning_mascot.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    ),
  );
}
