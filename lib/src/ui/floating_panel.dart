import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../devlens.dart';
import '../config/devlens_config.dart';

/// Floating panel that follows the cursor and shows network data
class DevLensFloatingPanel extends StatefulWidget {
  final Offset position;
  final SmartDetectionResult detectionResult;
  final String? detectedText;
  final DevLensTheme theme;

  const DevLensFloatingPanel({
    super.key,
    required this.position,
    required this.detectionResult,
    this.detectedText,
    required this.theme,
  });

  @override
  State<DevLensFloatingPanel> createState() => _DevLensFloatingPanelState();
}

class _DevLensFloatingPanelState extends State<DevLensFloatingPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _selectedTab = 0; // 0: Response, 1: Request, 2: Headers

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final panelWidth = 420.0;
    final panelHeight = 380.0;

    // Position panel to the right of cursor, with smart repositioning
    double left = widget.position.dx + 20;
    double top = widget.position.dy + 10;

    // Adjust if panel would go off screen
    if (left + panelWidth > screenSize.width - 20) {
      left = widget.position.dx - panelWidth - 20;
    }
    if (top + panelHeight > screenSize.height - 20) {
      top = screenSize.height - panelHeight - 20;
    }
    if (left < 20) left = 20;
    if (top < 20) top = 20;

    return Positioned(
      left: left,
      top: top,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: panelWidth,
            height: panelHeight,
            decoration: BoxDecoration(
              color: widget.theme.panelBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.theme.border, width: 1),
              boxShadow: widget.theme.shadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTabs(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final record = widget.detectionResult.record;
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.headerBackground,
        border: Border(bottom: BorderSide(color: theme.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Method + Status + Time row
          Row(
            children: [
              _buildMethodBadge(record.method),
              const SizedBox(width: 8),
              if (record.statusCode != null) ...[
                _buildStatusBadge(record.statusCode!),
                const SizedBox(width: 8),
              ],
              Text(
                record.formattedDuration,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Match indicator
              if (widget.detectionResult.matchType == MatchType.exact)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: theme.success),
                      const SizedBox(width: 4),
                      Text(
                        'MATCHED',
                        style: TextStyle(
                          color: theme.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // URL
          Text(
            record.url.toString(),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Matched field info
          if (widget.detectionResult.matchedPath != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.highlightColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.highlightBorder.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 12, color: theme.highlightBorder),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.detectionResult.matchedPath!,
                      style: TextStyle(
                        color: theme.highlightBorder,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodBadge(String method) {
    Color color;
    switch (method.toUpperCase()) {
      case 'GET':
        color = widget.theme.success;
        break;
      case 'POST':
        color = widget.theme.accent;
        break;
      case 'PUT':
        color = widget.theme.warning;
        break;
      case 'DELETE':
        color = widget.theme.error;
        break;
      default:
        color = widget.theme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int statusCode) {
    final theme = widget.theme;
    Color color;
    if (statusCode >= 200 && statusCode < 300) {
      color = theme.success;
    } else if (statusCode >= 300 && statusCode < 400) {
      color = theme.warning;
    } else {
      color = theme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$statusCode',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final theme = widget.theme;
    final tabs = ['Response', 'Request', 'Headers'];

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.headerBackground,
        border: Border(bottom: BorderSide(color: theme.border, width: 1)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? theme.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected ? theme.accent : theme.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildJsonView(widget.detectionResult.record.responseBody);
      case 1:
        return _buildJsonView(widget.detectionResult.record.requestBody);
      case 2:
        return _buildHeadersView();
      default:
        return const SizedBox();
    }
  }

  Widget _buildJsonView(dynamic data) {
    if (data == null) {
      return Center(
        child: Text(
          'No data',
          style: TextStyle(
            color: widget.theme.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: _JsonSyntaxHighlighter(
        data: data,
        theme: widget.theme,
        highlightPath: widget.detectionResult.matchedPath,
      ),
    );
  }

  Widget _buildHeadersView() {
    final record = widget.detectionResult.record;
    final theme = widget.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Headers',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...record.requestHeaders.entries.map((e) => _buildHeaderRow(e.key, e.value.toString())),
          const SizedBox(height: 16),
          Text(
            'Response Headers',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (record.responseHeaders.isEmpty)
            Text('None', style: TextStyle(color: theme.textMuted, fontStyle: FontStyle.italic))
          else
            ...record.responseHeaders.entries.map((e) => _buildHeaderRow(e.key, e.value.toString())),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(String key, String value) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$key: ',
              style: TextStyle(
                color: theme.jsonKey,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// JSON syntax highlighter with path highlighting
class _JsonSyntaxHighlighter extends StatelessWidget {
  final dynamic data;
  final DevLensTheme theme;
  final String? highlightPath;

  const _JsonSyntaxHighlighter({
    required this.data,
    required this.theme,
    this.highlightPath,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(children: _buildSpans(data, '', 0)),
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.5,
      ),
    );
  }

  List<InlineSpan> _buildSpans(dynamic value, String path, int indent) {
    final spans = <InlineSpan>[];
    final indentStr = '  ' * indent;

    if (value == null) {
      spans.add(_styledSpan('null', theme.jsonNull, path));
    } else if (value is bool) {
      spans.add(_styledSpan(value.toString(), theme.jsonBoolean, path));
    } else if (value is num) {
      spans.add(_styledSpan(value.toString(), theme.jsonNumber, path));
    } else if (value is String) {
      final displayValue = '"${_escapeString(value)}"';
      spans.add(_styledSpan(displayValue, theme.jsonString, path));
    } else if (value is List) {
      if (value.isEmpty) {
        spans.add(_styledSpan('[]', theme.textPrimary, path));
      } else {
        spans.add(TextSpan(text: '[\n', style: TextStyle(color: theme.textPrimary)));
        for (int i = 0; i < value.length; i++) {
          final itemPath = '$path[$i]';
          spans.add(TextSpan(text: '$indentStr  ', style: TextStyle(color: theme.textPrimary)));
          spans.addAll(_buildSpans(value[i], itemPath, indent + 1));
          if (i < value.length - 1) {
            spans.add(TextSpan(text: ',', style: TextStyle(color: theme.textPrimary)));
          }
          spans.add(TextSpan(text: '\n', style: TextStyle(color: theme.textPrimary)));
        }
        spans.add(TextSpan(text: '$indentStr]', style: TextStyle(color: theme.textPrimary)));
      }
    } else if (value is Map) {
      if (value.isEmpty) {
        spans.add(_styledSpan('{}', theme.textPrimary, path));
      } else {
        spans.add(TextSpan(text: '{\n', style: TextStyle(color: theme.textPrimary)));
        final entries = value.entries.toList();
        for (int i = 0; i < entries.length; i++) {
          final entry = entries[i];
          final keyPath = path.isEmpty ? entry.key.toString() : '$path.${entry.key}';

          spans.add(TextSpan(text: '$indentStr  ', style: TextStyle(color: theme.textPrimary)));
          spans.add(_styledSpan('"${entry.key}"', theme.jsonKey, keyPath, isKey: true));
          spans.add(TextSpan(text: ': ', style: TextStyle(color: theme.textPrimary)));
          spans.addAll(_buildSpans(entry.value, keyPath, indent + 1));
          if (i < entries.length - 1) {
            spans.add(TextSpan(text: ',', style: TextStyle(color: theme.textPrimary)));
          }
          spans.add(TextSpan(text: '\n', style: TextStyle(color: theme.textPrimary)));
        }
        spans.add(TextSpan(text: '$indentStr}', style: TextStyle(color: theme.textPrimary)));
      }
    } else {
      spans.add(_styledSpan(value.toString(), theme.textPrimary, path));
    }

    return spans;
  }

  InlineSpan _styledSpan(String text, Color color, String path, {bool isKey = false}) {
    final isHighlighted = highlightPath != null && path == highlightPath;

    if (isHighlighted) {
      return WidgetSpan(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: theme.highlightColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: theme.highlightBorder, width: 1.5),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return TextSpan(
      text: text,
      style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12),
    );
  }

  String _escapeString(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}