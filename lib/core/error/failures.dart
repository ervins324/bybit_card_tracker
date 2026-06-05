/// Application-level failure types for clean error propagation.
/// Base failure class.
sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Failure originating from the remote Bybit API.
class ServerFailure extends Failure {
  final int? statusCode;
  final int? retCode;
  const ServerFailure(super.message, {this.statusCode, this.retCode});
}

/// Failure originating from the local Hive cache.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Authentication-related failure (missing/invalid credentials).
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Geo-restriction failure (403 from US/China IP).
class GeoRestrictionFailure extends ServerFailure {
  const GeoRestrictionFailure()
      : super(
          'Access denied. Your IP appears to be in a restricted region '
          '(US or Mainland China). Please use a VPN or try a regional endpoint.',
          statusCode: 403,
        );
}
