import 'package:flutter/physics.dart';

abstract class AppAnimations {
  static const springSnappy =
      SpringDescription(mass: 1.0, stiffness: 300, damping: 25);
  static const springDefault =
      SpringDescription(mass: 1.0, stiffness: 200, damping: 22);
  static const springBouncy =
      SpringDescription(mass: 1.0, stiffness: 180, damping: 14);
  static const springSlide =
      SpringDescription(mass: 1.0, stiffness: 250, damping: 28);

  static const pageTransition = Duration(milliseconds: 320);
  static const cardEntrance = Duration(milliseconds: 380);
  static const sidebarSlide = Duration(milliseconds: 280);
}
