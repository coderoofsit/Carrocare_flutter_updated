import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/car_details/domain/entities/car_details_args.dart';
import 'package:carrocare_flutter/features/daily_wash/domain/entities/daily_service.dart';
import 'package:carrocare_flutter/features/disinfection/presentation/bloc/disinfection_bloc.dart';
import 'package:carrocare_flutter/features/vehicles/core/vehicle_category_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

String _stripHtml(String value) {
  return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

class DisinfectionPage extends StatefulWidget {
  const DisinfectionPage({super.key});

  @override
  State<DisinfectionPage> createState() => _DisinfectionPageState();
}

class _DisinfectionPageState extends State<DisinfectionPage> {
  @override
  void initState() {
    super.initState();
    context.read<DisinfectionBloc>().add(const DisinfectionRequested());
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Car Disinfection',
      onBack: () => context.pop(),
      actions: <Widget>[
        BlocBuilder<DisinfectionBloc, DisinfectionState>(
          builder: (context, state) {
            final description = state is DisinfectionLoaded
                ? _stripHtml(state.description)
                : '';
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
      body: BlocBuilder<DisinfectionBloc, DisinfectionState>(
        builder: (context, state) {
          if (state is DisinfectionLoading || state is DisinfectionInitial) {
            return const CarroCareLoadingOverlay();
          }
          if (state is DisinfectionFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final loaded = state as DisinfectionLoaded;
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
        title: const Text('Car Disinfection'),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 7,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(
            '/car-details',
            extra: CarDetailsArgs(
              carName: normalizeVehicleCategory(service.type),
              carPrice: service.displayPrice,
              carDesc: service.description,
              carImage: service.image,
              carId: service.id,
              header: 'Car Disinfection',
              displayPrice: service.displayPrice,
            ),
          );
        },
        child: SizedBox(
          height: 130,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 140,
                height: double.infinity,
                child: Image.network(
                  service.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        service.type.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          _stripHtml(service.description),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹ ${service.displayPrice}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
