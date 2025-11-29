import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/stamp.dart';

class StampCard extends StatelessWidget {
  final StampSummary summary;
  final VoidCallback? onTap;

  const StampCard({
    super.key,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: summary.cafeLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: summary.cafeLogoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _buildLogoPlaceholder(),
                            ),
                          )
                        : _buildLogoPlaceholder(),
                  ),
                  const SizedBox(width: 12),

                  // Name & reward
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.cafeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary.rewardDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Can redeem badge
                  if (summary.canRedeem)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'READY!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Stamp circles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  summary.stampsRequired,
                  (index) {
                    final isFilled = index < summary.stampCount;
                    return Container(
                      width: 32,
                      height: 32,
                      margin: EdgeInsets.only(
                        right: index < summary.stampsRequired - 1 ? 8 : 0,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? AppTheme.primary : Colors.grey.shade200,
                        border: Border.all(
                          color: isFilled
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isFilled
                          ? const Icon(
                              Icons.coffee,
                              color: Colors.white,
                              size: 16,
                            )
                          : Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: summary.progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    summary.canRedeem ? AppTheme.success : AppTheme.primary,
                  ),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 8),

              // Progress text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${summary.stampCount}/${summary.stampsRequired} stamps',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    summary.canRedeem
                        ? 'Tap to redeem!'
                        : '${summary.stampsRemaining} more to go',
                    style: TextStyle(
                      fontSize: 12,
                      color: summary.canRedeem
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                      fontWeight:
                          summary.canRedeem ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildLogoPlaceholder() {
    return const Center(
      child: Icon(
        Icons.coffee,
        color: AppTheme.primary,
        size: 24,
      ),
    );
  }
}
