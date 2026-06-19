import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileActions {
  static Future<void> shareApp(BuildContext context) async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Hey, Download this awesome app! \n ${AppUrls.playStore}',
        subject: 'Share via',
      ),
    );
  }

  static Future<void> rateApp() async {
    final marketUri = Uri.parse('market://details?id=com.muvierecktech.carrocare');
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri);
      return;
    }
    final webUri = Uri.parse(AppUrls.playStore);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<String> versionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return 'Version ${info.version}\n© Carro Auto Pvt Ltd.';
  }
}
