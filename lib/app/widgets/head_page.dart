import 'package:flutter/material.dart';

class HeadPage extends StatelessWidget {
  const HeadPage({
    Key? key,
    required this.text,
    required double custFontSize,
    ScrollController? scrollControler,
  })  : _custFontSize = custFontSize,
        super(key: key);

  final String? text;
  final double _custFontSize;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      radius: const Radius.circular(16.0),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: SelectableText(
                  text ?? '',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: _custFontSize),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
