import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/home_providers.dart';
import '../../../core/theme/app_theme.dart';

class LocationSelectorDialog extends ConsumerStatefulWidget {
  const LocationSelectorDialog({super.key});

  @override
  ConsumerState<LocationSelectorDialog> createState() => _LocationSelectorDialogState();
}

class _LocationSelectorDialogState extends ConsumerState<LocationSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _predefinedLocations = [
    {'name': 'Mansingh Bazar', 'lat': 21.4945, 'lng': 86.9238},
    {'name': 'Fakir Mohan Golei', 'lat': 21.4829, 'lng': 86.8987},
    {'name': 'Station Square', 'lat': 21.4934, 'lng': 86.9294},
    {'name': 'Remuna', 'lat': 21.5083, 'lng': 86.8723},
    {'name': 'Sahadev Khuntha', 'lat': 21.4798, 'lng': 86.9156},
    {'name': 'Azimabad', 'lat': 21.4879, 'lng': 86.9321},
    {'name': 'ITB', 'lat': 21.5012, 'lng': 86.9105},
    {'name': 'Balasore', 'lat': 21.4934, 'lng': 86.9294},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Select Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Popular Locations:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ..._predefinedLocations
                        .where((loc) =>
                            _searchController.text.isEmpty ||
                            loc['name']
                                .toString()
                                .toLowerCase()
                                .contains(_searchController.text.toLowerCase()))
                        .map((location) => ListTile(
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(location['name']),
                              onTap: () {
                                ref.read(userLocationProvider.notifier).setLocation(
                                      UserLocation(
                                        lat: location['lat'],
                                        lng: location['lng'],
                                        address: location['name'],
                                      ),
                                    );
                                Navigator.pop(context);
                              },
                            )),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.my_location, color: Color(0xFF22C55E)),
                      title: const Text('Use Current Location (GPS)'),
                      onTap: _isLoading
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              setState(() => _isLoading = true);
                              final result = await ref.read(userLocationProvider.notifier).getCurrentLocation();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(result),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              if (mounted) {
                                navigator.pop();
                              }
                            },
                      trailing: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showLocationSelector(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const LocationSelectorDialog(),
  );
}