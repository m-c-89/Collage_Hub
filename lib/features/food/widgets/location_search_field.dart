import 'package:flutter/material.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';

/// A search field that shows live inline suggestions from [kDeliveryLocations].
/// Only addresses are shown. Tap → selects. ✕ → clears. If [onScanTap] is non-null
/// a QR icon appears with tooltip "Scan location QR".
class LocationSearchField extends StatefulWidget {
  final DeliveryLocation? selectedLocation;
  final ValueChanged<DeliveryLocation?> onLocationChanged;
  final VoidCallback? onScanTap;

  const LocationSearchField({
    super.key,
    required this.selectedLocation,
    required this.onLocationChanged,
    this.onScanTap,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<DeliveryLocation> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedLocation != null) {
      _controller.text = widget.selectedLocation!.address;
    }
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(LocationSearchField old) {
    super.didUpdateWidget(old);
    if (widget.selectedLocation != old.selectedLocation) {
      if (widget.selectedLocation == null) {
        _controller.clear();
        _suggestions = [];
        _showSuggestions = false;
      } else {
        _controller.text = widget.selectedLocation!.address;
      }
    }
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_focus.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  void _onTextChanged(String value) {
    if (widget.selectedLocation != null) {
      // User is editing after selection — clear the selection
      widget.onLocationChanged(null);
    }
    final results = filterLocations(value);
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty || value.trim().isNotEmpty;
    });
  }

  void _selectLocation(DeliveryLocation loc) {
    _controller.text = loc.address;
    FocusScope.of(context).unfocus();
    _focus.unfocus();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    widget.onLocationChanged(loc);
  }

  void _clear() {
    _controller.clear();
    _suggestions = [];
    _showSuggestions = false;
    widget.onLocationChanged(null);
    setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedLocation != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            hintText: 'Type room, block, or floor…',
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
            ),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle,
                        size: 20, color: AppTheme.pureVegGreen),
                  ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _clear,
                    tooltip: 'Clear',
                    splashRadius: 18,
                  ),
                if (widget.onScanTap != null)
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_outlined, size: 20),
                    onPressed: widget.onScanTap,
                    tooltip: 'Scan location QR',
                    splashRadius: 18,
                  ),
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCD6CC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCD6CC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),

        // Inline suggestions
        if (_showSuggestions)
          TextFieldTapRegion(
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCD6CC)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _suggestions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'No matching location.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : Column(
                      children: _suggestions.map((loc) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _selectLocation(loc),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 16, color: AppTheme.primaryColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      loc.address,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${loc.fee}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
      ],
    );
  }
}
