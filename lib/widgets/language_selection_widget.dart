import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/localization_service.dart';

class LanguageSelectionWidget extends StatelessWidget {
  const LanguageSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(LocalizationService.getLanguage(context)),
      subtitle: Text(languageProvider.getCurrentLanguageDisplayName()),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showLanguageSelector(context),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.getSelectLanguage(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LanguageProvider.supportedLanguages.entries.map((entry) {
            final languageCode = entry.key;
            final languageName = entry.value;
            final isSelected = languageProvider.currentLanguageCode == languageCode;

            return RadioListTile<String>(
              title: Text(
                languageName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              value: languageCode,
              groupValue: languageProvider.currentLanguageCode,
              onChanged: (value) {
                if (value != null) {
                  languageProvider.changeLanguage(value);
                  Navigator.of(context).pop();
                }
              },
              dense: true,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocalizationService.getCancel(context)),
          ),
        ],
      ),
    );
  }
}

class LanguageBottomSheet extends StatelessWidget {
  const LanguageBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              LocalizationService.getSelectLanguage(context),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...LanguageProvider.supportedLanguages.entries.map((entry) {
            final languageCode = entry.key;
            final languageName = entry.value;
            final isSelected = languageProvider.currentLanguageCode == languageCode;

            return ListTile(
              title: Text(
                languageName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
              onTap: () {
                languageProvider.changeLanguage(languageCode);
                Navigator.of(context).pop();
              },
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const LanguageBottomSheet(),
    );
  }
}