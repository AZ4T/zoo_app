import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/animal_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    // Rebuild when theme changes
    final themeProvider = context.watch<ThemeProvider>();
    // Read-only for animal operations
    final animalProvider = context.read<AnimalProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dark mode toggle with error safety
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: themeProvider.isDark,
              onChanged: (_) async {
                try {
                  await themeProvider.toggleTheme();
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select App Theme Color:",
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),

            // Theme color picker
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: themeProvider.colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final color = themeProvider.colors[index];
                  final isSelected = themeProvider.colorIndex == index;
                  return GestureDetector(
                    onTap: () {
                      try {
                        themeProvider.changeColor(index);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Couldn’t change color: $e')),
                        );
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
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

            const Spacer(),

            // Reset button with confirmation & loading state
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label:
                  _isClearing
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text("Reset All Animal Data"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed:
                  _isClearing
                      ? null
                      : () async {
                        // 1) Confirm
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text('Confirm Data Reset'),
                                content: const Text(
                                  'This will permanently delete all animal records. Continue?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed:
                                        () => Navigator.of(ctx).pop(true),
                                    child: const Text('RESET'),
                                  ),
                                ],
                              ),
                        );

                        if (confirmed != true) return;

                        // 2) Clear
                        setState(() => _isClearing = true);
                        try {
                          await animalProvider.clearAllAnimals();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("All animal data has been reset."),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Failed to reset data: ${e.toString()}",
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _isClearing = false);
                        }
                      },
            ),
          ],
        ),
      ),
    );
  }
}
