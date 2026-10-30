import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/location_service.dart';
import '../../core/services/open_street_map_service.dart';

class MapLocationResult {
  final String fullAddress;
  final double latitude;
  final double longitude;

  const MapLocationResult({
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
  });
}

class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(18.5204, 73.8567);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late LatLng _center;
  List<OSMPlace> _searchResults = <OSMPlace>[];
  String? _selectedAddress;
  String? _errorMessage;
  bool _isSearching = false;
  bool _isLocating = false;
  bool _isResolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initialLatitude != null && widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _defaultCenter;
    _selectedAddress = widget.initialAddress;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Enter an address, area, landmark, or place name.';
        _searchResults = <OSMPlace>[];
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = <OSMPlace>[];
    });

    try {
      final results = await OpenStreetMapService.search(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        if (results.isEmpty) {
          _errorMessage = 'No matching places found. Try a nearby landmark.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _chooseSearchResult(OSMPlace place) {
    final nextCenter = LatLng(place.latitude, place.longitude);
    setState(() {
      _center = nextCenter;
      _selectedAddress = place.displayName;
      _searchResults = <OSMPlace>[];
      _errorMessage = null;
    });
    _mapController.move(nextCenter, 16);
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      final nextCenter = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _center = nextCenter;
        _selectedAddress = null;
        _searchResults = <OSMPlace>[];
      });
      _mapController.move(nextCenter, 17);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _confirmLocation() async {
    if (_isResolvingAddress) return;

    setState(() {
      _isResolvingAddress = true;
      _errorMessage = null;
    });

    try {
      // The pin is fixed at the screen centre. Read the current map centre
      // rather than the last selected search result.
      final center = _mapController.camera.center;
      final place = await OpenStreetMapService.reverse(
        latitude: center.latitude,
        longitude: center.longitude,
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        MapLocationResult(
          fullAddress: place.displayName,
          latitude: center.latitude,
          longitude: center.longitude,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isResolvingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose delivery location'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              onPositionChanged: (position, hasGesture) {
                final center = position.center;
                if (center != null) {
                  _center = center;
                  _selectedAddress = null;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.quicksalon.app',
                maxZoom: 19,
              ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 34),
                child: Icon(
                  Icons.location_pin,
                  size: 48,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.search),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchPlaces(),
                            decoration: const InputDecoration(
                              hintText: 'Search area, street, landmark...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Search address',
                          onPressed: _isSearching ? null : _searchPlaces,
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                        ),
                      ],
                    ),
                  ),
                  if (_searchResults.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(
                              place.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _chooseSearchResult(place),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 190,
            child: FloatingActionButton.small(
              heroTag: 'current_location_picker',
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: primary,
              onPressed: _isLocating ? null : _useCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          if (_errorMessage != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 150,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Move the map to place the pin exactly',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedAddress ?? 'Tap current location or search, then adjust the map.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isResolvingAddress ? null : _confirmLocation,
                        icon: _isResolvingAddress
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _isResolvingAddress ? 'Getting address...' : 'Confirm location',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 2),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black54,
                    backgroundColor: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
