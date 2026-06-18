import 'package:flutter/material.dart';

/// Parses backend HTML service descriptions into displayable bullet points.
class ServiceDescriptionDisplay {
  ServiceDescriptionDisplay._();

  static List<String> parsePoints(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const <String>[];

    final liMatches = RegExp(
      r'<li[^>]*>(.*?)</li>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(trimmed);
    if (liMatches.isNotEmpty) {
      return liMatches
          .map((match) => _cleanText(match.group(1) ?? ''))
          .where((point) => point.isNotEmpty)
          .toList();
    }

    final withoutTags = trimmed
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'&amp;', caseSensitive: false), '&')
        .replaceAll(RegExp(r'&lt;', caseSensitive: false), '<')
        .replaceAll(RegExp(r'&gt;', caseSensitive: false), '>');

    return withoutTags
        .split(RegExp(r'[\n\r]+'))
        .map(_cleanText)
        .where((point) => point.isNotEmpty)
        .toList();
  }

  static String plainText(String raw) {
    final points = parsePoints(raw);
    if (points.isNotEmpty) {
      return points.join(' ');
    }
    return _cleanText(raw);
  }

  static String includedServicesLabel(String raw) {
    final count = parsePoints(raw).length;
    if (count == 0) return 'View package details';
    if (count == 1) return '1 service included';
    return '$count services included';
  }

  static Widget buildPointList(
    String raw, {
    TextStyle? style,
    EdgeInsetsGeometry pointPadding = const EdgeInsets.only(bottom: 6),
  }) {
    final points = parsePoints(raw);
    final textStyle = style ??
        const TextStyle(
          color: Color(0xFF000000),
          fontSize: 18,
          fontWeight: FontWeight.w300,
          height: 1.35,
        );

    if (points.isEmpty) {
      final fallback = _cleanText(raw);
      if (fallback.isEmpty) return const SizedBox.shrink();
      return Text(fallback, style: textStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map(
            (point) => Padding(
              padding: pointPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('• ', style: textStyle),
                  Expanded(child: Text(point, style: textStyle)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  static String _cleanText(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'&amp;', caseSensitive: false), '&')
        .replaceAll(RegExp(r'&lt;', caseSensitive: false), '<')
        .replaceAll(RegExp(r'&gt;', caseSensitive: false), '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
