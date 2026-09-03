class AppVersionInfo {
  final String androidMinVersion;
  final String androidMaxVersion;
  final String iosMinVersion;
  final String iosMaxVersion;
  final int iosMinBuild;
  final int iosMaxBuild;
  final String androidUrl;
  final String iosUrl;
  final String title;
  final String message;

  const AppVersionInfo({
    required this.androidMinVersion,
    required this.androidMaxVersion,
    required this.iosMinVersion,
    required this.iosMaxVersion,
    this.iosMinBuild = 0,
    this.iosMaxBuild = 0,
    required this.androidUrl,
    required this.iosUrl,
    required this.title,
    required this.message,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      androidMinVersion: (json['android_min_version'] ?? '1.0.0').toString(),
      androidMaxVersion: (json['android_max_version'] ?? '1.0.0').toString(),
      iosMinVersion: (json['ios_min_version'] ?? '1.0.0').toString(),
      iosMaxVersion: (json['ios_max_version'] ?? '1.0.0').toString(),
      iosMinBuild: int.tryParse((json['ios_min_build'] ?? '0').toString()) ?? 0,
      iosMaxBuild: int.tryParse((json['ios_max_build'] ?? '0').toString()) ?? 0,
      androidUrl: (json['android_url'] ?? '').toString(),
      iosUrl: (json['ios_url'] ?? '').toString(),
      title: (json['title'] ?? 'App Update Available').toString(),
      message: (json['message'] ?? 'A new version of CarroCare is available. Please update for the best experience.').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'android_min_version': androidMinVersion,
        'android_max_version': androidMaxVersion,
        'ios_min_version': iosMinVersion,
        'ios_max_version': iosMaxVersion,
        'ios_min_build': iosMinBuild,
        'ios_max_build': iosMaxBuild,
        'android_url': androidUrl,
        'ios_url': iosUrl,
        'title': title,
        'message': message,
      };
}
