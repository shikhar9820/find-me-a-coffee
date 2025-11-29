import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/cafe.dart';
import '../services/cafe_service.dart';
import '../services/location_service.dart';
import '../widgets/cafe_tile.dart';
import 'cafe_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _cafeService = CafeService();
  final _locationService = LocationService();
  final _searchController = TextEditingController();

  List<Cafe> _nearbyCafes = [];
  List<Cafe> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadNearbyCafes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyCafes() async {
    setState(() {
      _isLoading = true;
      _locationError = null;
    });

    final locationResult = await _locationService.getCurrentLocation();

    if (locationResult.success && locationResult.position != null) {
      final cafes = await _cafeService.getNearbyCafes(
        latitude: locationResult.position!.latitude,
        longitude: locationResult.position!.longitude,
      );

      setState(() {
        _nearbyCafes = cafes;
        _isLoading = false;
      });
    } else {
      // Fallback: load Delhi cafes
      final cafes = await _cafeService.getCafesByCity('Delhi');

      setState(() {
        _nearbyCafes = cafes;
        _isLoading = false;
        _locationError = locationResult.error;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await _cafeService.searchCafes(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayCafes =
        _searchController.text.isNotEmpty ? _searchResults : _nearbyCafes;

    return SafeArea(
      child: Column(
        children: [
          // Header & Search
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover Cafes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: 'Search cafes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _search('');
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),

          // Location error banner
          if (_locationError != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Showing cafes in Delhi. Enable location for nearby cafes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadNearbyCafes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Cafe list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayCafes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNearbyCafes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: displayCafes.length,
                          itemBuilder: (context, index) {
                            final cafe = displayCafes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CafeTile(
                                cafe: cafe,
                                onTap: () => _openCafeDetail(cafe),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearch = _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearch ? Icons.search_off : Icons.store_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'No cafes found' : 'No cafes nearby',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try a different search term'
                  : 'We\'re expanding soon! Check back later.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _openCafeDetail(Cafe cafe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CafeDetailScreen(cafe: cafe),
      ),
    );
  }
}
