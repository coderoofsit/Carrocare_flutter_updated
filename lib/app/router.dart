import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:carrocare_flutter/features/auth/presentation/bloc/signup/signup_bloc.dart';
import 'package:carrocare_flutter/features/auth/presentation/bloc/forgot/forgot_password_bloc.dart';
import 'package:carrocare_flutter/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:carrocare_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:carrocare_flutter/features/auth/presentation/pages/signup_page.dart';
import 'package:carrocare_flutter/features/bike_wash/presentation/bloc/bike_wash_bloc.dart';
import 'package:carrocare_flutter/features/bike_wash/presentation/pages/bike_wash_page.dart';
import 'package:carrocare_flutter/features/car_details/domain/entities/car_details_args.dart';
import 'package:carrocare_flutter/features/car_details/presentation/pages/car_details_page.dart';
import 'package:carrocare_flutter/features/extra_interior/presentation/bloc/extra_interior_bloc.dart';
import 'package:carrocare_flutter/features/extra_interior/presentation/pages/extra_interior_page.dart';
import 'package:carrocare_flutter/features/apartment/presentation/pages/apartment_service_page.dart';
import 'package:carrocare_flutter/features/daily_wash/presentation/bloc/daily_wash_bloc.dart';
import 'package:carrocare_flutter/features/disinfection/presentation/bloc/disinfection_bloc.dart';
import 'package:carrocare_flutter/features/disinfection/presentation/pages/disinfection_page.dart';
import 'package:carrocare_flutter/features/door_step/presentation/pages/door_step_service_page.dart';
import 'package:carrocare_flutter/features/daily_wash/presentation/pages/daily_car_wash_page.dart';
import 'package:carrocare_flutter/features/home/presentation/pages/home_page.dart';
import 'package:carrocare_flutter/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:carrocare_flutter/features/onboarding/presentation/pages/introduction_page.dart';
import 'package:carrocare_flutter/features/onboarding/presentation/pages/splash_page.dart';
import 'package:carrocare_flutter/features/vehicles/presentation/bloc/my_vehicles_bloc.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/add_vehicle_args.dart';
import 'package:carrocare_flutter/features/vehicles/presentation/pages/add_vehicle_page.dart';
import 'package:carrocare_flutter/features/vehicles/presentation/pages/my_vehicles_page.dart';
import 'package:carrocare_flutter/features/vehicle_list/presentation/bloc/vehicle_list_bloc.dart';
import 'package:carrocare_flutter/features/vehicle_list/presentation/pages/vehicle_list_page.dart';
import 'package:carrocare_flutter/features/wax_polish/presentation/bloc/wax_polish_bloc.dart';
import 'package:carrocare_flutter/features/wax_polish/presentation/pages/wax_polish_page.dart';
import 'package:carrocare_flutter/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:carrocare_flutter/features/billing/presentation/bloc/my_billing_bloc.dart';
import 'package:carrocare_flutter/features/renew/presentation/pages/renew_page.dart';
import 'package:carrocare_flutter/features/billing/presentation/pages/my_billing_page.dart';
import 'package:carrocare_flutter/features/orders/presentation/bloc/my_orders_bloc.dart';
import 'package:carrocare_flutter/features/orders/presentation/pages/my_orders_page.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/payment_option_args.dart';
import 'package:carrocare_flutter/features/checkout/presentation/pages/cart_page.dart';
import 'package:carrocare_flutter/features/checkout/presentation/pages/checkout_finalize_page.dart';
import 'package:carrocare_flutter/features/checkout/presentation/pages/payment_option_page.dart';
import 'package:carrocare_flutter/features/checkout/presentation/pages/payment_success_page.dart';
import 'package:carrocare_flutter/features/checkout/presentation/pages/payment_web_page.dart';
import 'package:carrocare_flutter/features/orders/presentation/pages/order_detail_page.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/pages/internal_wash_page.dart';
import 'package:carrocare_flutter/features/orders/presentation/pages/wash_calendar_page.dart';
import 'package:carrocare_flutter/features/profile/presentation/pages/main_profile_page.dart';
import 'package:carrocare_flutter/features/profile/presentation/pages/profile_page.dart';
import 'package:carrocare_flutter/features/support/domain/entities/content_web_args.dart';
import 'package:carrocare_flutter/features/support/presentation/pages/about_us_page.dart';
import 'package:carrocare_flutter/features/support/presentation/pages/contact_us_page.dart';
import 'package:carrocare_flutter/features/support/presentation/pages/content_webview_page.dart';
import 'package:carrocare_flutter/features/support/presentation/pages/faq_page.dart';
import 'package:carrocare_flutter/features/support/presentation/pages/help_and_support_page.dart';
import 'package:carrocare_flutter/features/support/presentation/pages/privacy_policy_page.dart';
import 'package:carrocare_flutter/features/support/presentation/pages/terms_and_conditions_page.dart';
import 'package:carrocare_flutter/features/account/presentation/pages/delete_account_page.dart';
import 'package:carrocare_flutter/features/notifications/presentation/pages/notification_page.dart';
import 'package:carrocare_flutter/features/reminders/presentation/pages/my_reminder_page.dart';
import 'package:carrocare_flutter/features/map/presentation/pages/locate_on_map_page.dart';
import 'package:carrocare_flutter/features/map/presentation/pages/map_add_vehicle_page.dart';
import 'package:carrocare_flutter/features/connectivity/presentation/pages/offline_page.dart';
import 'package:carrocare_flutter/features/door_step/domain/entities/confirm_form_args.dart';
import 'package:carrocare_flutter/features/door_step/presentation/pages/confirm_form_page.dart';
import 'package:carrocare_flutter/features/door_step/presentation/pages/car_polish_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/introduction',
  routes: <RouteBase>[
    GoRoute(
      path: '/introduction',
      builder: (context, state) => const IntroductionPage(),
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<OnboardingBloc>(),
        child: const SplashPage(),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<LoginBloc>(),
        child: const LoginPage(),
      ),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/daily-car-wash',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<DailyWashBloc>(),
        child: const DailyCarWashPage(),
      ),
    ),
    GoRoute(
      path: '/bike-wash',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<BikeWashBloc>(),
        child: const BikeWashPage(),
      ),
    ),
    GoRoute(
      path: '/extra-interior',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<ExtraInteriorBloc>(),
        child: const ExtraInteriorPage(),
      ),
    ),
    GoRoute(
      path: '/disinfection',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<DisinfectionBloc>(),
        child: const DisinfectionPage(),
      ),
    ),
    GoRoute(
      path: '/apartment-service',
      builder: (context, state) => const ApartmentServicePage(),
    ),
    GoRoute(
      path: '/door-step-service',
      builder: (context, state) => const DoorStepServicePage(),
    ),
    GoRoute(
      path: '/help-support',
      builder: (context, state) => const HelpAndSupportPage(),
    ),
    GoRoute(
      path: '/wax-polish',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<WaxPolishBloc>(),
        child: const WaxPolishPage(),
      ),
    ),
    GoRoute(
      path: '/car-details',
      builder: (context, state) {
        final args = state.extra;
        if (args is! CarDetailsArgs) {
          return const Scaffold(
            body: Center(child: Text('Invalid car details')),
          );
        }
        return CarDetailsPage(args: args);
      },
    ),
    GoRoute(
      path: '/vehicle-list',
      builder: (context, state) {
        final args = state.extra;
        if (args is! CarDetailsArgs) {
          return const Scaffold(
            body: Center(child: Text('Invalid vehicle list')),
          );
        }
        return BlocProvider(
          create: (_) => sl<VehicleListBloc>(),
          child: VehicleListPage(args: args),
        );
      },
    ),
    GoRoute(
      path: '/my-vehicles',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<MyVehiclesBloc>(),
        child: const MyVehiclesPage(),
      ),
    ),
    GoRoute(
      path: '/add-vehicle',
      builder: (context, state) {
        final args = state.extra;
        return AddVehiclePage(
          args: args is AddVehicleArgs ? args : null,
        );
      },
    ),
    GoRoute(
      path: '/main-profile',
      builder: (context, state) => const MainProfilePage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<ProfileBloc>(),
        child: const ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/my-orders',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<MyOrdersBloc>(),
        child: const MyOrdersPage(),
      ),
    ),
    GoRoute(
      path: '/my-billings',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<MyBillingBloc>(),
        child: const MyBillingPage(),
      ),
    ),
    GoRoute(
      path: '/renew',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<MyOrdersBloc>(),
        child: const RenewPage(),
      ),
    ),
    GoRoute(
      path: '/content-web',
      builder: (context, state) {
        final args = state.extra;
        if (args is! ContentWebArgs) {
          return const Scaffold(
            body: Center(child: Text('Invalid content page')),
          );
        }
        return ContentWebviewPage(args: args);
      },
    ),
    GoRoute(
      path: '/contact-us',
      builder: (context, state) => const ContactUsPage(),
    ),
    GoRoute(
      path: '/about-us',
      builder: (context, state) => const AboutUsPage(),
    ),
    GoRoute(
      path: '/faq',
      builder: (context, state) => const FaqPage(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    GoRoute(
      path: '/terms-and-conditions',
      builder: (context, state) => const TermsAndConditionsPage(),
    ),
    GoRoute(
      path: '/payment-option',
      builder: (context, state) {
        final args = state.extra;
        if (args is! PaymentOptionArgs) {
          return const Scaffold(
            body: Center(child: Text('Invalid payment option')),
          );
        }
        return PaymentOptionPage(args: args);
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartPage(),
    ),
    GoRoute(
      path: '/payment-web',
      builder: (context, state) {
        final args = state.extra;
        if (args is! PaymentWebArgs) {
          return const Scaffold(
            body: Center(child: Text('Invalid payment web')),
          );
        }
        return PaymentWebPage(args: args);
      },
    ),
    GoRoute(
      path: '/checkout-finalize',
      builder: (context, state) {
        final args = state.extra;
        if (args is! CheckoutFinalizeArgs) {
          return const Scaffold(
            body: Center(child: Text('Invalid checkout')),
          );
        }
        return CheckoutFinalizePage(args: args);
      },
    ),
    GoRoute(
      path: '/payment-success',
      builder: (context, state) => const PaymentSuccessPage(),
    ),
    GoRoute(
      path: '/order-detail',
      builder: (context, state) {
        final args = state.extra;
        if (args is! OrderDetailArgs) {
          return const Scaffold(
            body: Center(child: Text('Invalid order details')),
          );
        }
        return OrderDetailPage(args: args);
      },
    ),
    GoRoute(
      path: '/internal-wash',
      builder: (context, state) {
        final args = state.extra;
        if (args is! InternalWashArgs) {
          return const Scaffold(
            body: Center(child: Text('Invalid internal wash')),
          );
        }
        return InternalWashPage(args: args);
      },
    ),
    GoRoute(
      path: '/wash-calendar',
      builder: (context, state) {
        final args = state.extra;
        if (args is! WashCalendarArgs) {
          return const Scaffold(
            body: Center(child: Text('Invalid calendar')),
          );
        }
        return WashCalendarPage(args: args);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<ForgotPasswordBloc>(),
        child: const ForgotPasswordPage(),
      ),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<SignupBloc>(),
        child: const SignupPage(),
      ),
    ),
    GoRoute(
      path: '/delete-account',
      builder: (context, state) => const DeleteAccountPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: '/my-reminder',
      builder: (context, state) => const MyReminderPage(),
    ),
    GoRoute(
      path: '/locate-on-map',
      builder: (context, state) => const LocateOnMapPage(),
    ),
    GoRoute(
      path: '/map-add-vehicle',
      builder: (context, state) => const MapAddVehiclePage(),
    ),
    GoRoute(
      path: '/confirm-form',
      builder: (context, state) {
        final args = state.extra;
        return ConfirmFormPage(
          args: args is ConfirmFormArgs
              ? args
              : const ConfirmFormArgs(),
        );
      },
    ),
    GoRoute(
      path: '/offline',
      builder: (context, state) => const OfflinePage(),
    ),
    GoRoute(
      path: '/car-polish',
      builder: (context, state) => const CarPolishPage(),
    ),
  ],
);
