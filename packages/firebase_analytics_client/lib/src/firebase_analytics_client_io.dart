/// Analytics client based on Firebase working for mobile.
/// Currently not supported
class FirebaseAnalyticsClient {
  /// Method which tracks an event for the provided
  /// [category], [action], and [label].
  void trackEvent({
    required String category,
    required String action,
    required String label,
  }) {
    // no-op on mobile
  }
}
