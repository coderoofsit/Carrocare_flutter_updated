import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileGate {
  static Future<bool> hasApartmentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('apartment_name') ?? '';
    return name.isNotEmpty && name.toLowerCase() != 'null';
  }

  static Future<bool> ensureApartmentProfile(BuildContext context) async {
    if (await hasApartmentProfile()) return true;
    await prefsSetLoadFromMain();
    if (!context.mounted) return false;
    GoRouter.of(context).push('/profile');
    return false;
  }

  static Future<void> prefsSetLoadFromMain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_load_from', 'main');
  }
}
