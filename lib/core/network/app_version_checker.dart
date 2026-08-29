import 'package:carrocare_flutter/app/router.dart';
import 'package:carrocare_flutter/core/network/app_version_model.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/utils/version_comparator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateStatus {
  noUpdate,
  optionalUpdate,
  forceUpdate,
}

class AppVersionChecker {
  static final AppVersionChecker _instance = AppVersionChecker._internal();
  factory AppVersionChecker() => _instance;
  AppVersionChecker._internal();

  static const List<String> _publicRoutes = <String>[
    '/login',
    '/signup',
    '/forgot-password',
    '/splash',
    '/introduction',
  ];

  bool _isDialogShowing = false;
  bool _dismissedOptionalInSession = false;

  /// Check version from API response map post-login.
  Future<void> checkFromResponse(Map<String, dynamic> responseData) async {
    if (responseData['app_version'] is Map) {
      try {
        final versionMap = Map<String, dynamic>.from(responseData['app_version'] as Map);
        final info = AppVersionInfo.fromJson(versionMap);
        await evaluateAndPrompt(info);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AppVersionChecker] Error parsing version: $e');
        }
      }
    }
  }

  /// Evaluates whether an update prompt should be shown.
  Future<void> evaluateAndPrompt(AppVersionInfo versionInfo) async {
    if (_isPublicRoute()) {
      return; // "need to check always after login not before so set it"
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    final minVersion = isAndroid
        ? versionInfo.androidMinVersion
        : (isIOS ? versionInfo.iosMinVersion : '1.0.0');

    final maxVersion = isAndroid
        ? versionInfo.androidMaxVersion
        : (isIOS ? versionInfo.iosMaxVersion : '1.0.0');

    final storeUrl = isAndroid
        ? versionInfo.androidUrl
        : (isIOS ? versionInfo.iosUrl : '');

    final status = _determineStatus(currentVersion, minVersion, maxVersion);

    if (status == UpdateStatus.forceUpdate) {
      _showForceUpdateDialog(versionInfo.title, versionInfo.message, storeUrl);
    } else if (status == UpdateStatus.optionalUpdate) {
      if (!_dismissedOptionalInSession && !_isDialogShowing) {
        _showOptionalUpdateDialog(versionInfo.title, versionInfo.message, storeUrl);
      }
    }
  }

  UpdateStatus _determineStatus(
    String currentVersion,
    String minVersion,
    String maxVersion,
  ) {
    if (VersionComparator.compare(currentVersion, minVersion) < 0) {
      return UpdateStatus.forceUpdate;
    }
    if (VersionComparator.compare(currentVersion, maxVersion) < 0) {
      return UpdateStatus.optionalUpdate;
    }
    return UpdateStatus.noUpdate;
  }

  bool _isPublicRoute() {
    try {
      final path = appRouter.state.uri.path;
      return _publicRoutes.any(
        (route) => path == route || path.startsWith('$route/'),
      );
    } catch (_) {
      return false;
    }
  }

  void _showForceUpdateDialog(String title, String message, String storeUrl) {
    if (_isDialogShowing) return;
    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;

    _isDialogShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  message.isNotEmpty
                      ? message
                      : 'A critical update is required to continue using CarroCare. Please update now.',
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    color: AppColors.grey700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _openStore(storeUrl),
                    child: Text(
                      'UPDATE NOW',
                      style: AppTypography.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  void _showOptionalUpdateDialog(String title, String message, String storeUrl) {
    if (_isDialogShowing) return;
    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;

    _isDialogShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message.isNotEmpty
                    ? message
                    : 'A new version of CarroCare is available with new features and improvements.',
                style: AppTypography.dmSans(
                  fontSize: 14,
                  color: AppColors.grey700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _dismissedOptionalInSession = true;
                      Navigator.of(ctx).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: Text(
                      'UPDATE LATER',
                      style: AppTypography.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _openStore(storeUrl);
                    },
                    child: Text(
                      'UPDATE NOW',
                      style: AppTypography.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  Future<void> _openStore(String storeUrl) async {
    if (storeUrl.isNotEmpty) {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    // Fallback store URLs if custom store URL not set
    Uri fallbackUri;
    if (defaultTargetPlatform == TargetPlatform.android) {
      fallbackUri = Uri.parse('market://details?id=com.carrocare.app');
    } else {
      fallbackUri = Uri.parse('https://apps.apple.com');
    }
    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }
}
