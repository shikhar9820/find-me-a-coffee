import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/stamp.dart';
import '../services/stamp_service.dart';
import '../services/nfc_service.dart';
import '../widgets/stamp_card.dart';
import '../widgets/stamp_animation.dart';
import 'discover_screen.dart';
import 'rewards_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _stampService = StampService();
  final _nfcService = NfcService();

  int _currentIndex = 0;
  List<StampSummary> _stampSummaries = [];
  bool _isLoading = true;
  bool _nfcAvailable = false;
  bool _isNfcActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _initNfc();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nfcService.stopSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startNfcSession();
    } else if (state == AppLifecycleState.paused) {
      _nfcService.stopSession();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final summaries = await _stampService.getUserStampSummaries();

    setState(() {
      _stampSummaries = summaries;
      _isLoading = false;
    });
  }

  Future<void> _initNfc() async {
    _nfcAvailable = await _nfcService.isAvailable();
    if (_nfcAvailable) {
      _startNfcSession();
    }
  }

  void _startNfcSession() {
    if (!_nfcAvailable) return;

    setState(() => _isNfcActive = true);

    _nfcService.startSession(
      onCafeTagDetected: (cafeId) => _onStampCollected(cafeId),
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.error,
          ),
        );
      },
    );
  }

  Future<void> _onStampCollected(String cafeId) async {
    final result = await _stampService.collectStamp(cafeId);

    if (result.success && result.summary != null) {
      // Show stamp animation
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StampAnimationDialog(
            cafeName: result.summary!.cafeName,
            currentStamps: result.summary!.stampCount,
            totalStamps: result.summary!.stampsRequired,
            isNewCafe: result.isNewCafe,
          ),
        );
      }

      // Reload data
      _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to collect stamp'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const DiscoverScreen(),
          const RewardsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _nfcAvailable ? null : () => _showNfcUnavailable(),
              backgroundColor:
                  _nfcAvailable ? AppTheme.primary : AppTheme.textSecondary,
              icon: Icon(
                _nfcAvailable ? Icons.nfc : Icons.nfc_outlined,
                color: Colors.white,
              ),
              label: Text(
                _nfcAvailable ? 'Tap to Stamp' : 'NFC Unavailable',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good morning!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your Coffee Stamps',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // NFC Status card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _nfcAvailable
                            ? AppTheme.primary.withOpacity(0.1)
                            : AppTheme.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _nfcAvailable
                              ? AppTheme.primary.withOpacity(0.3)
                              : AppTheme.textSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _nfcAvailable ? Icons.nfc : Icons.nfc_outlined,
                            color: _nfcAvailable
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nfcAvailable
                                      ? 'Ready to Stamp!'
                                      : 'NFC Not Available',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _nfcAvailable
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  _nfcAvailable
                                      ? 'Tap your phone on the NFC tag at any cafe'
                                      : 'Use QR codes to collect stamps',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stamp cards
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_stampSummaries.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final summary = _stampSummaries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: StampCard(summary: summary),
                      );
                    },
                    childCount: _stampSummaries.length,
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.coffee_outlined,
                size: 50,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No stamps yet!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Visit a participating cafe and tap your phone on the NFC tag to collect your first stamp.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _currentIndex = 1); // Go to discover
              },
              icon: const Icon(Icons.explore),
              label: const Text('Discover Cafes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNfcUnavailable() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NFC Not Available'),
        content: const Text(
          'Your device doesn\'t support NFC or it\'s disabled. You can still collect stamps by scanning QR codes at cafes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
