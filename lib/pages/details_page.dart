import 'package:flutter/material.dart';
import 'package:project_cross_final/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../models/animal.dart';
import '../providers/animal_provider.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Animal? animal = context.select<AnimalProvider, Animal?>(
      (provider) => provider.selectedAnimal,
    );

    if (animal == null) {
      // delay showing SnackBar until after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_animal_selected'.tr())),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BottomNavBar()),
          );
        }
      });
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(animal.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'animal-${animal.key}',
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  animal.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    final total = progress.expectedTotalBytes;
                    final loaded = progress.cumulativeBytesLoaded;
                    return Center(
                      child: CircularProgressIndicator(
                        value: total != null ? loaded / total : null,
                      ),
                    );
                  },
                  errorBuilder: (ctx, error, stack) {
                    debugPrint('Error loading image: $error');
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              animal.name,
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              // e.g. "Breed: Golden Retriever"
              tr('breed_label', namedArgs: {'breed': animal.breed}),
              style: textTheme.titleMedium,
            ),
            Text(
              // e.g. "Price: $99.99"
              tr('price_label', namedArgs: {
                'price': animal.price.toStringAsFixed(2)
              }),
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              animal.description,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
