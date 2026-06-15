import 'package:carrocare_flutter/core/theme/app_colors.dart';
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
                      'DAILY CAR WASH',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  BlocBuilder<DailyWashBloc, DailyWashState>(
                    builder: (context, state) {
                      final description = state is DailyWashLoaded
                          ? _stripHtml(state.description)
                          : '';
                      return GestureDetector(
                        onTap: description.isEmpty
                            ? null
                            : () => _showInfo(context, description),
                        child: Container(
                          width: 35,
                          height: 35,
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(5),
                          child: Opacity(
                            opacity: description.isEmpty ? 0.45 : 1,
                            child: Image.asset('assets/images/info.png'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEDEFF1),
                child: BlocBuilder<DailyWashBloc, DailyWashState>(
                  builder: (context, state) {
                    if (state is DailyWashLoading || state is DailyWashInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showInfo(BuildContext context, String description) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Daily Car Wash'),
        content: Text(description),
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

  static const Color _hatchbackImageBg = Color(0xFFCFD8DC);
  static const Color _sedanImageBg = Color(0xFF757575);
  static const Color _suvImageBg = Color(0xFFD8963F);

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

  Color _imageBackgroundColor() {
    final type = service.type.toLowerCase();
    if (type.contains('suv')) return _suvImageBg;
    if (type.contains('sedan')) return _sedanImageBg;
    return _hatchbackImageBg;
  }

  @override
  Widget build(BuildContext context) {
    final textScale =
        MediaQuery.of(context).textScaler.scale(1).clamp(1.0, 1.2);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 7,
      shadowColor: const Color(0x26000000),
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _imageBackgroundColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  service.image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.contain,
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Image.asset(
                      'assets/images/placeholder.png',
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      service.type.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 17 * textScale,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _stripHtml(service.description),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14 * textScale,
                        fontWeight: FontWeight.w300,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹ ${service.displayPrice}/-',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 17 * textScale,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openDetails(context),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/vectors/ic_baseline_arrow_forward_ios_24.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
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

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
