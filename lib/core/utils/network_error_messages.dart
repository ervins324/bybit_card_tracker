/// Converts low-level network exceptions into user-friendly messages.
class NetworkErrorMessages {
  NetworkErrorMessages._();

  static String format(Object error, {String? host}) {
    final text = error.toString().toLowerCase();

    if (text.contains('failed host lookup') ||
        text.contains('no address associated with hostname') ||
        text.contains('socketexception')) {
      final target = host ?? 'the Bybit API server';
      return 'Cannot reach $target.\n\n'
          '• Check mobile data or Wi‑Fi is on\n'
          '• Try another network (some carriers block crypto APIs)\n'
          '• In app menu, switch API Endpoint to a regional server '
          '(Netherlands, Turkey, etc.)\n'
          '• Disable Private DNS / VPN filters temporarily';
    }

    if (text.contains('connection timed out') ||
        text.contains('timed out')) {
      return 'Connection timed out. Check your internet and try again.';
    }

    if (text.contains('connection refused')) {
      return 'Connection refused by the server. Try a different API endpoint.';
    }

    if (text.contains('network is unreachable')) {
      return 'No internet connection. Turn on Wi‑Fi or mobile data.';
    }

    if (text.contains('certificate') || text.contains('handshake')) {
      return 'Secure connection failed. Check your device date/time settings.';
    }

    return error.toString();
  }
}
