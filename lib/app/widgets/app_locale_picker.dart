import 'package:flutter/material.dart';

class AppLocalePicker extends StatelessWidget {
  final List<String> supportedLocales;
  final Function(String) localePickedCallback;

  const AppLocalePicker({
    Key? key,
    required this.supportedLocales,
    required this.localePickedCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: supportedLocales.map((curLocale) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 80,
            maxWidth: 120,
          ),
          child: _LocaleTile(
            locale: curLocale,
            onTap: () => localePickedCallback(curLocale),
          ),
        );
      }).toList(),
    );
  }
}

class _LocaleTile extends StatelessWidget {
  final String locale;
  final VoidCallback onTap;

  const _LocaleTile({required this.locale, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Flag size responsive to tile width, but with min values
        final flagW = (c.maxWidth * 0.6).clamp(80.0, 100.0);
        final flagH = flagW * 0.5;

        return InkWell(
          key: ValueKey(locale),
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4.0), // some breathing space
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SizedBox(
                    width: flagW,
                    height: flagH,
                    child: Image.asset(
                      'assets/flags/$locale.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _getTranslatedText(locale),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _getTranslatedText(String locale) {
  switch (locale) {
    case "bg":
      return "Български";
    case "ka":
      return "ქართული";
    case "ru":
      return "Русский";
    default:
      return locale.toUpperCase();
  }
}
