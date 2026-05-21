

import 'package:estimate_maker/model/estimate_entry.dart';
import 'package:estimate_maker/model/tile.dart';
import 'package:flutter/material.dart';

class EstimateProvider extends ChangeNotifier{
  // Private state

  final List<EstimateEntry> _entries = [];
  Tile? _selectedTile;
  double? _roomArea;

  // public read-only ancestors

  /// A copy of the entries list. Returning a copy prevents 
  /// callers from mutating the internal list directly
  List<EstimateEntry> get entries => List.unmodifiable(_entries);

  Tile? get selectedTile => _selectedTile;
  double? get roomArea => _roomArea;

  /// Gross total across all entries
  double get grossTotal => _entries.fold(0, (sum, entry) => sum + entry.entryTotal);

  /// True only when enough data is there to add an entry
  bool get canAddEntry => 
      _selectedTile != null &&
      _roomArea != null &&
      _roomArea! > 0 &&
      _selectedTile!.price != null &&
      _selectedTile!.squareMeter != null;

  
  // Live calculations preview

  /// Boxes that will be needed for the current inputs, before adding
  /// return null if inputs are incomplete
  int? get previewBoxes {
    if (!canAddEntry) return null;

    if(_decimalSection(_roomArea! / 10) >= 0.45) {
      final raw = (_roomArea! / 10).ceil() / _selectedTile!.squareMeter!; 
      return raw.truncate();
    }
    final raw = (_roomArea! / 10) / _selectedTile!.squareMeter!; 
    return raw.truncate();
  }

  // if _decimalSection >= 0.45,ceil it, else

  double _decimalSection(double num){
    var deci = num - num.truncate();
    return double.parse(deci.toStringAsFixed(2));
  }

  /// Entry total preview before adding
  double? get previewTotal {
    return previewBoxes! * _selectedTile!.price!;
  }

  // Actions
  void selectTile(Tile tile){
    _selectedTile = tile;
    notifyListeners();
  }

  void setRoomArea(double roomArea) {
    _roomArea = roomArea;
    notifyListeners();
  }

  /// calls when user types length and breath separately.
  /// computes area and stores it.
  void setRoomDimensions(double length, double breadth) {
    _roomArea = length * breadth;
    notifyListeners();
  }
  
  void addEntry(){
    if (!canAddEntry) return ;

    _entries.add(
      EstimateEntry(
        tile: _selectedTile!, 
        roomArea: _roomArea!)
    );

    notifyListeners();
  }

  void removeEntry(int index){
    _entries.removeAt(index);
    notifyListeners();
  }

  void clearAll(){
    _entries.clear();
    _selectedTile = null;
    _roomArea = null;
    notifyListeners();
  }
  
}