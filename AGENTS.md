# bybit_card_tracker

## Quick start
- `flutter pub get` — install deps
- `flutter analyze` — lint only (uses `flutter_lints` v6)
- `flutter run` — any device; no emulator restrictions
- No tests exist (`test/` directory missing); no typecheck script

## Architecture
- **Flutter + Riverpod + Hive + Clean Architecture** (`core/`, `data/`, `domain/`, `presentation/`)
- Use case layer removed as dead code (providers call repository directly)
- State: `AsyncNotifierProvider` for transactions, plain `Provider` for derived stats
- Hive boxes opened at startup in `main.dart`: `settings`, `transactions`
- API credentials stored in `flutter_secure_storage` via `credentials_provider.dart`
- Dark theme via `AppTheme` in `core/theme/app_theme.dart` (Material 3, gold accent, Inter font)

## Entrypoints & Navigation
- `lib/main.dart` → `ProviderScope` → `BybitCardTrackerApp`
- Routes: `/setup` (SetupScreen), `/home` (HomeScreen)
- Home: 4-tab `IndexedStack` — Dashboard, History, Bonuses, Profile
- `HomeScreen.initState` auto-triggers `transactionProvider.notifier.sync()` on every open
- Dashboard auto-fetches exchange rate if API key saved (silent failure)

## API
- Bybit v5, HMAC-SHA256 signing inline in `bybit_remote_datasource.dart`
- Regional endpoint fallback selectable via Settings menu
- Rate limit retry: 3 attempts with exponential backoff (retCodes 10006, 10014, 429)
- Exchange rates via ExchangeRate-API v6 `/pair/USD/UAH`; key persists in Hive

## Categories
- MCC-based resolution in `merchant_categories.dart` (no merchant name matching)
- Per-transaction overrides via `customCategory`; user rules via `CategoryRulesScreen`

## Currency
- UAH/USD toggle on Dashboard
- `exchangeRate` in `AppSettings` (default 41.0), editable via dialog or auto-fetched

## Caveats
- `flutter analyze` is the sole verification command
- All API calls require valid Bybit API key + secret (set in SetupScreen)
- Loading overlay: `loading_animation_widget.threeRotatingDots`, gold, full-screen `Colors.black54`
