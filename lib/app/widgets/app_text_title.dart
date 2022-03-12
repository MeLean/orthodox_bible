import 'package:flutter/material.dart';

class TextTitle extends StatelessWidget {
  const TextTitle({
    Key? key,
    required String text,
    required double custFontSize,
  })  : _text = text,
        _custFontSize = custFontSize,
        super(key: key);

  final String _text;
  final double _custFontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity,
        child: SelectableText(
          _text,
          textAlign: TextAlign.start,
          style: TextStyle(fontSize: _custFontSize),
        ),
      ),
    );
  }
}
