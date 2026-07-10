import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bybit_card_tracker/core/theme/app_theme.dart';
import 'package:bybit_card_tracker/presentation/providers/profile_provider.dart';
import 'package:bybit_card_tracker/presentation/providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    // Only show UAH conversions when toggle is on
    String? uahLine(double usd) {
      if (!settings.showInUah) return null;
      final uah = usd * settings.exchangeRate;
      return '~ ${uah.toStringAsFixed(2)} UAH';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Assets'),
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => RefreshIndicator(
          color: AppTheme.gold,
          onRefresh: () async {
            ref.invalidate(profileProvider);
            try {
              await ref.read(profileProvider.future);
            } catch (_) {}
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                'Bybit Card Tier',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(height: 12),
              _buildCard('Current Tier', profile.tierDisplayName, Icons.star_rounded),
              _buildCard('Monthly Points Used', '${profile.usedLimit.toStringAsFixed(0)} / ${profile.limit.toStringAsFixed(0)} ${profile.unit}', Icons.card_giftcard_rounded,
                extraSubtitle: uahLine(profile.usedLimit),
              ),
              _buildCard('Auto Cashback', profile.autoCashback ? 'Enabled' : 'Disabled', Icons.autorenew_rounded),
              
              const SizedBox(height: 24),
              Text(
                'Funding Assets',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(height: 12),
              _buildCard('USDT Wallet Balance', '${profile.usdtWalletBalance.toStringAsFixed(2)} USDT', Icons.account_balance_wallet_rounded,
                extraSubtitle: uahLine(profile.usdtWalletBalance),
              ),
              _buildCard('USDT Transfer Balance', '${profile.usdtTransferBalance.toStringAsFixed(2)} USDT', Icons.swap_horiz_rounded,
                extraSubtitle: uahLine(profile.usdtTransferBalance),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value, IconData icon, {String? extraSubtitle}) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.cardBorderColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.gold, size: 20),
          ),
          title: Text(
            title, 
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  value, 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              if (extraSubtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    extraSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.gold.withValues(alpha: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
