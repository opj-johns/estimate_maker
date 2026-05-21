import 'package:estimate_maker/Data/tiles.dart';
import 'package:estimate_maker/model/estimate_entry.dart';
import 'package:estimate_maker/model/tile.dart';
import 'package:estimate_maker/service/estimate_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EstimatorScreen extends StatelessWidget {
    const EstimatorScreen({super.key});

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _RoomDimensionsSection(),
                  SizedBox(height: 16,),
                  _TileSelectorSection(),
                  SizedBox(height: 16,),
                  _EntriesSection(),
                  SizedBox(height: 80,), // clearance for the gross total bar
                ],
              ),
            ),),
        ],
      ),
      bottomNavigationBar: _GrossTotalBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context){
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: Text(
        'Tile Estimator', 
        style: TextStyle(fontSize: 18, fontWeight: .w500),),
      actions: [
        // Clear all button - only visible when there are entries
        Consumer<EstimateProvider>(
          builder: (context, provider, _) {
            if (provider.entries.isEmpty) return SizedBox.shrink();
            return Row(
            children: [
              // Export button
              // _ExportButton(provider: provider),
              // Clear all button
              TextButton.icon(
                onPressed: () => _confirmClearAll(context, provider),
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          );
          },
        )
      ],
    );
  }
}


void _confirmClearAll(BuildContext context, EstimateProvider provider){
  showDialog(context: context, 
  builder: (_) => AlertDialog(
    title: const Text('Clear Estimate?'),
    content: const Text('This will remove all entries. This cannot be undone.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context), 
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => {
          provider.clearAll(),
          Navigator.pop(context),
        }, 
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: const Text('Clear'),
      ),
    ],
  ));
}


class _RoomDimensionsSection extends StatefulWidget {
  const _RoomDimensionsSection();

  @override
  State<_RoomDimensionsSection> createState() => _RoomDimensionsSectionState();
}

class _RoomDimensionsSectionState extends State<_RoomDimensionsSection> {
  // - Input mode -
  // true = user enters length + breadth
  // user enters area directly
  bool _useDimensions = true;

  // controllers
  // Controllers let use read and clear text field programmatically
  final _lengthController = TextEditingController();
  final _breadthController = TextEditingController();
  final _areaController = TextEditingController();

  // Focus nodes
  // Used to move keyboard focus from lenght -> breadth prgrammatically
  final _breadthFocus = FocusNode();

  @override   
  void dispose(){
    // always dispose controller and focus node to free memory
    _lengthController.dispose();
    _breadthController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  // helpers
  void _onDimensionsChanged() {
    final length = double.tryParse(_lengthController.text);
    final breadth = double.tryParse(_breadthController.text);

    if(length != null && breadth != null){
      // Both fields are valid. Push computed area to provider
      context.read<EstimateProvider>().setRoomDimensions(length, breadth);

      // Mirror the computed Area into the area field for user feedback.
      _areaController.text = (length * breadth).toStringAsFixed(2);
    }
  }

 void _onAreaChanged(String value){
  final roomArea = double.tryParse(value);
  if(roomArea != null){
    context.read<EstimateProvider>().setRoomArea(roomArea);
  }
 }

 void _switchMode(bool useDimensions) {
  setState(() {
    _useDimensions = useDimensions;
    //Clear all fields when switching mode to avoid stale values.
    _lengthController.clear();
    _breadthController.clear();
    _areaController.clear();
  });
  context.read<EstimateProvider>().setRoomArea(0);
 }
  

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Room dimensions', 
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _buildModeToggle(context),
          const SizedBox(height: 16,),
          _useDimensions
            ? _buildDimensionInputs(context)
            : _buildAreaInput(context),
        ],
      ));
  }


// - sub-builders
// These methods are not widget classes because they are tiny,
// have no independent lifecycle, and only exist to keep build()
// readable. They rebuild with the parent which is fine here
// because the stateful widget already manages it's own rebuild scope.

  Widget _buildModeToggle(BuildContext context){
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: .circular(8),
      ),
      padding: .all(3),
      child: Row(
        children: [
          _ToggleOption(
          label: 'Length x Breadth',
          selected: _useDimensions,
          onTap: () => _switchMode(true),
          ),
          _ToggleOption(
          label: 'Enter area',
          selected: !_useDimensions,
          onTap: () => _switchMode(false),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionInputs(BuildContext context){
    return Row(
      crossAxisAlignment: .start,
      children: [
        Expanded(
          child: _LabelledField(
            label: 'Length  (m)',
            controller: _lengthController,
            hint: '0.00',
            // When user submits length, jump focus to breadth
            onSubmitted: (_) => 
              FocusScope.of(context).requestFocus(_breadthFocus),
            onChanged: (_) => _onDimensionsChanged(),
          ),
        ),
        const SizedBox(width: 12,),
        Padding(
          padding: const .only(top: 20),
          child: Text(
            'x',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12,),
        Expanded(
          child: _LabelledField(
            label: "Breadth (m)",
            controller: _breadthController,
            hint: '0.00',
            focusNode: _breadthFocus,
            onChanged: (_) => _onDimensionsChanged(),
          ),
        )
      ],
    );
  }

  Widget _buildAreaInput(BuildContext context){
    return _LabelledField(
      label: 'Room area (m²)',
      controller: _areaController,
      hint: '0.00',
      onChanged: _onAreaChanged,
    );
  }
}

class _TileSelectorSection extends StatelessWidget {
  const _TileSelectorSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Select tile',
      child: Consumer<EstimateProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: .stretch,
            children: [
              _buildDropdown(context, provider),
              if(provider.selectedTile != null) ...[
                const SizedBox(height: 14,),
                _TilePreviewCard(tile: provider.selectedTile!),
              ],
              if (provider.canAddEntry) ...[
                const SizedBox(height: 14,),
                _CalcPreviewCard(provider: provider),
                const SizedBox(height: 14,),
                _AddEntryButton(provider: provider),
              ]
            ],
          );
        }),
    );
  }

  Widget _buildDropdown(BuildContext context, EstimateProvider provider){
    return DropdownButtonFormField<Tile>(
      initialValue: provider.selectedTile,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Choose a tile...',
        isDense: true,
        contentPadding: const .symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: .circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: .circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: .circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, 
            width: 1.5
          ),
        ),
      ),
      items: kTiles
        .where((t) => t.price != null && t.squareMeter!=null)
        .map((tile) => DropdownMenuItem<Tile>(
          value: tile,
          child: Text(
            tile.name,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          )))
        .toList(),
      onChanged: (tile) => {
        if(tile != null) context.read<EstimateProvider>().selectTile(tile)
      },
    );
  }
}


class _EntriesSection extends StatelessWidget {
  const _EntriesSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<EstimateProvider>(  
      builder: (context, provider, _){
        if(provider.entries.isEmpty) _buildEmtpyState(context);

        return _SectionCard(
          title: 'Estimate entries', 
          child: Column(
            children: [
              _buildColumnHeaders(context),
              const SizedBox(height: 4,),
              // ListView.builder inside a Column requires a fixed height or
              // ShrinkWrap. We use ShrinkWrap here because the list
              // lives inside a singlechildscrollview - the parent handles all
              // scrolling.
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.entries.length,
                itemBuilder: (context, index){
                  return _EntryRow(
                    entry: provider.entries[index],
                    index: index,
                  );
                }, 
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmtpyState(BuildContext context){
    return Container(
      padding: const .symmetric(vertical: 32),
      alignment: .center,
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12,),
          Text(
            'No entries yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: .w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4,),
          Text(
            'Add a tile above to start your estimate',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.6),
            ),
          ), 
        ],
      ),
    );
  }

  Widget _buildColumnHeaders(BuildContext context){
    final style = TextStyle(
      fontSize: 10,
      fontWeight: .w500,
      letterSpacing: 0.5,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const .only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Tile', style: style,),
          ),
          Expanded(
            child: Text('AREA', style: style, textAlign: .center,),
          ),
          Expanded(
            child: Text('BOXES', style: style, textAlign: .center,),
          ),
          Expanded(
            flex: 2,
            child: Text('TOTAL', style: style, textAlign: .right,),
          ),
          // spacer for the delete icon
          const SizedBox(width: 32,),
        ],
      ),
    );
  }
}


class _GrossTotalBar extends StatelessWidget {  
  const _GrossTotalBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<EstimateProvider>(
      builder: (context, provider, _){
        return Container(
          padding: .symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
         child: Row(children: [
          Column(
            mainAxisSize: .min,
            children: [
              Text(
                'Gross Total',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text('${provider.entries.length} entries',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),)
            ],
          ),
          Spacer(),
          Text(
            'GH₵ ${provider.grossTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: .w500,
            ),
          ),
         ],),
        );
      },);
  }
}

// -shared local primitive

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: .all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        )
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: .fromLTRB(16, 14, 16, 0),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: .w500,
                letterSpacing: .7,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: .all(16),
            child: child,)
        ],
      ),
    );
  }
}

/// A single option inside the mode toggle bar
class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

   const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const .symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: .circular(6),
            border: selected 
              ? .all(color: scheme.outlineVariant, width: 0.5)
              : null,        
          ),
        child: Text(
          label,
          textAlign: .center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: 
              selected ? .w500 : .w400,
            color: selected
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
          ),
        ), 
        ),
      ),
    );
  }
}

/// TextField with a label above it and numeric keyboard
class _LabelledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _LabelledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6,),  
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: 
            const TextInputType.numberWithOptions(decimal: true),
          textInputAction: .next,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: scheme.onSurfaceVariant),
            isDense: true,
            contentPadding: const .symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: scheme.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: .circular(8),
              borderSide: 
                BorderSide(color: scheme.outline, width: 0.5),
            ),
            enabledBorder:  OutlineInputBorder(
              borderRadius: .circular(8),
              borderSide: 
                BorderSide(color: scheme.outlineVariant, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: .circular(8),
              borderSide: 
                BorderSide(color: scheme.primary, width: 1.5),
            )
          ),
        )
      ],
    );    
  }
}

class _TilePreviewCard extends StatelessWidget {
  final Tile tile;
  const _TilePreviewCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: .symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: .circular(8),
        border: .all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: .spaceAround,
        children: [
          _PreviewStat(
            label: 'Size',
            value: tile.size ?? '-',),
          _divider(scheme),
          _PreviewStat(
            label: 'Finish',
            value: tile.finish,),
          _divider(scheme),
          _PreviewStat(
            label: 'Per box',
            value: '${tile.squareMeter} m²',),
          _divider(scheme),
          _PreviewStat(
            label: 'Price',
            value: 'GH₵ ${tile.price!.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme scheme){
    return Container(
      width: 0.5,
      height: 28,
      color: scheme.outlineVariant,
    );
  }
}

/// A single stat inside the tile preview card
class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(value, 
        style: TextStyle(fontSize: 13, fontWeight: .w500),),
        const SizedBox(height: 2,),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CalcPreviewCard extends StatelessWidget {
  final EstimateProvider provider;

  const _CalcPreviewCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const .symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: .circular(8),
        border: .all(
          color: scheme.primary.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _CalcRow(
            label: "Room area",
            value: '${provider.roomArea!.toStringAsFixed(2)} m²',
          ),
          const SizedBox(height: 4,),
          _CalcRow( 
            label:
                '÷ 10 × ${provider.selectedTile!.squareMeter} m²/box',
            value: '= ${(provider.roomArea! / 10 * provider.selectedTile!.squareMeter!).toStringAsFixed(2)}',
          ),
          Divider(
            height: 16,
            color: scheme.primary.withValues(alpha: 0.25),
          ),
          _CalcRow(
            label: 'Boxes needed',
            value: '${provider.previewBoxes} boxes',
            bold: true,
          ),
          const SizedBox(height: 4),
          _CalcRow(
            label: 'Entry total',
            value:
                'GH₵ ${provider.previewTotal!.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );   
  }
}

/// One row inside the calculation preview.
class _CalcRow extends StatelessWidget{
  final String label;
  final String value;
  final bool bold;

  const _CalcRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    
    final style = TextStyle(  
      fontSize: 13,
      fontWeight: bold ? .w500 : .w400,
      color: bold 
        ? Theme.of(context).colorScheme.onSurface 
        : Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Text(label, style: style,),
        Text(value, style: style,),
      ],
    );
  }
}

class _AddEntryButton extends StatelessWidget {
  final EstimateProvider provider;

  const _AddEntryButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          provider.addEntry();
          // Show a brief confirmation snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${provider.selectedTile!.name} added to estimate',),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: .circular(8),
              )
            )
          );
        }, 
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add to estimate'),
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: .symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: .circular(8),
          )
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final EstimateEntry entry;
  final int index;

  const _EntryRow({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // Key must be unique per item. We combine index + tile id
      // to guarantee uniqueness even if the tile appears twice
      key: ValueKey('${index}_${entry.tile.id}'),
      direction: DismissDirection.endToStart,
      // the red background reviewed as the user swipes
      background: _buildDismissibleBackground(context),
      // calls after the dismiss animation completes
      onDismissed: (_) {
        context.read<EstimateProvider>().removeEntry(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.tile.name} removed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: .circular(8),
            )
          )
        );
      }, 
      child: _buildRowContent(context)
    );    
  }

  Widget _buildDismissibleBackground(BuildContext context){
    return Container(
      alignment: .centerRight,
      padding: const .only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: .circular(8),
      ),
      child: Icon(
        Icons.delete_outline,
        color: Theme.of(context).colorScheme.onErrorContainer,
        size: 20,
      ),
    );
  }

  Widget _buildRowContent(BuildContext context){
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const .symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant,
            width: 0.5
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          // Tile name + finish badge
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  entry.tile.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: .w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3,),
                _FinishBadge(finish: entry.tile.finish),
              ],
            ),
          ),
          // Room Area
          // Room area
          Expanded(
            child: Text(
              entry.roomArea.toStringAsFixed(2),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          // Boxes needed
          Expanded(
            child: Text(
              '${entry.boxesNeeded}',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // Entry total
          Expanded(
            flex: 2,
            child: Text(
              'GH₵ ${entry.entryTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          // delete button - tab alternative to swipe
          SizedBox(
            width: 32,
            child: IconButton(
              padding: .zero,
              iconSize: 16, 
              icon: Icon(Icons.close, 
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),),
              onPressed: () => context.read<EstimateProvider>().removeEntry(index),),
          )
        ],
      ),
    );
  }
}

class _FinishBadge extends StatelessWidget {
  final String finish;

  const _FinishBadge({required this.finish});

  // Maps each finish type to a consistent color pair
  // Adding a new finish only requires adding one line here
  static const Map<String, (Color, Color)> _palette = {
    'Polish':      (Color(0xFFE3F2FD), Color(0xFF1565C0)),
    'Rustic':      (Color(0xFFFFF3E0), Color(0xFFE65100)),
    'Unpolish':    (Color(0xFFF3E5F5), Color(0xFF6A1B9A)),
    'Anti-slip':   (Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    'Facial':      (Color(0xFFFCE4EC), Color(0xFFAD1457)),
    'Wall':        (Color(0xFFE0F2F1), Color(0xFF00695C)),
    'Terracotta':  (Color(0xFFFFEBEE), Color(0xFFC62828)),
    'Black Design':(Color(0xFFECEFF1), Color(0xFF263238)),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _palette[finish] ?? 
    (
      Theme.of(context).colorScheme.surfaceContainerHighest,
      Theme.of(context).colorScheme.onSurfaceVariant,
    );   

    return Container(
      padding: const .symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: .circular(99),
      ),
      child: Text(
        finish,
        style: TextStyle(
          fontSize: 10,
          fontWeight: .w500,
          color: colors.$2,
        ),
      ),
    );
  }
}

