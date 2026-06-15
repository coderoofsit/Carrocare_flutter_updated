import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/car_details/domain/entities/car_details_args.dart';
import 'package:carrocare_flutter/features/door_step/domain/entities/confirm_form_args.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CarDetailsPage extends StatelessWidget {
  const CarDetailsPage({super.key, required this.args});

  final CarDetailsArgs args;

  static const String _machinePolishHeader = 'doorstep car machine polish';

  @override
  Widget build(BuildContext context) {
    final isMachinePolish =
        args.header.toLowerCase() == _machinePolishHeader.toLowerCase();
    final bookLabel = isMachinePolish ? 'Proceed' : 'Book now';

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
                  Expanded(
                    child: Text(
                      args.header.toUpperCase(),
                      style: const TextStyle(
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 100),
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
                                    args.carImage,
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
                                      args.carName.toUpperCase(),
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
                                      _stripHtml(args.carDesc),
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
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
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
                            child: Text(
                              'Total amount \n ₹ ${args.displayPrice}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (isMachinePolish) {
                                context.push(
                                  '/confirm-form',
                                  extra: const ConfirmFormArgs(
                                    mode: ConfirmFormMode.machinePolish,
                                  ),
                                );
                              } else {
                                context.push(
                                  '/vehicle-list',
                                  extra: args,
                                );
                              }
                            },
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
                            child: Text(
                              bookLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
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
