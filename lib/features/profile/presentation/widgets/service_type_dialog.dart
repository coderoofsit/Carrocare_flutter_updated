import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/widgets/remote_image_with_fallback.dart';
import 'package:carrocare_flutter/features/mobile_assets/data/repositories/mobile_assets_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showServiceTypeDialog(BuildContext context) async {
  final mobileAssets = sl<MobileAssetsRepository>();
  await mobileAssets.ensureLoaded();
  if (!context.mounted) return;
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose Service Type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: SizedBox(
              width: 40,
              height: 40,
              child: RemoteImageWithFallback(
                imageUrl: mobileAssets.serviceCardUrl('apartment_services'),
                fallbackAsset: 'assets/images/apartment_services.png',
                fit: BoxFit.contain,
              ),
            ),
            title: const Text('Apartment Service'),
            onTap: () => Navigator.pop(context, 'apartment'),
          ),
          ListTile(
            leading: SizedBox(
              width: 40,
              height: 40,
              child: RemoteImageWithFallback(
                imageUrl: mobileAssets.serviceCardUrl('doorstep_picker'),
                fallbackAsset: 'assets/images/doorstep_service.png',
                fit: BoxFit.contain,
              ),
            ),
            title: const Text('Door Step Service'),
            onTap: () => Navigator.pop(context, 'doorstep'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_wants', choice);
  if (!context.mounted) return;
  if (choice == 'apartment') {
    context.push('/apartment-service');
  } else {
    context.push('/door-step-service');
  }
}
