import 'package:flutter/material.dart';

mixin LoadingIndicatorProvider {
  Widget getLoadingIndicator() =>
      const Center(child: CircularProgressIndicator());
}
