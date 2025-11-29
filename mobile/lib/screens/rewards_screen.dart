import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/stamp.dart';
import '../models/redemption.dart';
import '../services/stamp_service.dart';
import '../widgets/reward_card.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _stampService = StampService();

  List<StampSummary> _readyToRedeem = [];
  List<Redemption> _activeRedemptions = [];
  List<Redemption> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final summaries = await _stampService.getUserStampSummaries();
    final activeRedemptions = await _stampService.getActiveRedemptions();
    final history = await _stampService.getRedemptionHistory();

    setState(() {
      _readyToRedeem = summaries.where((s) => s.canRedeem).toList();
      _activeRedemptions = activeRedemptions;
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _redeemReward(StampSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Reward?'),
        content: Text(
          'You\'re about to redeem "${summary.rewardDescription}" at ${summary.cafeName}.\n\n'
          'This will use ${summary.stampsRequired} stamps and generate a code valid for 15 minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final redemption = await _stampService.createRedemption(summary.cafeId);

    if (redemption != null) {
      _loadData();
      _showRedemptionCode(redemption);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create redemption. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showRedemptionCode(Redemption redemption) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RedemptionCodeSheet(redemption: redemption),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rewards',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primary,
                  tabs: [
                    Tab(text: 'Ready (${_readyToRedeem.length})'),
                    Tab(text: 'Active (${_activeRedemptions.length})'),
                    const Tab(text: 'History'),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReadyTab(),
                      _buildActiveTab(),
                      _buildHistoryTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyTab() {
    if (_readyToRedeem.isEmpty) {
      return _buildEmptyState(
        icon: Icons.card_giftcard_outlined,
        title: 'No rewards ready',
        subtitle: 'Keep collecting stamps to earn rewards!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _readyToRedeem.length,
        itemBuilder: (context, index) {
          final summary = _readyToRedeem[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RewardCard(
              cafeName: summary.cafeName,
              cafeLogoUrl: summary.cafeLogoUrl,
              rewardDescription: summary.rewardDescription,
              onRedeem: () => _redeemReward(summary),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_activeRedemptions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.qr_code_outlined,
        title: 'No active redemptions',
        subtitle: 'Redeem a reward to get a code',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _activeRedemptions.length,
        itemBuilder: (context, index) {
          final redemption = _activeRedemptions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ActiveRedemptionCard(
              redemption: redemption,
              onTap: () => _showRedemptionCode(redemption),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No redemption history',
        subtitle: 'Your past redemptions will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final redemption = _history[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HistoryCard(redemption: redemption),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActiveRedemptionCard extends StatelessWidget {
  final Redemption redemption;
  final VoidCallback onTap;

  const _ActiveRedemptionCard({
    required this.redemption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      redemption.cafeName ?? 'Cafe',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      redemption.rewardDescription,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    redemption.redemptionCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Expires in ${redemption.timeRemainingText}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Redemption redemption;

  const _HistoryCard({required this.redemption});

  @override
  Widget build(BuildContext context) {
    final isClaimed = redemption.isClaimed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isClaimed
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isClaimed ? Icons.check_circle : Icons.cancel,
                color: isClaimed ? AppTheme.success : AppTheme.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    redemption.cafeName ?? 'Cafe',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    redemption.rewardDescription,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isClaimed ? 'Claimed' : 'Expired',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isClaimed ? AppTheme.success : AppTheme.error,
                  ),
                ),
                Text(
                  _formatDate(redemption.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _RedemptionCodeSheet extends StatelessWidget {
  final Redemption redemption;

  const _RedemptionCodeSheet({required this.redemption});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.card_giftcard,
            size: 48,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            redemption.cafeName ?? 'Cafe',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            redemption.rewardDescription,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary,
                width: 2,
              ),
            ),
            child: Text(
              redemption.redemptionCode,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Show this code to the cafe staff',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Expires in ${redemption.timeRemainingText}',
            style: TextStyle(
              color: AppTheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
