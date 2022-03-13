import 'package:flutter/material.dart';

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.disableAfterClick = const Duration(milliseconds: 500),
  }) : super(key: key);

  final Function onPressed;
  final Widget icon;
  final Duration disableAfterClick;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _acceptsClicks = true;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        if (_acceptsClicks) {
          _acceptsClicks = false;
          widget.onPressed();
          Future.delayed(widget.disableAfterClick, () {
            if (mounted) {
              _acceptsClicks = true;
            }
          });
        }
      },
      icon: widget.icon,
    );
  }
}
