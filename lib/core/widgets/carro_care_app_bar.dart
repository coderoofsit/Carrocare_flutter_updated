import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum CarroCareAppBarLeading { back, menu, none }

class CarroCareAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CarroCareAppBar({
    super.key,
    required this.title,
    this.leading = CarroCareAppBarLeading.back,
    this.onLeadingTap,
    this.actions = const <Widget>[],
    this.backgroundColor = AppColors.white,
    this.transparent = false,
    this.showBorder = true,
    this.subtitle,
  });

  final String title;
  final CarroCareAppBarLeading leading;
  final VoidCallback? onLeadingTap;
  final List<Widget> actions;
  final Color backgroundColor;
  final bool transparent;
  final bool showBorder;
  final String? subtitle;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (subtitle != null ? 20 : 0),
      );

  @override
  Widget build(BuildContext context) {
    final bg = transparent ? Colors.transparent : backgroundColor;
    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: showBorder && !transparent
                ? const Border(
                    bottom: BorderSide(color: AppColors.grey200, width: 1),
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: kToolbarHeight + (subtitle != null ? 20 : 0),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      _LeadingButton(
                        leading: leading,
                        onTap: onLeadingTap,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: AppTypography.quicksand(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: transparent
                                    ? AppColors.grey800
                                    : AppColors.grey800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: AppTypography.dmSans(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      ...actions,
                      if (leading != CarroCareAppBarLeading.none &&
                          actions.isEmpty)
                        const SizedBox(width: 45),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadingButton extends StatelessWidget {
  const _LeadingButton({
    required this.leading,
    this.onTap,
  });

  final CarroCareAppBarLeading leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (leading == CarroCareAppBarLeading.none) {
      return const SizedBox(width: 16);
    }

    final asset = leading == CarroCareAppBarLeading.back
        ? 'assets/images/back.png'
        : 'assets/images/menu.png';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          asset,
          color: AppColors.grey800,
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    );
  }
}

/// Cart icon with optional badge for app bar actions.
class CarroCareCartAction extends StatelessWidget {
  const CarroCareCartAction({
    super.key,
    required this.count,
    required this.onTap,
    this.iconColor = AppColors.grey800,
  });

  final int count;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/vectors/ic_cart.svg',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            if (count > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.white),
                  ),
                  child: Text(
                    '$count',
                    style: AppTypography.dmSans(
                      fontSize: 8,
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
  }
}
