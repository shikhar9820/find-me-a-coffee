import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../models/cafe.dart';
import '../models/stamp.dart';
import '../services/stamp_service.dart';
import '../services/location_service.dart';

class CafeDetailScreen extends StatefulWidget {
  final Cafe cafe;

  const CafeDetailScreen({super.key, required this.cafe});

  @override
  State<CafeDetailScreen> createState() => _CafeDetailScreenState();
}

class _CafeDetailScreenState extends State<CafeDetailScreen> {
  final _stampService = StampService();
  final _locationService = LocationService();

  StampSummary? _stampSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStampSummary();
  }

  Future<void> _loadStampSummary() async {
    final summary = await _stampService.getStampSummaryForCafe(widget.cafe.id);
    setState(() {
      _stampSummary = summary;
      _isLoading = false;
    });
  }

  Future<void> _openMaps() async {
    if (widget.cafe.latitude == null || widget.cafe.longitude == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.cafe.latitude},${widget.cafe.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cafe = widget.cafe;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.primary.withOpacity(0.1),
                child: cafe.logoUrl != null
                    ? Image.network(
                        cafe.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Address
                  Text(
                    cafe.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (cafe.address != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cafe.address!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Reward info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Reward',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cafe.displayReward,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Collect ${cafe.stampsRequired} stamps to earn',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Your progress
                  if (!_isLoading && _stampSummary != null) ...[
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildProgressCard(),
                  ] else if (!_isLoading && _stampSummary == null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'You haven\'t collected any stamps here yet. Visit the cafe and tap on the NFC tag!',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Directions button
                  if (cafe.latitude != null && cafe.longitude != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openMaps,
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.secondary,
      child: const Center(
        child: Icon(
          Icons.coffee,
          size: 64,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final summary = _stampSummary!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Stamp circles
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              summary.stampsRequired,
              (index) {
                final isFilled = index < summary.stampCount;
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppTheme.primary : Colors.grey.shade200,
                    border: Border.all(
                      color: isFilled ? AppTheme.primary : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: isFilled
                      ? const Icon(
                          Icons.coffee,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Progress text
          Text(
            '${summary.stampCount} / ${summary.stampsRequired} stamps',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.canRedeem
                ? 'You can redeem your reward!'
                : '${summary.stampsRemaining} more to go',
            style: TextStyle(
              color: summary.canRedeem ? AppTheme.success : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
