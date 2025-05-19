import 'package:hive/hive.dart';

part 'animal.g.dart';

@HiveType(typeId: 0)
class Animal extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String breed;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String imageUrl;

  @HiveField(5)
  final bool isLiked;

  @HiveField(6)
  final String? imageBase64;

  /// Creates a new Animal.
  /// 
  /// [price] must be >= 0.
  Animal({
    required this.name,
    required this.breed,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.isLiked,
    this.imageBase64,
  }) : assert(price >= 0, 'Price cannot be negative');

  /// Returns a modified copy of this Animal.
  Animal copyWith({
    String? name,
    String? breed,
    double? price,
    String? description,
    String? imageUrl,
    bool? isLiked,
    String? imageBase64,
  }) {
    return Animal(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isLiked: isLiked ?? this.isLiked,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  /// Serialize to a JSON-like map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'breed': breed,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'isLiked': isLiked,
        'imageBase64': imageBase64,
      };

  /// Create an Animal from a JSON-like map.
  /// Throws if required fields are missing or of the wrong type.
  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      name: json['name'] as String,
      breed: json['breed'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      isLiked: json['isLiked'] as bool,
      imageBase64: json['imageBase64'] as String?,
    );
  }

  @override
  String toString() {
    return 'Animal(name: $name, breed: $breed, price: $price, isLiked: $isLiked)';
  }
}
