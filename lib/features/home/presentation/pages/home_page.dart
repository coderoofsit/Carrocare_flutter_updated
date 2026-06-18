import 'dart:async';

import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/utils/profile_gate.dart';
import 'package:carrocare_flutter/core/utils/session_debug.dart';
import 'package:carrocare_flutter/core/widgets/app_bottom_nav.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_app_bar.dart';
import 'package:carrocare_flutter/core/widgets/home_shell.dart';
import 'package:carrocare_flutter/core/widgets/service_card.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/widgets/internal_wash_overlays.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _sliderController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  int _bottomIndex = 1;
  String _username = '';
  int _cartCount = 0;
  bool _showInternalWashOverlay = false;
  final CartLocalStorage _cartStorage = CartLocalStorage();

  final List<String> _banners = <String>[
    'assets/images/slide_1.jpg',
    'assets/images/slide_2.jpg',
    'assets/images/slide_3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadCartCount();
    _startAutoBannerScroll();
  }

  Future<void> _loadCartCount() async {
    _cartCount = await _cartStorage.count();
    if (mounted) setState(() {});
  }

  void _startAutoBannerScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_sliderController.hasClients || _banners.isEmpty) {
        return;
      }
      final int nextPage = (_currentBannerIndex + 1) % _banners.length;
      _sliderController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? '');
    await SessionDebug.logCustomerId(tag: 'HomePage');
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _sliderController.dispose();
    super.dispose();
  }

  Future<void> _onServiceTap(String id) async {
    if (id == 'apartment_service') {
      await ProfileGate.prefsSetLoadFromMain();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_wants', 'apartment');
      if (!mounted) return;
      context.push('/apartment-service');
    } else if (id == 'doorstep_service') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_wants', 'doorstep');
      if (!mounted) return;
      context.push('/door-step-service');
    } else if (id == 'daily_car_wash') {
      if (!await ProfileGate.ensureApartmentProfile(context)) return;
      if (!mounted) return;
      context.push('/daily-car-wash');
    } else if (id == 'bike_wash') {
      if (!await ProfileGate.ensureApartmentProfile(context)) return;
      if (!mounted) return;
      context.push('/bike-wash');
    } else if (id == 'car_disinfection') {
      if (!await ProfileGate.ensureApartmentProfile(context)) return;
      if (!mounted) return;
      context.push('/disinfection');
    } else if (id == 'extra_interior') {
      if (!await ProfileGate.ensureApartmentProfile(context)) return;
      if (!mounted) return;
      context.push('/extra-interior');
    } else if (id == 'wax_polish') {
      if (!await ProfileGate.ensureApartmentProfile(context)) return;
      if (!mounted) return;
      context.push('/wax-polish');
    } else if (id == 'my_vehicles') {
      context.push('/my-vehicles');
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _username.isEmpty ? 'Welcome' : 'Hi $_username';

    return HomeShell(
      appBar: CarroCareAppBar(
        title: greeting,
        subtitle: 'Your car care companion',
        leading: CarroCareAppBarLeading.menu,
        onLeadingTap: () => context.go('/main-profile'),
        transparent: true,
        showBorder: false,
        actions: <Widget>[
          CarroCareCartAction(
            count: _cartCount,
            onTap: () async {
              await context.push('/cart');
              await _loadCartCount();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _PromoBanner(
              banners: _banners,
              controller: _sliderController,
              currentIndex: _currentBannerIndex,
              onPageChanged: (i) => setState(() => _currentBannerIndex = i),
            ),
            const SizedBox(height: 16),
            _QuickAccessRow(
              onOrdersTap: () => context.push('/my-orders'),
              onVehiclesTap: () => context.push('/my-vehicles'),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'Subscription Services'),
            const SizedBox(height: 10),
            _TwoColCards(
              cards: <_ServiceCardData>[
                _ServiceCardData(
                  id: 'daily_car_wash',
                  title: 'Daily Car Wash',
                  imageAsset: 'assets/images/car_wash.jpg',
                ),
                _ServiceCardData(
                  id: 'bike_wash',
                  title: 'Bike Wash',
                  imageAsset: 'assets/images/bike_wash.jpg',
                ),
              ],
              onTap: _onServiceTap,
            ),
            const SizedBox(height: 16),
            const _SectionTitle(title: 'On Demand Services'),
            const SizedBox(height: 10),
            _TwoColCards(
              cards: <_ServiceCardData>[
                _ServiceCardData(
                  id: 'doorstep_service',
                  title: 'Door Step Service',
                  imageAsset: 'assets/images/doorstep_service.png',
                ),
              ],
              onTap: _onServiceTap,
            ),
            const SizedBox(height: 16),
            const _SectionTitle(title: 'Quick Services'),
            const SizedBox(height: 10),
            _TwoColCards(
              cards: <_ServiceCardData>[
                _ServiceCardData(
                  id: 'extra_interior',
                  title: 'Extra Interior',
                  imageAsset: 'assets/images/extra_interior.png',
                ),
                _ServiceCardData(
                  id: 'wax_polish',
                  title: 'Wax Polish',
                  imageAsset: 'assets/images/wax_polish.jpg',
                ),
              ],
              onTap: _onServiceTap,
            ),
            const SizedBox(height: 10),
            _TwoColCards(
              cards: <_ServiceCardData>[
                _ServiceCardData(
                  id: 'my_vehicles',
                  title: 'My Vehicles',
                  imageAsset: 'assets/images/my_vehicles.jpg',
                ),
              ],
              onTap: _onServiceTap,
            ),
          ],
        ),
      ),
      overlay: _showInternalWashOverlay
          ? InternalWashEntryOverlay(
              onClose: () => setState(() => _showInternalWashOverlay = false),
            )
          : null,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _bottomIndex,
        onTap: (index) {
          if (index == 0) {
            context.push('/my-orders');
            return;
          }
          if (index == 1) {
            setState(() {
              _bottomIndex = 1;
              _showInternalWashOverlay = true;
            });
            return;
          }
          if (index == 2) {
            context.push('/profile');
            return;
          }
          setState(() => _bottomIndex = index);
        },
        items: const <AppBottomNavItem>[
          AppBottomNavItem(
            iconAsset: 'assets/images/orders.png',
            label: 'Orders',
          ),
          AppBottomNavItem(
            iconAsset: 'assets/images/internal.png',
            label: 'Internal Car Wash',
          ),
          AppBottomNavItem(
            iconAsset: 'assets/images/profile.png',
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.banners,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<String> banners;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDecorations.bannerRadius),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDecorations.bannerRadius),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              PageView.builder(
                controller: controller,
                itemCount: banners.length,
                onPageChanged: onPageChanged,
                itemBuilder: (_, i) => Image.asset(
                  banners[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(
                    banners.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: currentIndex == index ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: currentIndex == index
                            ? AppColors.primary
                            : AppColors.grey300,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({
    required this.onOrdersTap,
    required this.onVehiclesTap,
  });

  final VoidCallback onOrdersTap;
  final VoidCallback onVehiclesTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: _MyOrdersQuickPill(onTap: onOrdersTap),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MyVehiclesQuickPill(onTap: onVehiclesTap),
          ),
        ],
      ),
    );
  }
}

class _MyOrdersQuickPill extends StatelessWidget {
  const _MyOrdersQuickPill({required this.onTap});

  static const double _pillHeight = 48;
  static const double _iconSlotSize = 34;
  static const double _iconRenderSize = 62;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _QuickAccessCard(
      height: _pillHeight,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: _iconSlotSize,
            height: _iconSlotSize,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: _iconRenderSize,
                maxHeight: _iconRenderSize,
                alignment: Alignment.center,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/orders.png',
                    width: _iconRenderSize,
                    height: _iconRenderSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.delivery_dining_outlined,
                      color: AppColors.primary,
                      size: _iconRenderSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'My Orders',
              style: AppTypography.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyVehiclesQuickPill extends StatelessWidget {
  const _MyVehiclesQuickPill({required this.onTap});

  static const double _pillHeight = 48;
  static const double _iconSlotSize = 30;
  static const double _iconRenderSize = 40;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _QuickAccessCard(
      height: _pillHeight,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: _iconSlotSize,
            height: _iconSlotSize,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: _iconRenderSize,
                maxHeight: _iconRenderSize,
                alignment: Alignment.center,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/iosvechile.png',
                    width: _iconRenderSize,
                    height: _iconRenderSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.directions_car_outlined,
                      color: AppColors.primary,
                      size: _iconRenderSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'My Vehicles',
              style: AppTypography.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.height,
    required this.onTap,
    required this.child,
  });

  final double height;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.grey200),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: height,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: AppTypography.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.grey800,
        ),
      ),
    );
  }
}

class _TwoColCards extends StatelessWidget {
  const _TwoColCards({
    required this.cards,
    required this.onTap,
  });

  final List<_ServiceCardData> cards;
  final Future<void> Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = cards
        .map(
          (card) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                height: 150,
                child: ServiceCard(
                  title: card.title,
                  imageAsset: card.imageAsset,
                  onTap: () => onTap(card.id),
                ),
              ),
            ),
          ),
        )
        .toList();
    if (children.length == 1) {
      children.add(const Expanded(child: SizedBox.shrink()));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ServiceCardData {
  const _ServiceCardData({
    required this.id,
    required this.title,
    required this.imageAsset,
  });

  final String id;
  final String title;
  final String imageAsset;
}
