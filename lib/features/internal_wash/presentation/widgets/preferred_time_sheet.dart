import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

Future<String?> showPreferredTimeSheet(
  BuildContext context,
  List<String> slots,
) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SafeArea(
        child: Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: slots.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final slot = slots[index];
              return ListTile(
                title: Text(
                  slot,
                  style: const TextStyle(color: AppColors.black, fontSize: 16),
                ),
                onTap: () => Navigator.pop(context, slot),
              );
            },
          ),
        ),
      );
    },
  );
}
