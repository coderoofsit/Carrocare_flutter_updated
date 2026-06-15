import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InternalWashField extends StatelessWidget {
  const InternalWashField({
    super.key,
    required this.value,
    required this.hint,
    this.onTap,
    this.trailingIcon,
    this.maxLines = 1,
    this.readOnly = true,
  });

  final String value;
  final String hint;
  final VoidCallback? onTap;
  final Widget? trailingIcon;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? hint : value;
    final isHint = value.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    display,
                    maxLines: maxLines,
                    style: TextStyle(
                      color: isHint ? Colors.grey : AppColors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (trailingIcon != null) trailingIcon!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InternalWashArrowField extends StatelessWidget {
  const InternalWashArrowField({
    super.key,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final String value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InternalWashField(
      value: value,
      hint: hint,
      onTap: onTap,
      trailingIcon: Transform.rotate(
        angle: 1.5708,
        child: SvgPicture.asset(
          'assets/vectors/ic_baseline_arrow_forward_ios_24.svg',
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            AppColors.black,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class InternalWashCalendarField extends StatelessWidget {
  const InternalWashCalendarField({
    super.key,
    required this.value,
    required this.onTap,
  });

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InternalWashField(
      value: value,
      hint: 'Preferred Date',
      onTap: onTap,
      trailingIcon: SvgPicture.asset(
        'assets/vectors/ic_calendar_24.svg',
        width: 22,
        height: 22,
      ),
    );
  }
}
