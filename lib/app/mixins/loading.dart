import 'package:flutter/material.dart';

mixin LoadingIndicatorProvider {
  Widget provideLoadingIndicator(BuildContext context) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      );
}
