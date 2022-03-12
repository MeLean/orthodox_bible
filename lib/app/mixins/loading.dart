import 'package:flutter/material.dart';

mixin LoadingIndicatorProvider {
  Widget provideLoadingIndicator() =>
      const Center(child: CircularProgressIndicator());
}
