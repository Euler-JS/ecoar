import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../../core/utils/logger.dart';

class ARGestureDetector extends StatefulWidget {
  final Widget child;
  final Function(Offset position)? onTap;
  final Function(Offset position)? onLongPress;
  final Function(double scale)? onPinch;
  final Function(Offset delta)? onPan;
  final Function(double rotation)? onRotate;

  const ARGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onPinch,
    this.onPan,
    this.onRotate,
  });

  @override
  State<ARGestureDetector> createState() => _ARGestureDetectorState();
}

class _ARGestureDetectorState extends State<ARGestureDetector> {
  double _lastScale = 1.0;
  double _lastRotation = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          // Get tap position relative to widget
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPosition = renderBox.globalToLocal(Offset.zero);
            widget.onTap!(localPosition);
          }
        }
      },
      onLongPress: () {
        if (widget.onLongPress != null) {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPosition = renderBox.globalToLocal(Offset.zero);
            widget.onLongPress!(localPosition);
          }
        }
      },
      onPanUpdate: (details) {
        widget.onPan?.call(details.delta);
      },
      onScaleStart: (details) {
        _lastScale = 1.0;
        _lastRotation = 0.0;
      },
      onScaleUpdate: (details) {
        // Handle pinch gesture
        if (widget.onPinch != null && details.scale != _lastScale) {
          widget.onPinch!(details.scale);
          _lastScale = details.scale;
        }

        // Handle rotation gesture
        if (widget.onRotate != null && details.rotation != _lastRotation) {
          widget.onRotate!(details.rotation);
          _lastRotation = details.rotation;
        }
      },
      child: widget.child,
    );
  }
}
