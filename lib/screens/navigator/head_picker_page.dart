import 'package:flutter/material.dart';

class HeadPickerPage extends StatelessWidget {
  final String bookTitle;
  final int headsCount;

  const HeadPickerPage({
    Key? key,
    required this.bookTitle,
    required this.headsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          bookTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false, // AppBar already handles the top inset
        child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 12, right: 12, bottom: 12),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: headsCount,
            itemBuilder: (context, index) {
              final head = index + 1;
              return _HeadTile(
                head: head,
                onTap: () => Navigator.pop(context, head),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeadTile extends StatelessWidget {
  final int head;
  final VoidCallback onTap;

  const _HeadTile({
    Key? key,
    required this.head,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Text(
            '$head',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
