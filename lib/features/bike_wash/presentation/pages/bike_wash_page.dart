import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/bike_wash/presentation/bloc/bike_wash_bloc.dart';
import 'package:carrocare_flutter/features/car_details/domain/entities/car_details_args.dart';
import 'package:carrocare_flutter/features/vehicles/core/vehicle_category_utils.dart';import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BikeWashPage extends StatefulWidget {
  const BikeWashPage({super.key});

  @override
  State<BikeWashPage> createState() => _BikeWashPageState();
}

class _BikeWashPageState extends State<BikeWashPage> {
  @override
  void initState() {
    super.initState();
    context.read<BikeWashBloc>().add(const BikeWashRequested());
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
                    onTap: () => context.pop(),
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
                      'DAILY BIKE WASH',
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
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFFEDEFF1),
                      child: BlocBuilder<BikeWashBloc, BikeWashState>(
                        builder: (context, state) {
                          if (state is BikeWashLoading || state is BikeWashInitial) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }
                          if (state is BikeWashFailure) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            );
                          }

                          final loaded = state as BikeWashLoaded;
                          final service = loaded.service;
                          return SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 120),
                            child: Column(
                              children: <Widget>[
                                Card(
                                  margin: const EdgeInsets.all(5),
                                  elevation: 7,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: SizedBox(
                                    height: 220,
                                    width: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Image.network(
                                        service.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Image.asset(
                                          'assets/images/placeholder.png',
                                          fit: BoxFit.cover,
                                        ),
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Image.asset(
                                            'assets/images/placeholder.png',
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        service.type.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _stripHtml(service.description),
                                        style: const TextStyle(
                                          color: AppColors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: BlocBuilder<BikeWashBloc, BikeWashState>(
                      builder: (context, state) {
                        final price = state is BikeWashLoaded
                            ? state.service.displayPrice
                            : '';
                        return Container(
                          height: 100,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 6,
                                offset: Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: price.isEmpty
                                    ? const Text(
                                        'Total amount',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          const Text(
                                            'Total amount',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppColors.black,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            '₹ $price/-',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: state is BikeWashLoaded
                                    ? () {
                                        final service = state.service;
                                        context.push(
                                          '/vehicle-list',
                                          extra: CarDetailsArgs(
                                            carName: normalizeVehicleCategory(
                                              service.type,
                                            ),
                                            carPrice: service.price,
                                            carDesc: service.description,
                                            carImage: service.image,
                                            carId: service.id,
                                            header: 'Daily Bike Wash',
                                            displayPrice: service.displayPrice,
                                          ),
                                        );
                                      }
                                    : null,                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'Book now',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
