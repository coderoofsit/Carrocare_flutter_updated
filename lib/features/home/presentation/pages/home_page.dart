import 'dart:async';

import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/utils/session_debug.dart';
import 'package:carrocare_flutter/core/utils/profile_gate.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/widgets/internal_wash_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      if (!mounted || !_sliderController.hasClients || _banners.isEmpty) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: <Widget>[
          SafeArea(
        child: Column(
          children: <Widget>[
            _Header(
              username: _username,
              cartCount: _cartCount,
              onMenuTap: () => context.go('/main-profile'),
              onCartTap: () async {
                await context.push('/cart');
                await _loadCartCount();
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  color: const Color(0xFFEDEFF1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 200,
                        child: Stack(
                          children: <Widget>[
                            PageView.builder(
                              controller: _sliderController,
                              itemCount: _banners.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentBannerIndex = i),
                              itemBuilder: (_, i) => Image.asset(
                                _banners[i],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List<Widget>.generate(
                                  _banners.length,
                                  (index) => Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentBannerIndex == index
                                          ? AppColors.white
                                          : AppColors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SectionTitle(title: 'Subscription  Services'),
                      const SizedBox(height: 6),
                      _TwoColCards(
                        cards: <_ServiceCardData>[
                          _ServiceCardData(
                            id: 'apartment_service',
                            title: 'Apartment Service',
                            imageAsset: 'assets/images/apartment_services.png',
                          ),
                          _ServiceCardData(
                            id: 'doorstep_service',
                            title: 'Door Step Service',
                            imageAsset: 'assets/images/doorstep_service.png',
                          ),
                        ],
                      ),
                      _TwoColCards(
                        cards: <_ServiceCardData>[
                          _ServiceCardData(
                            id: 'daily_car_wash',
                            title: 'Daily Car Wash',
                            imageAsset: 'assets/images/iosdailycardwash.png',
                          ),
                          _ServiceCardData(
                            id: 'bike_wash',
                            title: 'Bike Wash',
                            imageAsset: 'assets/images/iosbikewash.png',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionTitle(title: 'Quick  Services'),
                      const SizedBox(height: 6),
                      // Android home: layoutRow2 = Extra Interior + Wax Polish;
                      // layoutRow3 = My Vehicles (Car Disinfection is visibility=gone).
                      _TwoColCards(
                        cards: <_ServiceCardData>[
                          _ServiceCardData(
                            id: 'extra_interior',
                            title: 'Extra Interior',
                            imageAsset: 'assets/images/iosextrainerior.png',
                          ),
                          _ServiceCardData(
                            id: 'wax_polish',
                            title: 'Wax Polish',
                            imageAsset: 'assets/images/ioswaxpolish.png',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _TwoColCards(
                        cards: <_ServiceCardData>[
                          _ServiceCardData(
                            id: 'my_vehicles',
                            title: 'My Vehicles',
                            imageAsset: 'assets/images/iosvechile.png',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
          if (_showInternalWashOverlay)
            InternalWashEntryOverlay(
              onClose: () => setState(() => _showInternalWashOverlay = false),
            ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: BottomNavigationBar(
          currentIndex: _bottomIndex,
          type: BottomNavigationBarType.fixed,
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
              // Android bottom nav Profile → ProfileActivity (details form).
              context.push('/profile');
              return;
            }
            setState(() => _bottomIndex = index);
          },
          backgroundColor: AppColors.primary,
          selectedItemColor: AppColors.white,
          unselectedItemColor: AppColors.white.withValues(alpha: 0.8),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: _BottomNavIcon('assets/images/orders.png'),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: _BottomNavIcon('assets/images/internal.png'),
              label: 'Internal Car Wash',
            ),
            BottomNavigationBarItem(
              icon: _BottomNavIcon('assets/images/profile.png'),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.username,
    required this.cartCount,
    required this.onMenuTap,
    required this.onCartTap,
  });

  final String username;
  final int cartCount;
  final VoidCallback onMenuTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onMenuTap,
            child: Image.asset('assets/images/menu.png', width: 22, height: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hi ${username.isEmpty ? '' : username} !',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 21,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCartTap,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Center(
                    child: SvgPicture.asset(
                      'assets/vectors/ic_cart.svg',
                      width: 25,
                      height: 25,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.white),
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TwoColCards extends StatelessWidget {
  const _TwoColCards({required this.cards});
  final List<_ServiceCardData> cards;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = cards
        .map((card) => Expanded(child: _ServiceCard(card: card)))
        .toList();
    if (children.length == 1) {
      children.add(const Expanded(child: SizedBox.shrink()));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.card});
  final _ServiceCardData card;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () async {
          if (card.id == 'apartment_service') {
            await ProfileGate.prefsSetLoadFromMain();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_wants', 'apartment');
            if (!context.mounted) return;
            context.push('/apartment-service');
          } else if (card.id == 'doorstep_service') {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_wants', 'doorstep');
            if (!context.mounted) return;
            context.push('/door-step-service');
          } else if (card.id == 'daily_car_wash') {
            if (!await ProfileGate.ensureApartmentProfile(context)) return;
            if (!context.mounted) return;
            context.push('/daily-car-wash');
          } else if (card.id == 'bike_wash') {
            if (!await ProfileGate.ensureApartmentProfile(context)) return;
            if (!context.mounted) return;
            context.push('/bike-wash');
          } else if (card.id == 'car_disinfection') {
            if (!await ProfileGate.ensureApartmentProfile(context)) return;
            if (!context.mounted) return;
            context.push('/disinfection');
          } else if (card.id == 'extra_interior') {
            if (!await ProfileGate.ensureApartmentProfile(context)) return;
            if (!context.mounted) return;
            context.push('/extra-interior');
          } else if (card.id == 'wax_polish') {
            if (!await ProfileGate.ensureApartmentProfile(context)) return;
            if (!context.mounted) return;
            context.push('/wax-polish');
          } else if (card.id == 'my_vehicles') {
            context.push('/my-vehicles');
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Card(
              elevation: 4,
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(19),
                  child: Image.asset(
                    card.imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/placeholder.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              card.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PNGs are large canvases with small centered artwork; scale up visually
/// inside a fixed slot so the bar height stays at 60dp (Android parity).
class _BottomNavIcon extends StatelessWidget {
  const _BottomNavIcon(this.asset);

  final String asset;

  static const double _slotSize = 26;
  static const double _renderSize = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _slotSize,
      height: _slotSize,
      child: OverflowBox(
        alignment: Alignment.center,
        maxWidth: _renderSize,
        maxHeight: _renderSize,
        child: Image.asset(
          asset,
          width: _renderSize,
          height: _renderSize,
          fit: BoxFit.contain,
        ),
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
