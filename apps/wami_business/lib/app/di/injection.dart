import 'package:wami_core/wami_core.dart';

import '../../features/account/data/datasources/account_data_sources.dart';
import '../../features/account/data/repositories/account_repository_impl.dart';
import '../../features/account/domain/repositories/account_repository.dart';
import '../../features/account/domain/usecases/account_usecases.dart';
import '../../features/account/presentation/cubit/account_cubit.dart';
import '../../features/establishments/data/datasources/establishments_data_sources.dart';
import '../../features/establishments/data/repositories/establishments_repository_impl.dart';
import '../../features/establishments/domain/repositories/establishments_repository.dart';
import '../../features/establishments/domain/usecases/establishments_usecases.dart';
import '../../features/establishments/presentation/cubit/establishment_cubit.dart';
import '../../features/finances/data/datasources/finances_data_sources.dart';
import '../../features/finances/data/repositories/finances_repository_impl.dart';
import '../../features/finances/domain/repositories/finances_repository.dart';
import '../../features/finances/domain/usecases/finances_usecases.dart';
import '../../features/finances/presentation/cubit/finances_cubit.dart';
import '../../features/lodging/data/datasources/lodging_data_sources.dart';
import '../../features/lodging/data/repositories/lodging_repository_impl.dart';
import '../../features/lodging/domain/repositories/lodging_repository.dart';
import '../../features/lodging/domain/usecases/lodging_usecases.dart';
import '../../features/lodging/presentation/cubit/lodging_cubits.dart';
import '../../features/onboarding/data/datasources/onboarding_data_sources.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/onboarding_usecases.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/rental/data/datasources/rental_data_sources.dart';
import '../../features/rental/data/repositories/rental_repository_impl.dart';
import '../../features/rental/domain/repositories/rental_repository.dart';
import '../../features/rental/domain/usecases/rental_usecases.dart';
import '../../features/rental/presentation/cubit/rental_cubits.dart';
import '../../features/restaurant/data/datasources/restaurant_data_sources.dart';
import '../../features/restaurant/data/repositories/restaurant_repository_impl.dart';
import '../../features/restaurant/domain/repositories/restaurant_repository.dart';
import '../../features/restaurant/domain/usecases/restaurant_usecases.dart';
import '../../features/restaurant/presentation/cubit/restaurant_cubits.dart';
import '../../features/reviews/data/datasources/reviews_data_sources.dart';
import '../../features/reviews/data/repositories/reviews_repository_impl.dart';
import '../../features/reviews/domain/repositories/reviews_repository.dart';
import '../../features/reviews/domain/usecases/reviews_usecases.dart';
import '../../features/reviews/presentation/cubit/reviews_cubit.dart';
import '../../features/transport/data/datasources/transport_data_sources.dart';
import '../../features/transport/data/repositories/transport_repository_impl.dart';
import '../../features/transport/domain/repositories/transport_repository.dart';
import '../../features/transport/domain/usecases/transport_usecases.dart';
import '../../features/transport/presentation/cubit/transport_cubits.dart';
import '../session/session_cubit.dart';

/// Racine de composition de WAMI Business.
/// Sources, repositories, cas d'usage : singletons paresseux. Cubits : fabriques.
Future<void> configureDependencies(AppConfig config) async {
  await sl.reset();
  sl
    ..registerSingleton<AppConfig>(config)
    ..registerLazySingleton(AuthInterceptor.new)
    ..registerLazySingleton(() => ApiClient(sl(), sl()))
    ..registerLazySingleton(() => FakeBackend(sl()));

  final fake = config.useFakeBackend;
  _onboarding(fake);
  _establishments(fake);
  _restaurant(fake);
  _lodging(fake);
  _rental(fake);
  _transport(fake);
  _finances(fake);
  _reviews(fake);
  _account(fake);
}

void _onboarding(bool fake) {
  sl
    ..registerLazySingleton<OnboardingRemoteDataSource>(
      () => fake ? OnboardingFakeDataSource(sl()) : OnboardingApiDataSource(sl(), sl()),
    )
    ..registerLazySingleton<OnboardingRepository>(() => OnboardingRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetSession(sl()))
    ..registerLazySingleton(() => RequestOtp(sl()))
    ..registerLazySingleton(() => VerifyOtp(sl()))
    ..registerLazySingleton(() => RegisterBusiness(sl()))
    ..registerLazySingleton(() => GetChecklist(sl()))
    ..registerLazySingleton(() => SendChecklistItem(sl()))
    ..registerLazySingleton(() => Logout(sl()))
    ..registerFactory(() => SessionCubit(sl(), sl()))
    ..registerFactory(
      () => OnboardingCubit(
        requestOtp: sl(),
        verifyOtp: sl(),
        register: sl(),
        getChecklist: sl(),
        sendItem: sl(),
      ),
    );
}

void _establishments(bool fake) {
  sl
    ..registerLazySingleton<EstablishmentsRemoteDataSource>(
      () => fake ? EstablishmentsFakeDataSource(sl()) : EstablishmentsApiDataSource(sl()),
    )
    ..registerLazySingleton<EstablishmentsRepository>(() => EstablishmentsRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetEstablishments(sl()))
    ..registerLazySingleton(() => SetEstablishmentOpen(sl()))
    ..registerLazySingleton(() => GetDashboard(sl()))
    ..registerFactory(() => EstablishmentCubit(sl(), sl()))
    ..registerFactory(() => DashboardCubit(sl()));
}

void _restaurant(bool fake) {
  sl
    ..registerLazySingleton<RestaurantRemoteDataSource>(
      () => fake ? RestaurantFakeDataSource(sl()) : RestaurantApiDataSource(sl()),
    )
    ..registerLazySingleton<RestaurantRepository>(() => RestaurantRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetOrders(sl()))
    ..registerLazySingleton(() => AcceptOrder(sl()))
    ..registerLazySingleton(() => RejectOrder(sl()))
    ..registerLazySingleton(() => ExtendPrep(sl()))
    ..registerLazySingleton(() => MarkOrderReady(sl()))
    ..registerLazySingleton(() => GetMenu(sl()))
    ..registerLazySingleton(() => SetItemAvailability(sl()))
    ..registerLazySingleton(() => SetOrdersPaused(sl()))
    ..registerFactory(
      () => OrdersCubit(getOrders: sl(), accept: sl(), reject: sl(), extend: sl(), markReady: sl()),
    )
    ..registerFactory(() => MenuCubit(sl(), sl(), sl()));
}

void _lodging(bool fake) {
  sl
    ..registerLazySingleton<LodgingRemoteDataSource>(
      () => fake ? LodgingFakeDataSource(sl()) : LodgingApiDataSource(sl()),
    )
    ..registerLazySingleton<LodgingRepository>(() => LodgingRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetPlanning(sl()))
    ..registerLazySingleton(() => ConfirmBooking(sl()))
    ..registerLazySingleton(() => RejectBooking(sl()))
    ..registerLazySingleton(() => CreateDeskBooking(sl()))
    ..registerLazySingleton(() => CheckInGuest(sl()))
    ..registerLazySingleton(() => GetRoomTypes(sl()))
    ..registerLazySingleton(() => UpdateRoomType(sl()))
    ..registerFactory(() => PlanningCubit(sl(), sl(), sl()))
    ..registerFactory(() => RoomTypesCubit(sl(), sl()))
    ..registerFactory(() => DeskBookingCubit(sl(), sl()))
    ..registerFactory(() => CheckInCubit(sl()));
}

void _rental(bool fake) {
  sl
    ..registerLazySingleton<RentalRemoteDataSource>(
      () => fake ? RentalFakeDataSource(sl()) : RentalApiDataSource(sl()),
    )
    ..registerLazySingleton<RentalRepository>(() => RentalRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetListings(sl()))
    ..registerLazySingleton(() => SetListingRented(sl()))
    ..registerLazySingleton(() => GetVisits(sl()))
    ..registerLazySingleton(() => AcceptVisit(sl()))
    ..registerLazySingleton(() => DeclineVisit(sl()))
    ..registerLazySingleton(() => ProposeVisitSlot(sl()))
    ..registerLazySingleton(() => GetAvailability(sl()))
    ..registerLazySingleton(() => SaveAvailability(sl()))
    ..registerFactory(
      () => VisitsCubit(getVisits: sl(), getAvailability: sl(), accept: sl(), decline: sl(), propose: sl()),
    )
    ..registerFactory(
      () => ListingsCubit(getListings: sl(), getAvailability: sl(), setRented: sl(), saveAvailability: sl()),
    );
}

void _transport(bool fake) {
  sl
    ..registerLazySingleton<TransportRemoteDataSource>(
      () => fake ? TransportFakeDataSource(sl()) : TransportApiDataSource(sl()),
    )
    ..registerLazySingleton<TransportRepository>(() => TransportRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetDepartures(sl()))
    ..registerLazySingleton(() => GetDeparture(sl()))
    ..registerLazySingleton(() => SellSeat(sl()))
    ..registerLazySingleton(() => ToggleSeatBlocked(sl()))
    ..registerLazySingleton(() => BoardPassenger(sl()))
    ..registerLazySingleton(() => ReportDelay(sl()))
    ..registerLazySingleton(() => GetLines(sl()))
    ..registerLazySingleton(() => UpdateLinePrice(sl()))
    ..registerFactory(() => DeparturesCubit(sl(), sl()))
    ..registerFactory(
      () => SeatMapCubit(getDeparture: sl(), sell: sl(), toggleBlocked: sl(), board: sl()),
    )
    ..registerFactory(() => LinesCubit(sl(), sl()));
}

void _finances(bool fake) {
  sl
    ..registerLazySingleton<FinancesRemoteDataSource>(
      () => fake ? FinancesFakeDataSource(sl()) : FinancesApiDataSource(sl()),
    )
    ..registerLazySingleton<FinancesRepository>(() => FinancesRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetFinanceOverview(sl()))
    ..registerFactory(() => FinancesCubit(sl()));
}

void _reviews(bool fake) {
  sl
    ..registerLazySingleton<ReviewsRemoteDataSource>(
      () => fake ? ReviewsFakeDataSource(sl()) : ReviewsApiDataSource(sl()),
    )
    ..registerLazySingleton<ReviewsRepository>(() => ReviewsRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetReviews(sl()))
    ..registerLazySingleton(() => ReplyToReview(sl()))
    ..registerFactory(() => ReviewsCubit(sl(), sl()));
}

void _account(bool fake) {
  sl
    ..registerLazySingleton<AccountRemoteDataSource>(
      () => fake ? AccountFakeDataSource(sl()) : AccountApiDataSource(sl()),
    )
    ..registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetBusinessAccount(sl()))
    ..registerLazySingleton(() => InviteMember(sl()))
    ..registerLazySingleton(() => RemoveMember(sl()))
    ..registerFactory(() => AccountCubit(sl(), sl(), sl()));
}
