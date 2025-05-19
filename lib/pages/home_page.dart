import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

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
  String _sortBy = 'Name ↑';
  bool _showItems = false;
  bool _isApiLoading = false;

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
    final filtered = allAnimals.where((a) {
      return a.name.toLowerCase().contains(term) ||
             a.breed.toLowerCase().contains(term);
    }).toList()
      // Then sort
      ..sort((a, b) {
        switch (_sortBy) {
          case 'Name ↓':  return b.name.compareTo(a.name);
          case 'Price ↑': return a.price.compareTo(b.price);
          case 'Price ↓': return b.price.compareTo(a.price);
          default:         return a.name.compareTo(b.name);
        }
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Animals for Sale')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search Bar ───────────────────────
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search by name or breed',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 12),

            // ── Sort Dropdown ────────────────────
            DropdownButton<String>(
              value: _sortBy,
              items: const ['Name ↑', 'Name ↓', 'Price ↑', 'Price ↓']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
                    // Use the same hero tag you’ll use in DetailsPage
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
                                          errorBuilder: (_,__,___) =>
                                              const Icon(Icons.broken_image),
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

            // ── Empty State ──────────────────────
            if (filtered.isEmpty)
              const Expanded(
                child: Center(child: Text('No animals found.')),
              )
            else
              // ── Staggered List/Grid ─────────────
              Expanded(child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 600;

                  Widget animatedItem(int idx) {
                    final animal = filtered[idx];
                    // Find the “true” index in the full list so deletes/edits work
                    final trueIndex = allAnimals.indexOf(animal);

                    return AnimatedSlide(
                      offset:
                          _showItems ? Offset.zero : const Offset(0, 0.1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: AnimatedOpacity(
                        opacity: _showItems ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: AnimalTile(
                          animal: animal,
                          index: trueIndex,
                        ),
                      ),
                    );
                  }

                  return isWide
                      ? GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, idx) => FutureBuilder(
                              future: Future.delayed(
                                  Duration(milliseconds: idx * 100)),
                              builder: (_, __) => animatedItem(idx)),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, idx) => FutureBuilder(
                              future: Future.delayed(
                                  Duration(milliseconds: idx * 100)),
                              builder: (_, __) => animatedItem(idx)),
                        );
                },
              )),
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
            tooltip: 'Add Manually',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          // API add
          FloatingActionButton(
            heroTag: 'api_add',
            onPressed: _isApiLoading ? null : () async {
              setState(() => _isApiLoading = true);
              try {
                await provider.addAnimalFromApi('cat');
              } catch (e) {
                debugPrint('API add error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Couldn’t add from API: $e')),
                );
              } finally {
                if (mounted) setState(() => _isApiLoading = false);
              }
            },
            tooltip: 'Add from API',
            child: const Icon(Icons.image),
          ),
        ],
      ),

      // ── API Loading Overlay ──────────────
      // (blocks taps under the FABs too)
      persistentFooterButtons: _isApiLoading
          ? [
              ModalBarrier(color: Colors.black38, dismissible: false),
              Center(
                child: SizedBox(
                  height: 100,
                  child: Lottie.asset('animations/loading.json'),
                ),
              )
            ]
          : null,
    );
  }

  void _openDetails(BuildContext context, Animal animal) {
    final provider = context.read<AnimalProvider>();
    provider.selectAnimal(animal);
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const DetailsPage(),
      transitionsBuilder: (_, anim, __, child) {
        final offset =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(anim);
        return SlideTransition(position: offset, child: child);
      },
    ));
  }
}
