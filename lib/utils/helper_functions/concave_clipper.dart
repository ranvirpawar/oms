import 'package:flutter/cupertino.dart';

class ConcaveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    // Starting point (top-left)
    path.lineTo(0, size.height - 20);

    // Create the concave curve
    path.quadraticBezierTo(
      size.width / 2, // control point x
      size.height + 20, // control point y (below the bottom to create concave)
      size.width, // end point x
      size.height - 20, // end point y
    );

    // Finish the shape
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom clipper for convex bottom border
class ConvexBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top-left
    path.moveTo(0, 0);

    // Draw top side
    path.lineTo(size.width, 0);

    // Draw right side down to near the bottom
    path.lineTo(size.width, size.height - 20);

    // Draw the convex bottom curve
    path.quadraticBezierTo(
      size.width / 2, // control point x
      size.height - 40, // control point y (moved upward to create convex curve)
      0, // end point x
      size.height - 20, // end point y
    );

    // Close the path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}