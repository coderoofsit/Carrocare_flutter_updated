import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/car_details/domain/entities/car_details_args.dart';
import 'package:carrocare_flutter/features/vehicles/core/vehicle_category_utils.dart';
import 'package:carrocare_flutter/features/extra_interior/presentation/bloc/extra_interior_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ExtraInteriorPage extends StatefulWidget {
  const ExtraInteriorPage({super.key});

  @override
  State<ExtraInteriorPage> createState() => _ExtraInteriorPageState();
}

class _ExtraInteriorPageState extends State<ExtraInteriorPage> {
  @override
  void initState() {
    super.initState();
    context.read<ExtraInteriorBloc>().add(const ExtraInteriorRequested());
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Extra Interior',
      onBack: () => context.pop(),
      footer: BlocBuilder<ExtraInteriorBloc, ExtraInteriorState>(
        builder: (context, state) {
          final price =
              state is ExtraInteriorLoaded ? state.service.displayPrice : '';
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
                          mainAxisAlignment: MainAxisAlignment.center,
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
                  onPressed: state is ExtraInteriorLoaded
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
                              header: 'Extra Interior',
                              displayPrice: service.displayPrice,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
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
      body: BlocBuilder<ExtraInteriorBloc, ExtraInteriorState>(
        builder: (context, state) {
          if (state is ExtraInteriorLoading || state is ExtraInteriorInitial) {
            return const CarroCareLoadingOverlay();
          }
          if (state is ExtraInteriorFailure) {
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

          final loaded = state as ExtraInteriorLoaded;
          final service = loaded.service;
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: <Widget>[
                Card(
                  margin: const EdgeInsets.all(5),
                  elevation: 7,
                  color: AppColors.white,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 5,
                          top: 10,
                          bottom: 10,
                        ),
                        child: Text(
                          service.type.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          _stripHtml(service.description),
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                          ),
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
    );
  }
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
