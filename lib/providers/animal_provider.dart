// lib/providers/animal_provider.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/animal.dart';
import '../services/pixabay_service.dart';

class AnimalProvider extends ChangeNotifier {
  List<Animal> animals = [];
  Animal? selectedAnimal;

  late Box<Animal> animalBox;

  /// Call this once at startup to open Hive and load or seed data.
  Future<void> initHive() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(AnimalAdapter().typeId)) {
        Hive.registerAdapter(AnimalAdapter());
      }
      animalBox = await Hive.openBox<Animal>('animals');

      if (animalBox.isEmpty) {
        await _seedDefaultAnimals();
      }
      _loadFromBox();
    } catch (e, st) {
      debugPrint('initHive error: $e\n$st');
      throw Exception('Couldn’t initialize local database');
    }
  }

  Future<void> _seedDefaultAnimals() async {
    final defaultAnimals = <Animal>[
      Animal(
        name: "Simple Cat",
        breed: "Dvornyaga",
        price: 19.99,
        description: "Friendly and loyal cat",
        imageUrl: "../../assets/cat.jpg",
        isLiked: false,
      ),
      Animal(
        name: "Mr. Duck",
        breed: "duck duck",
        price: 25.99,
        description: "Tasty duck",
        imageUrl: "../../assets/duck.webp",
        isLiked: false,
      ),
      Animal(
        name: "African Grey elephant",
        breed: "African elephant",
        price: 499.99,
        description: "Great giant elephant",
        imageUrl: "../../assets/elephant.webp",
        isLiked: false,
      ),
      Animal(
        name: "German puppy",
        breed: "german original small dog",
        price: 99.99,
        description: "deutsche dogge",
        imageUrl: "../../assets/germanPuppy.webp",
        isLiked: false,
      ),
      Animal(
        name: "Golden dog",
        breed: "golden retriever",
        price: 79.99,
        description: "english dog",
        imageUrl: "../../assets/goldendog.jpeg",
        isLiked: false,
      ),
      Animal(
        name: "kangarooooo",
        breed: "jumping animal",
        price: 129.99,
        description: "australian animal",
        imageUrl: "../../assets/kangaroo.webp",
        isLiked: false,
      ),
      Animal(
        name: "Leopard",
        breed: "cat",
        price: 399.99,
        description: "wild dangerous animal",
        imageUrl: "../../assets/leopard.jpg",
        isLiked: false,
      ),
      Animal(
        name: "Lion king",
        breed: "kitty",
        price: 699.99,
        description: "King of the animals",
        imageUrl: "../../assets/lion.jpg",
        isLiked: false,
      ),
      Animal(
        name: "Panthera",
        breed: "cat",
        price: 499.99,
        description: "black cat",
        imageUrl: "../../assets/panthera.jpg",
        isLiked: false,
      ),
      Animal(
        name: "Great White Shark",
        breed: "fish",
        price: 499.99,
        description: "sea creature",
        imageUrl: "../../assets/shark.webp",
        isLiked: false,
      ),
      Animal(
        name: "Turtle",
        breed: "ant",
        price: 59.99,
        description: "slow animal",
        imageUrl: "../../assets/turtle.jpg",
        isLiked: false,
      ),
      Animal(
        name: "Whale",
        breed: "mammal",
        price: 999.99,
        description: "the biggest mammal",
        imageUrl: "../../assets/whale.jpg",
        isLiked: false,
      ),
    ];
    try {
      await animalBox.addAll(defaultAnimals);
    } catch (e, st) {
      debugPrint('seedDefaultAnimals error: $e\n$st');
      throw Exception('Couldn’t seed default animals');
    }
  }

  void _loadFromBox() {
    animals = animalBox.values.toList();
    notifyListeners();
  }

  /// Create
  Future<void> addAnimal(Animal animal) async {
    try {
      await animalBox.add(animal);
      _loadFromBox();
    } catch (e, st) {
      debugPrint('addAnimal error: $e\n$st');
      throw Exception('Couldn’t add animal');
    }
  }

  /// Read is just _loadFromBox()

  /// Update
  Future<void> updateAnimal(int index, Animal updated) async {
    try {
      await animalBox.putAt(index, updated);
      _loadFromBox();
    } catch (e, st) {
      debugPrint('updateAnimal error: $e\n$st');
      throw Exception('Couldn’t update animal');
    }
  }

  /// Delete
  Future<void> deleteAnimal(int index) async {
    try {
      await animalBox.deleteAt(index);
      _loadFromBox();
    } catch (e, st) {
      debugPrint('deleteAnimal error: $e\n$st');
      throw Exception('Couldn’t delete animal');
    }
  }

  /// Clears the entire box and reloads into memory.
  Future<void> clearAllAnimals() async {
    try {
      await animalBox.clear();
      _loadFromBox();
    } catch (e, st) {
      debugPrint('clearAllAnimals error: $e\n$st');
      throw Exception('Couldn’t clear all animals');
    }
  }

  /// Single‐selection for detail view
  void selectAnimal(Animal animal) {
    selectedAnimal = animal;
    notifyListeners();
  }

  /// Fetch a random image via Pixabay and create a new animal
  Future<void> addAnimalFromApi(String animalType) async {
    try {
      final imageUrl = await PixabayService.getRandomAnimalImage(animalType);
      final animal = Animal(
        name: animalType,
        breed: 'Unknown',
        price: 0.0,
        description: 'Generated from API',
        imageUrl: imageUrl,
        isLiked: false,
      );
      await animalBox.add(animal);
      _loadFromBox();
    } catch (e, st) {
      debugPrint('addAnimalFromApi error: $e\n$st');
      throw Exception('Couldn’t fetch image from API');
    }
  }
}
