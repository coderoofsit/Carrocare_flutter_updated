import 'package:carrocare_flutter/core/utils/service_description_display.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_gradients.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/car_details/domain/entities/car_details_args.dart';
import 'package:carrocare_flutter/features/vehicles/core/vehicle_category_utils.dart';
import 'package:carrocare_flutter/features/daily_wash/domain/entities/daily_service.dart';
import 'package:carrocare_flutter/features/daily_wash/presentation/bloc/daily_wash_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class DailyCarWashPage extends StatefulWidget {
  const DailyCarWashPage({super.key});

  @override
  State<DailyCarWashPage> createState() => _DailyCarWashPageState();
}

class _DailyCarWashPageState extends State<DailyCarWashPage> {
  @override
  void initState() {
    super.initState();
    context.read<DailyWashBloc>().add(const DailyWashRequested());
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Daily Car Wash',
      onBack: () => context.pop(),
      backgroundDecoration: const BoxDecoration(
        gradient: AppGradients.washScreenBackground,
      ),
      actions: <Widget>[
        BlocBuilder<DailyWashBloc, DailyWashState>(
          builder: (context, state) {
            final description =
                state is DailyWashLoaded ? state.description : '';
            return GestureDetector(
              onTap: description.isEmpty
                  ? null
                  : () => _showInfo(context, description),
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                child: Opacity(
                  opacity: description.isEmpty ? 0.45 : 1,
                  child: Image.asset('assets/images/info.png'),
                ),
              ),
            );
          },
        ),
      ],
      body: BlocBuilder<DailyWashBloc, DailyWashState>(
        builder: (context, state) {
          if (state is DailyWashLoading || state is DailyWashInitial) {
            return const CarroCareLoadingOverlay();
          }
          if (state is DailyWashFailure) {
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

          final loaded = state as DailyWashLoaded;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: loaded.services.length,
            itemBuilder: (context, index) {
              return _ServiceCard(service: loaded.services[index]);
            },
          );
        },
      ),
    );
  }

  static void _showInfo(BuildContext context, String description) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Daily Car Wash'),
        content: SingleChildScrollView(
          child: ServiceDescriptionDisplay.buildPointList(
            description,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final DailyService service;

  void _openDetails(BuildContext context) {
    context.push(
      '/car-details',
      extra: CarDetailsArgs(
        carName: normalizeVehicleCategory(service.type),
        carPrice: service.prices,
        carDesc: service.description,
        carImage: service.image,
        carId: service.id,
        header: 'Daily Car Wash',
        displayPrice: service.displayPrice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScale =
        MediaQuery.of(context).textScaler.scale(1).clamp(1.0, 1.2);
    final includedLabel =
        ServiceDescriptionDisplay.includedServicesLabel(service.description);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: const Color(0x1A000000),
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 140,
              child: Image.network(
                service.image,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/placeholder.png',
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Image.asset(
                    'assets/images/placeholder.png',
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    service.type.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 18 * textScale,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    includedLabel,
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 14 * textScale,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Text(
                        '₹ ${service.displayPrice}/-',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 20 * textScale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'View details',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13 * textScale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            SvgPicture.asset(
                              'assets/vectors/ic_baseline_arrow_forward_ios_24.svg',
                              width: 12,
                              height: 12,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
