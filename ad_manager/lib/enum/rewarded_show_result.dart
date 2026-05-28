enum RewardedShowResult {
  /// Ad was shown successfully.
  success,

  /// User declined the consent dialog (opted out).
  consentDeclined,

  /// Ad is not ready or already disposed.
  notReady,

  /// Ad unit is disabled via [AdData.enabled].
  disabled,

  /// An error occurred while showing the ad.
  failed,
}
