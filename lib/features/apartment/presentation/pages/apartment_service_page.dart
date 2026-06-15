import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/utils/profile_gate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class ApartmentServicePage extends StatelessWidget {
  const ApartmentServicePage({super.key});

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
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 35,
                      height: 35,
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(5),
                      child: Image.asset('assets/images/back.png'),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'APARTMENT SERVICE',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEDEFF1),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: <Widget>[
                      _TwoColCards(
                        cards: <_ApartmentCardData>[
                          _ApartmentCardData(
                            title: 'Daily Car Wash',
                            imageAsset: 'assets/images/home_car_wash.png',
                            onTap: () => _openService(
                              context,
                              () => context.push('/daily-car-wash'),
                            ),
                          ),
                          _ApartmentCardData(
                            title: 'Car Disinfection',
                            imageAsset: 'assets/images/car_disinsfection.png',
                            onTap: () => _openService(
                              context,
                              () => context.push('/disinfection'),
                            ),
                          ),
                        ],
                      ),
                      _TwoColCards(
                        cards: <_ApartmentCardData>[
                          _ApartmentCardData(
                            title: 'Bike Wash',
                            imageAsset: 'assets/images/iosbikewash.png',
                            onTap: () => _openService(
                              context,
                              () => context.push('/bike-wash'),
                            ),
                          ),
                          _ApartmentCardData(
                            title: 'Wax Polish',
                            imageAsset: 'assets/images/ioswaxpolish.png',
                            onTap: () => _openService(
                              context,
                              () => context.push('/wax-polish'),
                            ),
                          ),
                        ],
                      ),
                      _TwoColCards(
                        cards: <_ApartmentCardData>[
                          _ApartmentCardData(
                            title: 'Extra Interior',
                            imageAsset: 'assets/images/iosextrainerior.png',
                            onTap: () => _openService(
                              context,
                              () => context.push('/extra-interior'),
                            ),
                          ),
                          _ApartmentCardData(
                            title: 'My Vehicles',
                            imageAsset: 'assets/images/iosvechile.png',
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
              ),
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
    required this.onTap,
  });

  final String title;
  final String imageAsset;
  final Future<void> Function() onTap;
}

class _TwoColCards extends StatelessWidget {
  const _TwoColCards({required this.cards});

  final List<_ApartmentCardData> cards;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: cards
            .map(
              (card) => Expanded(
                child: _ApartmentCard(card: card),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ApartmentCard extends StatelessWidget {
  const _ApartmentCard({required this.card});

  final _ApartmentCardData card;

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
                  child: Image.asset(card.imageAsset, fit: BoxFit.contain),
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
