import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bybit_card_tracker/core/constants/api_constants.dart';
import 'package:bybit_card_tracker/core/error/failures.dart';
import 'package:bybit_card_tracker/core/theme/app_theme.dart';
import 'package:bybit_card_tracker/core/utils/network_error_messages.dart';
import 'package:bybit_card_tracker/presentation/providers/credentials_provider.dart';
import 'package:bybit_card_tracker/presentation/providers/transaction_provider.dart';
import 'package:bybit_card_tracker/presentation/screens/home_screen.dart';

/// Setup screen for entering and saving Bybit API credentials.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyCtrl = TextEditingController();
  final _apiSecretCtrl = TextEditingController();
  String _selectedBaseUrl = ApiConstants.mainnetBaseUrl;
  bool _obscureKey = true;
  bool _obscureSecret = true;
  bool _isConnecting = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _apiSecretCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isConnecting = true);

    try {
      // 1. Save credentials
      await ref.read(credentialsProvider.notifier).save(
            apiKey: _apiKeyCtrl.text.trim(),
            apiSecret: _apiSecretCtrl.text.trim(),
            baseUrl: _selectedBaseUrl,
          );

      // 2. Trigger first sync
      await ref.read(transactionProvider.notifier).sync();

      if (!mounted) return;

      // 3. Navigate to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is Failure
          ? e.message
          : NetworkErrorMessages.format(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.gold.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),

                    // ── Logo / Header ─
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.gold,
                              AppTheme.gold.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          size: 36,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bybit Card Tracker',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect your Bybit API to start tracking expenses.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 40),

                    // ── API Key ─
                    TextFormField(
                      controller: _apiKeyCtrl,
                      obscureText: _obscureKey,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        prefixIcon: const Icon(Icons.key_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureKey
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () =>
                              setState(() => _obscureKey = !_obscureKey),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'API Key is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── API Secret ─
                    TextFormField(
                      controller: _apiSecretCtrl,
                      obscureText: _obscureSecret,
                      decoration: InputDecoration(
                        labelText: 'API Secret',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSecret
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () => setState(
                              () => _obscureSecret = !_obscureSecret),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'API Secret is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Base URL selector ─
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBaseUrl,
                      decoration: const InputDecoration(
                        labelText: 'API Endpoint',
                        prefixIcon: Icon(Icons.dns_rounded),
                      ),
                      dropdownColor: AppTheme.cardColor,
                      items: ApiConstants.regionalEndpoints.entries
                          .map((e) => DropdownMenuItem(
                                value: e.value,
                                child: Text(
                                  e.key,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedBaseUrl = v);
                      },
                    ),
                    const SizedBox(height: 32),

                    // ── Connect Button ─
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isConnecting ? null : _connect,
                        child: _isConnecting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sync_rounded),
                                  SizedBox(width: 10),
                                  Text('Connect & Sync'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Info hint ─
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your API keys stay on this device only. '
                              'On mobile, if sync fails, try Menu → API Endpoint and pick a regional server. '
                              'Avoid US / Mainland China IP (403).',
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
