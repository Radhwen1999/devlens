import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'devlens.dart';
import 'config/devlens_config.dart';
import 'ui/floating_panel.dart';

/// The main DevLens overlay widget
/// 
/// Wrap your app with this to enable wheel-click inspection:
/// ```dart
/// runApp(DevLensOverlay(child: MyApp()));
/// ```
class DevLensOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final DevLensConfig config;

  const DevLensOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.config = const DevLensConfig(),
  });

  @override
  State<DevLensOverlay> createState() => _DevLensOverlayState();
}

class _DevLensOverlayState extends State<DevLensOverlay> {
  bool _isInspecting = false;
  Offset _cursorPosition = Offset.zero;
  String? _detectedText;
  SmartDetectionResult? _detectionResult;

  // For element detection
  Element? _hoveredElement;
  RenderObject? _hoveredRenderObject;
  Rect? _hoveredBounds;

  @override
  void initState() {
    super.initState();
    DevLens.init(config: widget.config);
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Middle mouse button
    if (event.buttons == kMiddleMouseButton) {
      setState(() {
        _isInspecting = true;
        _cursorPosition = event.position;
      });
      _detectWidgetAtPosition(event.position);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isInspecting) {
      setState(() {
        _isInspecting = false;
        _detectedText = null;
        _detectionResult = null;
        _hoveredElement = null;
        _hoveredRenderObject = null;
        _hoveredBounds = null;
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isInspecting) {
      setState(() {
        _cursorPosition = event.position;
      });
      _detectWidgetAtPosition(event.position);
    }
  }

  void _handlePointerHover(PointerHoverEvent event) {
    if (_isInspecting) {
      setState(() {
        _cursorPosition = event.position;
      });
      _detectWidgetAtPosition(event.position);
    }
  }

  /// Detect widget and extract text at the given position
  void _detectWidgetAtPosition(Offset position) {
    final renderObject = _findRenderObjectAtPosition(position);
    if (renderObject == null) return;

    String? extractedText;
    Rect? bounds;

    // Get the bounds of the render object
    if (renderObject is RenderBox) {
      final transform = renderObject.getTransformTo(null);
      final size = renderObject.size;
      final topLeft = MatrixUtils.transformPoint(transform, Offset.zero);
      bounds = Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height);
    }

    // Try to extract text from the render object
    extractedText = _extractTextFromRenderObject(renderObject);

    // If we found text, do smart detection
    SmartDetectionResult? result;
    if (extractedText != null && extractedText.isNotEmpty) {
      result = DevLens.instance.detectDataForValue(extractedText);
    } else if (DevLens.instance.latestRecord != null) {
      // No text found, show latest record
      result = SmartDetectionResult(
        record: DevLens.instance.latestRecord!,
        matchedPath: null,
        matchedValue: null,
        matchType: MatchType.none,
      );
    }

    setState(() {
      _hoveredRenderObject = renderObject;
      _hoveredBounds = bounds;
      _detectedText = extractedText;
      _detectionResult = result;
    });
  }

  /// Find the render object at the given position
  RenderObject? _findRenderObjectAtPosition(Offset position) {
    final renderObject = context.findRenderObject();
    if (renderObject == null) return null;

    RenderObject? result;

    void hitTest(RenderObject object) {
      if (object is RenderBox) {
        final transform = object.getTransformTo(null);
        final localPosition = MatrixUtils.transformPoint(
          Matrix4.tryInvert(transform) ?? Matrix4.identity(),
          position,
        );

        if (object.size.contains(localPosition)) {
          result = object;
        }
      }

      object.visitChildren(hitTest);
    }

    hitTest(renderObject);
    return result;
  }

  /// Extract text from a render object
  String? _extractTextFromRenderObject(RenderObject renderObject) {
    // Try to find text in the render object tree
    String? text;

    void findText(RenderObject object) {
      if (object is RenderParagraph) {
        text = object.text.toPlainText();
      }
      object.visitChildren(findText);
    }

    findText(renderObject);
    return text;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerMove: _handlePointerMove,
      onPointerHover: _handlePointerHover,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          widget.child,

          // Highlight overlay for hovered element
          if (_isInspecting && _hoveredBounds != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HighlightPainter(
                    bounds: _hoveredBounds!,
                    color: widget.config.theme.accent,
                  ),
                ),
              ),
            ),

          // Floating panel
          if (_isInspecting && _detectionResult != null)
            DevLensFloatingPanel(
              position: _cursorPosition,
              detectionResult: _detectionResult!,
              detectedText: _detectedText,
              theme: widget.config.theme,
            ),
        ],
      ),
    );
  }
}

/// Painter for highlighting the hovered element
class _HighlightPainter extends CustomPainter {
  final Rect bounds;
  final Color color;

  _HighlightPainter({required this.bounds, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw semi-transparent overlay on everything except the hovered element
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.3);

    // Draw the darkened areas
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(bounds),
      ),
      overlayPaint,
    );

    // Draw highlight border around the element
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(bounds.inflate(1), borderPaint);

    // Draw subtle fill
    final fillPaint = Paint()..color = color.withOpacity(0.1);
    canvas.drawRect(bounds, fillPaint);
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) {
    return bounds != oldDelegate.bounds || color != oldDelegate.color;
  }
}