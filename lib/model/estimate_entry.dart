import 'tile.dart';

class EstimateEntry {
  final Tile tile;
  final double roomArea; // in square meters

  EstimateEntry({required this.tile, required this.roomArea});

  // number of boxes needed, rounded up to the nearest whole box. Formula is (roomArea / 10) / tile.squareMeter
  // note that ceil() returns the least integer that isn't smaller than this number.
  int get boxesNeeded {
    if (tile.squareMeter == null) return 0;
    final raw = (roomArea / 10) / tile.squareMeter!;
   return raw.ceil() ;
  }

  // Total cost of this entry
  double get entryTotal {
    if (tile.price == null) return 0;

    return boxesNeeded * tile.price!;
  }
}
