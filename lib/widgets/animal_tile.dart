import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../providers/animal_provider.dart';
import '../pages/add_animal_page.dart';
import '../pages/details_page.dart';

class AnimalTile extends StatefulWidget {
  final Animal animal;
  final int index;

  const AnimalTile({
    Key? key,
    required this.animal,
    required this.index,
  }) : super(key: key);

  @override
  State<AnimalTile> createState() => _AnimalTileState();
}

class _AnimalTileState extends State<AnimalTile> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _)  => setState(() => _isPressed = true);
  void _onTapUp(TapUpDetails _)      => setState(() => _isPressed = false);
  void _onTapCancel()                => setState(() => _isPressed = false);

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

    // choose the image source:
    Widget imageWidget;
    if (widget.animal.imageBase64 != null &&
        widget.animal.imageBase64!.isNotEmpty &&
        _isValidBase64(widget.animal.imageBase64!)) {
      imageWidget = Image.memory(
        base64Decode(widget.animal.imageBase64!),
        fit: BoxFit.cover,
      );
    } else if (widget.animal.imageUrl.isNotEmpty) {
      imageWidget = Image.network(
        widget.animal.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, prog) =>
            prog == null
                ? child
                : Center(
                    child: CircularProgressIndicator(value: prog.expectedTotalBytes != null
                        ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes!
                        : null),
                  ),
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else {
      imageWidget = const Icon(Icons.pets, size: 40, color: Colors.grey);
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        // Navigate to details with a slide hero transition
        try {
          provider.selectAnimal(widget.animal);
          Navigator.of(context).push(PageRouteBuilder(
            pageBuilder: (_, anim, __) => const DetailsPage(),
            transitionsBuilder: (_, anim, __, child) {
              final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
              return SlideTransition(position: offset, child: child);
            },
          ));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Couldn’t open details: $e')),
          );
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: Hero(
              tag: 'animal-${widget.animal.key}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 60, height: 60, child: imageWidget),
              ),
            ),
            title: Text(widget.animal.name),
            subtitle: Text(
              'Breed: ${widget.animal.breed} | \$${widget.animal.price.toStringAsFixed(2)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // DELETE
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    try {
                      await provider.deleteAnimal(widget.index);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Delete failed: $e')),
                      );
                    }
                  },
                ),

                // EDIT
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddAnimalPage(
                          animal: widget.animal,
                          index: widget.index,
                        ),
                      ),
                    );
                  },
                ),

                // LIKE / UNLIKE
                IconButton(
                  icon: Icon(
                    widget.animal.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: widget.animal.isLiked
                        ? Colors.redAccent
                        : Colors.grey,
                  ),
                  onPressed: () async {
                    final updated = widget.animal.copyWith(
                      isLiked: !widget.animal.isLiked,
                    );
                    try {
                      await provider.updateAnimal(widget.index, updated);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Couldn’t toggle favorite: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
