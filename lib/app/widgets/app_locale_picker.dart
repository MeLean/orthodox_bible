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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: supportedLocales.map((curLocale) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                key: ValueKey(curLocale),
                onTap: () => localePickedCallback(curLocale),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.0,
                    ),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 40,
                    child: Image.asset(
                      'assets/flags/$curLocale.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 120,
                  child: SelectableText(
                    _getTranslatedText(curLocale),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getTranslatedText(String curLocale) {
    switch (curLocale) {
      case "bg":
        return "Чети на Български";
      case "ka":
        return "წაიკითხეთ ქართულად";
      default:
        return "Read in $curLocale";
    }
  }
}
