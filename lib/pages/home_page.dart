import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';

import '../models/animal.dart';
import '../providers/animal_provider.dart';
import '../widgets/animal_tile.dart';
import 'add_animal_page.dart';
import 'details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _sortBy = 'sort.name_asc';
  bool _showItems = false;
  bool _isApiLoading = false;

  // these keys match your JSON keys:
  final _sortOptions = const [
    'sort.name_asc',
    'sort.name_desc',
    'sort.price_asc',
    'sort.price_desc',
  ];

  @override
  void initState() {
    super.initState();
    // Trigger the staggered entrance animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _showItems = true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the animal list
    final provider = context.watch<AnimalProvider>();
    final allAnimals = provider.animals;
    final term = _searchCtrl.text.toLowerCase();

    // Filter by name or breed
    final filtered = allAnimals
        .where((a) =>
            a.name.toLowerCase().contains(term) ||
            a.breed.toLowerCase().contains(term))
        .toList()
      ..sort((a, b) {
        switch (_sortBy) {
          case 'sort.name_desc':
            return b.name.compareTo(a.name);
          case 'sort.price_asc':
            return a.price.compareTo(b.price);
          case 'sort.price_desc':
            return b.price.compareTo(a.price);
          default: // 'sort.name_asc'
            return a.name.compareTo(b.name);
        }
      });

    Widget animatedItem(int idx) {
      return AnimatedSlide(
        offset: _showItems ? Offset.zero : const Offset(0, .1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _showItems ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: AnimalTile(animal: filtered[idx], index: idx),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('home.title'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search Bar ───────────────────────
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'home.search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 12),

            // ── Sort Dropdown ────────────────────
            DropdownButton<String>(
              value: _sortBy,
              items: _sortOptions
                  .map((key) => DropdownMenuItem(
                        value: key,
                        child: Text(key.tr()),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _sortBy = v!),
              isExpanded: true,
            ),

            const SizedBox(height: 16),

            // ── Horizontal Gallery ───────────────
            if (filtered.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final animal = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _openDetails(context, animal),
                        child: Hero(
                          tag: 'animal-${animal.key}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: animal.imageBase64 != null
                                  ? Image.memory(
                                      base64Decode(animal.imageBase64!),
                                      fit: BoxFit.cover,
                                    )
                                  : (animal.imageUrl.isNotEmpty
                                      ? Image.network(
                                          animal.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => const Icon(
                                            Icons.broken_image,
                                          ),
                                        )
                                      : const Icon(Icons.pets, size: 48)),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Animated Empty State ──────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutBack,
                child: filtered.isEmpty
                    // this Column is the “empty” state
                    ? Column(
                        key: const ValueKey('empty'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // bounce‐in icon
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: const Icon(
                              Icons.pets,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // fade‐in text
                          Text(
                            'home.empty_message'.tr(),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      )
                    // when you have items, swap in the real list/grid
                    : Padding(
                        key: const ValueKey('list'),
                        padding: const EdgeInsets.only(top: 8),
                        child: LayoutBuilder(
                          builder: (_, constraints) {
                            final isWide = constraints.maxWidth > 600;
                            if (isWide) {
                              return GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, idx) => animatedItem(idx),
                              );
                            } else {
                              return ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, idx) => animatedItem(idx),
                              );
                            }
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),

      // ── FABs ──────────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Manual add
          FloatingActionButton(
            heroTag: 'manual_add',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAnimalPage()),
            ),
            tooltip: 'home.tooltip_add_manual'.tr(),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          // API add
          FloatingActionButton(
            heroTag: 'api_add',
            onPressed: _isApiLoading
                ? null
                : () async {
                    setState(() => _isApiLoading = true);
                    try {
                      await provider.addAnimalFromApi('cat');
                    } catch (e) {
                      debugPrint('API add error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('home.snackbar_api_error'.tr(
                            namedArgs: {'error': e.toString()},
                          )),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isApiLoading = false);
                    }
                  },
            tooltip: 'home.tooltip_add_api'.tr(),
            child: const Icon(Icons.image),
          ),
        ],
      ),

      // ── API Loading Overlay ──────────────
      persistentFooterButtons: _isApiLoading
          ? [
              ModalBarrier(color: Colors.black38, dismissible: false),
              Center(
                child: SizedBox(
                  height: 100,
                  child: Lottie.asset('animations/loading.json'),
                ),
              ),
            ]
          : null,
    );
  }

  void _openDetails(BuildContext context, Animal animal) {
    final provider = context.read<AnimalProvider>();
    provider.selectAnimal(animal);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DetailsPage(),
        transitionsBuilder: (_, anim, __, child) {
          final offset = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim);
          return SlideTransition(position: offset, child: child);
        },
      ),
    );
  }
}
