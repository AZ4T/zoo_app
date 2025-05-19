import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../providers/theme_provider.dart';
import '../providers/animal_provider.dart';
import '../providers/locale_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final animalProvider = context.read<AnimalProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dark Mode Switch
            SwitchListTile(
              title: Text('settings.dark_mode'.tr()),
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),

            const SizedBox(height: 24),

            // Accent Color Picker
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'settings.accent_color'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: themeProvider.colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final isSelected = themeProvider.colorIndex == i;
                  return GestureDetector(
                    onTap: () => themeProvider.changeColor(i),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: themeProvider.colors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Language Selector
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('settings.language'.tr()),
              trailing: DropdownButton<Locale>(
                value: localeProvider.currentLocale,
                underline: const SizedBox(),
                items: localeProvider.supportedLocales.map((loc) {
                  final code = loc.languageCode.toUpperCase();
                  final flag = loc.languageCode == 'en'
                      ? '🇺🇸'
                      : loc.languageCode == 'ru'
                          ? '🇷🇺'
                          : '🇰🇿';
                  return DropdownMenuItem(
                    value: loc,
                    child: Row(
                      children: [
                        Text(flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(code),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newLocale) {
                  if (newLocale != null) {
                    localeProvider.setLocale(newLocale);
                    context.setLocale(newLocale);
                  }
                },
              ),
            ),

            const Spacer(),

            // Reset All Animal Data Button
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: _isClearing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('settings.reset_button'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _isClearing ? null : _confirmAndClearAll,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('settings.reset_confirm_title'.tr()),
        content: Text('settings.reset_confirm_text'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('settings.cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('settings.reset_action'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClearing = true);
    try {
      await context.read<AnimalProvider>().clearAllAnimals();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings.reset_success'.tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('settings.reset_failure'.tr(namedArgs: {'error': e.toString()})),
        ),
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }
}
