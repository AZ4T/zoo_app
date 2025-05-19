import 'package:flutter/material.dart';
import 'package:project_cross_final/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No animal selected.')));
        // if we can go back, just pop; otherwise send them to the home/tabs page:
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BottomNavBar()),
          );
        }
      });
      // render something briefly while the redirect happens
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
              style: textTheme.headlineMedium, // was headline5
            ),
            const SizedBox(height: 8),
            Text(
              'Breed: ${animal.breed}',
              style: textTheme.titleMedium, // was subtitle1
            ),
            Text(
              'Price: \$${animal.price.toStringAsFixed(2)}',
              style: textTheme.titleMedium, // was subtitle1
            ),
            const SizedBox(height: 12),
            Text(
              animal.description,
              style: textTheme.bodyMedium, // was bodyText2
            ),
          ],
        ),
      ),
    );
  }
}
