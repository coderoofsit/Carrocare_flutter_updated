import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/utils/profile_gate.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/remote_image_with_fallback.dart';
import 'package:carrocare_flutter/features/mobile_assets/data/repositories/mobile_assets_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ApartmentServicePage extends StatefulWidget {
  const ApartmentServicePage({super.key});

  @override
  State<ApartmentServicePage> createState() => _ApartmentServicePageState();
}

class _ApartmentServicePageState extends State<ApartmentServicePage> {
  final MobileAssetsRepository _mobileAssets = sl<MobileAssetsRepository>();

  @override
  void initState() {
    super.initState();
    _loadMobileAssets();
  }

  Future<void> _loadMobileAssets() async {
    await _mobileAssets.ensureLoaded();
    if (mounted) setState(() {});
  }

  Future<void> _openService(BuildContext context, VoidCallback route) async {
    if (!await ProfileGate.hasApartmentProfile()) {
      await ProfileGate.prefsSetLoadFromMain();
      if (!context.mounted) return;
      context.push('/profile');
      return;
    }
    route();
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Apartment Service',
      onBack: () => context.go('/home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            _TwoColCards(
              mobileAssets: _mobileAssets,
              cards: <_ApartmentCardData>[
                _ApartmentCardData(
                  title: 'Daily Car Wash',
                  imageAsset: 'assets/images/home_car_wash.png',
                  serviceCardKey: 'apartment_daily_car_wash',
                  onTap: () => _openService(
                    context,
                    () => context.push('/daily-car-wash'),
                  ),
                ),
                _ApartmentCardData(
                  title: 'Car Disinfection',
                  imageAsset: 'assets/images/car_disinsfection.png',
                  serviceCardKey: 'apartment_disinfection',
                  onTap: () => _openService(
                    context,
                    () => context.push('/disinfection'),
                  ),
                ),
              ],
            ),
            _TwoColCards(
              mobileAssets: _mobileAssets,
              cards: <_ApartmentCardData>[
                _ApartmentCardData(
                  title: 'Bike Wash',
                  imageAsset: 'assets/images/iosbikewash.png',
                  serviceCardKey: 'apartment_bike_wash',
                  onTap: () => _openService(
                    context,
                    () => context.push('/bike-wash'),
                  ),
                ),
                _ApartmentCardData(
                  title: 'Wax Polish',
                  imageAsset: 'assets/images/ioswaxpolish.png',
                  serviceCardKey: 'apartment_wax_polish',
                  onTap: () => _openService(
                    context,
                    () => context.push('/wax-polish'),
                  ),
                ),
              ],
            ),
            _TwoColCards(
              mobileAssets: _mobileAssets,
              cards: <_ApartmentCardData>[
                _ApartmentCardData(
                  title: 'Extra Interior',
                  imageAsset: 'assets/images/iosextrainerior.png',
                  serviceCardKey: 'apartment_extra_interior',
                  onTap: () => _openService(
                    context,
                    () => context.push('/extra-interior'),
                  ),
                ),
                _ApartmentCardData(
                  title: 'My Vehicles',
                  imageAsset: 'assets/images/iosvechile.png',
                  serviceCardKey: 'apartment_my_vehicles',
                  onTap: () => _openService(
                    context,
                    () => context.push('/my-vehicles'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApartmentCardData {
  const _ApartmentCardData({
    required this.title,
    required this.imageAsset,
    required this.serviceCardKey,
    required this.onTap,
  });

  final String title;
  final String imageAsset;
  final String serviceCardKey;
  final Future<void> Function() onTap;
}

class _TwoColCards extends StatelessWidget {
  const _TwoColCards({required this.cards, required this.mobileAssets});

  final List<_ApartmentCardData> cards;
  final MobileAssetsRepository mobileAssets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: cards
            .map(
              (card) => Expanded(
                child: _ApartmentCard(card: card, mobileAssets: mobileAssets),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ApartmentCard extends StatelessWidget {
  const _ApartmentCard({required this.card, required this.mobileAssets});

  final _ApartmentCardData card;
  final MobileAssetsRepository mobileAssets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: <Widget>[
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            child: InkWell(
              onTap: () => card.onTap(),
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: RemoteImageWithFallback(
                    imageUrl: mobileAssets.serviceCardUrl(card.serviceCardKey),
                    fallbackAsset: card.imageAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Text(
            card.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
