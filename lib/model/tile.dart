class Tile {
  final int id;
  final String name;
  final String? size;
  final String finish;
  final double? price;
  final double? squareMeter;

  const Tile({
    required this.id,
    required this.name,
    this.size,
    required this.finish,
    this.price,
    this.squareMeter,
  });
}

