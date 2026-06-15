import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showServiceTypeDialog(BuildContext context) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose Service Type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Image.asset(
              'assets/images/apartment_services.png',
              width: 40,
              height: 40,
            ),
            title: const Text('Apartment Service'),
            onTap: () => Navigator.pop(context, 'apartment'),
          ),
          ListTile(
            leading: Image.asset(
              'assets/images/doorstep_service.png',
              width: 40,
              height: 40,
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
