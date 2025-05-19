import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_cross_final/pages/add_animal_page.dart';
import 'package:project_cross_final/pages/details_page.dart';
import 'package:project_cross_final/providers/animal_provider.dart';
import 'package:project_cross_final/models/animal.dart';

class AnimalTile extends StatelessWidget {
  final Animal animal;
  final int index;

  const AnimalTile({
    Key? key,
    required this.animal,
    required this.index,
  }) : super(key: key);

  bool _isValidBase64(String b64) {
    try {
      return base64Decode(b64).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AnimalProvider>();

    // Build the thumbnail (memory → network → default)
    Widget imageWidget;
    if (animal.imageBase64 != null &&
        animal.imageBase64!.isNotEmpty &&
        _isValidBase64(animal.imageBase64!)) {
      imageWidget = Image.memory(
        base64Decode(animal.imageBase64!),
        fit: BoxFit.cover,
      );
    } else if (animal.imageUrl.isNotEmpty) {
      imageWidget = Image.network(
        animal.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, prog) {
          if (prog == null) return child;
          final total = prog.expectedTotalBytes;
          final loaded = prog.cumulativeBytesLoaded;
          return Center(
            child: CircularProgressIndicator(
              value: total != null ? loaded / total : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else {
      imageWidget = const Icon(Icons.pets, size: 40, color: Colors.grey);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        onTap: () {
          try {
            provider.selectAnimal(animal);
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, anim, __) => const DetailsPage(),
                transitionsBuilder: (_, anim, __, child) {
                  final offset = Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(anim);
                  return SlideTransition(position: offset, child: child);
                },
              ),
            );
          } catch (e) {
            debugPrint('Navigation error: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Couldn’t open details: $e')),
            );
          }
        },
        leading: Hero(
          tag: 'animal-${animal.key}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 60, height: 60, child: imageWidget),
          ),
        ),
        title: Text(animal.name),
        subtitle: Text(
          'Breed: ${animal.breed} | \$${animal.price.toStringAsFixed(2)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Delete
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                try {
                  provider.deleteAnimal(index);
                } catch (e) {
                  debugPrint('Delete error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Couldn’t delete: $e')),
                  );
                }
              },
            ),

            // Edit
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddAnimalPage(
                      animal: animal,
                      index: index,
                    ),
                  ),
                );
              },
            ),

            // Like/Unlike
            IconButton(
              icon: Icon(
                animal.isLiked ? Icons.favorite : Icons.favorite_border,
                color: animal.isLiked ? Colors.redAccent : Colors.grey,
              ),
              onPressed: () async {
                final updated =
                    animal.copyWith(isLiked: !animal.isLiked);
                try {
                  await provider.updateAnimal(index, updated);
                } catch (e) {
                  debugPrint('Favorite toggle error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Couldn’t update favorite: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
