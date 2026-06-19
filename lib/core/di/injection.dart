import 'package:carrocare_flutter/core/auth/session_expired_handler.dart';
import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/core/network/auth_token_service.dart';
import 'package:carrocare_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:carrocare_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:carrocare_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:carrocare_flutter/features/auth/domain/usecases/auth_usecases.dart';
import 'package:carrocare_flutter/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:carrocare_flutter/features/auth/presentation/bloc/signup/signup_bloc.dart';
import 'package:carrocare_flutter/features/auth/presentation/bloc/forgot/forgot_password_bloc.dart';
import 'package:carrocare_flutter/features/disinfection/data/datasources/disinfection_remote_data_source.dart';
import 'package:carrocare_flutter/features/disinfection/data/repositories/disinfection_repository_impl.dart';
import 'package:carrocare_flutter/features/disinfection/domain/repositories/disinfection_repository.dart';
import 'package:carrocare_flutter/features/disinfection/domain/usecases/get_disinfection_services_use_case.dart';
import 'package:carrocare_flutter/features/disinfection/presentation/bloc/disinfection_bloc.dart';
import 'package:carrocare_flutter/features/bike_wash/data/datasources/bike_wash_remote_data_source.dart';
import 'package:carrocare_flutter/features/bike_wash/data/repositories/bike_wash_repository_impl.dart';
import 'package:carrocare_flutter/features/bike_wash/domain/repositories/bike_wash_repository.dart';
import 'package:carrocare_flutter/features/bike_wash/domain/usecases/get_bike_wash_service_use_case.dart';
import 'package:carrocare_flutter/features/bike_wash/presentation/bloc/bike_wash_bloc.dart';
import 'package:carrocare_flutter/features/extra_interior/data/datasources/extra_interior_remote_data_source.dart';
import 'package:carrocare_flutter/features/extra_interior/data/repositories/extra_interior_repository_impl.dart';
import 'package:carrocare_flutter/features/extra_interior/domain/repositories/extra_interior_repository.dart';
import 'package:carrocare_flutter/features/extra_interior/domain/usecases/get_extra_interior_service_use_case.dart';
import 'package:carrocare_flutter/features/extra_interior/presentation/bloc/extra_interior_bloc.dart';
import 'package:carrocare_flutter/features/wax_polish/data/datasources/wax_polish_remote_data_source.dart';
import 'package:carrocare_flutter/features/wax_polish/data/repositories/wax_polish_repository_impl.dart';
import 'package:carrocare_flutter/features/wax_polish/domain/repositories/wax_polish_repository.dart';
import 'package:carrocare_flutter/features/wax_polish/domain/usecases/get_wax_polish_services_use_case.dart';
import 'package:carrocare_flutter/features/wax_polish/presentation/bloc/wax_polish_bloc.dart';
import 'package:carrocare_flutter/features/vehicle_list/presentation/bloc/vehicle_list_bloc.dart';
import 'package:carrocare_flutter/features/daily_wash/data/datasources/daily_wash_remote_data_source.dart';
import 'package:carrocare_flutter/features/daily_wash/data/repositories/daily_wash_repository_impl.dart';
import 'package:carrocare_flutter/features/daily_wash/domain/repositories/daily_wash_repository.dart';
import 'package:carrocare_flutter/features/daily_wash/domain/usecases/get_daily_wash_services_use_case.dart';
import 'package:carrocare_flutter/features/daily_wash/presentation/bloc/daily_wash_bloc.dart';
import 'package:carrocare_flutter/features/vehicles/data/datasources/vehicles_remote_data_source.dart';
import 'package:carrocare_flutter/features/vehicles/data/repositories/vehicles_repository.dart';
import 'package:carrocare_flutter/features/vehicles/presentation/bloc/my_vehicles_bloc.dart';
import 'package:carrocare_flutter/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:carrocare_flutter/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:carrocare_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:carrocare_flutter/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:carrocare_flutter/features/mobile_assets/data/datasources/mobile_assets_remote_data_source.dart';
import 'package:carrocare_flutter/features/mobile_assets/data/repositories/mobile_assets_repository.dart';
import 'package:carrocare_flutter/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:carrocare_flutter/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:carrocare_flutter/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:carrocare_flutter/features/billing/domain/repositories/billing_repository.dart';
import 'package:carrocare_flutter/features/billing/presentation/bloc/my_billing_bloc.dart';
import 'package:carrocare_flutter/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:carrocare_flutter/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:carrocare_flutter/features/orders/domain/repositories/orders_repository.dart';
import 'package:carrocare_flutter/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:carrocare_flutter/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:carrocare_flutter/features/orders/presentation/bloc/my_orders_bloc.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerLazySingleton<AuthTokenService>(AuthTokenService.new);
  sl.registerLazySingleton<SessionExpiredHandler>(
    () => SessionExpiredHandler(sl<AuthTokenService>()),
  );
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(sl<AuthTokenService>(), sl<SessionExpiredHandler>()),
  );
  sl.registerLazySingleton<MobileAssetsRemoteDataSource>(
    () => MobileAssetsRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<MobileAssetsRepository>(
    () => MobileAssetsRepository(sl<MobileAssetsRemoteDataSource>()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SendOtpUseCase>(
    () => SendOtpUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ForgotOtpUseCase>(
    () => ForgotOtpUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ForgotUpdateUseCase>(
    () => ForgotUpdateUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<DailyWashRemoteDataSource>(
    () => DailyWashRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<DailyWashRepository>(
    () => DailyWashRepositoryImpl(sl<DailyWashRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetDailyWashServicesUseCase>(
    () => GetDailyWashServicesUseCase(sl<DailyWashRepository>()),
  );
  sl.registerLazySingleton<BikeWashRemoteDataSource>(
    () => BikeWashRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<BikeWashRepository>(
    () => BikeWashRepositoryImpl(sl<BikeWashRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetBikeWashServiceUseCase>(
    () => GetBikeWashServiceUseCase(sl<BikeWashRepository>()),
  );
  sl.registerLazySingleton<ExtraInteriorRemoteDataSource>(
    () => ExtraInteriorRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<ExtraInteriorRepository>(
    () => ExtraInteriorRepositoryImpl(sl<ExtraInteriorRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetExtraInteriorServiceUseCase>(
    () => GetExtraInteriorServiceUseCase(sl<ExtraInteriorRepository>()),
  );
  sl.registerLazySingleton<WaxPolishRemoteDataSource>(
    () => WaxPolishRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<WaxPolishRepository>(
    () => WaxPolishRepositoryImpl(sl<WaxPolishRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetWaxPolishServicesUseCase>(
    () => GetWaxPolishServicesUseCase(sl<WaxPolishRepository>()),
  );
  sl.registerLazySingleton<VehiclesRemoteDataSource>(
    () => VehiclesRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<VehiclesRepository>(
    () => VehiclesRepository(sl<VehiclesRemoteDataSource>()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileRemoteDataSource>()),
  );
  sl.registerLazySingleton<OrdersRemoteDataSource>(
    () => OrdersRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(sl<OrdersRemoteDataSource>()),
  );
  sl.registerLazySingleton<BillingRemoteDataSource>(
    () => BillingRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<BillingRepository>(
    () => BillingRepositoryImpl(sl<BillingRemoteDataSource>()),
  );
  sl.registerLazySingleton<CheckoutRemoteDataSource>(
    () => CheckoutRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(sl<CheckoutRemoteDataSource>()),
  );
  sl.registerFactory<LoginBloc>(() => LoginBloc(sl<LoginUseCase>()));
  sl.registerFactory<SignupBloc>(
    () => SignupBloc(sl<SendOtpUseCase>(), sl<RegisterUseCase>()),
  );
  sl.registerFactory<ForgotPasswordBloc>(
    () => ForgotPasswordBloc(sl<ForgotOtpUseCase>(), sl<ForgotUpdateUseCase>()),
  );
  sl.registerFactory<DailyWashBloc>(
    () => DailyWashBloc(sl<GetDailyWashServicesUseCase>()),
  );
  sl.registerFactory<BikeWashBloc>(
    () => BikeWashBloc(sl<GetBikeWashServiceUseCase>()),
  );
  sl.registerFactory<ExtraInteriorBloc>(
    () => ExtraInteriorBloc(sl<GetExtraInteriorServiceUseCase>()),
  );
  sl.registerFactory<WaxPolishBloc>(
    () => WaxPolishBloc(sl<GetWaxPolishServicesUseCase>()),
  );
  sl.registerFactory<VehicleListBloc>(
    () => VehicleListBloc(sl<VehiclesRepository>()),
  );
  sl.registerFactory<ProfileBloc>(
    () => ProfileBloc(sl<ProfileRepository>(), sl<VehiclesRepository>()),
  );
  sl.registerFactory<MyVehiclesBloc>(
    () => MyVehiclesBloc(sl<VehiclesRepository>()),
  );
  sl.registerFactory<OnboardingBloc>(OnboardingBloc.new);
  sl.registerFactory<MyOrdersBloc>(
    () => MyOrdersBloc(sl<OrdersRepository>()),
  );
  sl.registerFactory<MyBillingBloc>(
    () => MyBillingBloc(sl<BillingRepository>()),
  );
  sl.registerLazySingleton<DisinfectionRemoteDataSource>(
    () => DisinfectionRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<DisinfectionRepository>(
    () => DisinfectionRepositoryImpl(sl<DisinfectionRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetDisinfectionServicesUseCase>(
    () => GetDisinfectionServicesUseCase(sl<DisinfectionRepository>()),
  );
  sl.registerFactory<DisinfectionBloc>(
    () => DisinfectionBloc(sl<GetDisinfectionServicesUseCase>()),
  );
}
