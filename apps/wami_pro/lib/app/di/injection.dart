import 'package:wami_core/wami_core.dart';

import '../../features/account/data/datasources/account_data_sources.dart';
import '../../features/account/data/repositories/account_repository_impl.dart';
import '../../features/account/domain/repositories/account_repository.dart';
import '../../features/account/domain/usecases/account_usecases.dart';
import '../../features/account/presentation/cubit/account_cubit.dart';
import '../../features/bonus/data/datasources/bonus_data_sources.dart';
import '../../features/bonus/data/repositories/bonus_repository_impl.dart';
import '../../features/bonus/domain/repositories/bonus_repository.dart';
import '../../features/bonus/domain/usecases/bonus_usecases.dart';
import '../../features/bonus/presentation/cubit/bonus_cubit.dart';
import '../../features/contract/data/datasources/contract_data_sources.dart';
import '../../features/contract/data/repositories/contract_repository_impl.dart';
import '../../features/contract/domain/repositories/contract_repository.dart';
import '../../features/contract/domain/usecases/contract_usecases.dart';
import '../../features/contract/presentation/cubit/contract_cubit.dart';
import '../../features/notifications/data/datasources/notifications_data_sources.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/notifications_usecases.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/earnings/data/datasources/earnings_data_sources.dart';
import '../../features/earnings/data/repositories/earnings_repository_impl.dart';
import '../../features/earnings/domain/repositories/earnings_repository.dart';
import '../../features/earnings/domain/usecases/earnings_usecases.dart';
import '../../features/earnings/presentation/cubit/earnings_cubits.dart';
import '../../features/missions/data/datasources/missions_data_sources.dart';
import '../../features/missions/data/repositories/missions_repository_impl.dart';
import '../../features/missions/domain/repositories/missions_repository.dart';
import '../../features/missions/domain/usecases/missions_usecases.dart';
import '../../features/missions/presentation/bloc/missions_bloc.dart';
import '../../features/missions/presentation/cubit/direct_ride_cubit.dart';
import '../../features/onboarding/data/datasources/onboarding_data_sources.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/onboarding_usecases.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../shared/app_version.dart';
import '../../shared/location_service.dart';
import '../../shared/push_service.dart';
import '../../shared/realtime_client.dart';
import '../../shared/session_store.dart';
import '../session/session_cubit.dart';

/// Racine de composition de WAMI Pro.
/// Sources, repositories, cas d'usage : singletons paresseux. Blocs : fabriques.
Future<void> configureDependencies(AppConfig config) async {
  sl
    ..registerSingleton<AppConfig>(config)
    ..registerLazySingleton(AuthInterceptor.new)
    // Le serveur enveloppe ses succès dans {success, data}.
    ..registerLazySingleton(() => ApiClient(sl(), sl(), unwrapEnvelope: true))
    ..registerLazySingleton(() => FakeBackend(sl()))
    ..registerLazySingleton(() => SessionStore(sl()))
    ..registerLazySingleton(LocationService.new)
    ..registerLazySingleton(() => PushService(sl()))
    ..registerLazySingleton(() => AppVersionService(sl()))
    ..registerLazySingleton(() => RealtimeClient(sl(), sl()));
  sl<SessionStore>().onCleared = sl<RealtimeClient>().disconnect;

  final fake = config.useFakeBackend;
  _onboarding(fake);
  _missions(fake);
  _earnings(fake);
  _account(fake);
  _bonus(fake);
  _contract(fake);
  _notifications(fake);
}

void _onboarding(bool fake) {
  sl
    ..registerLazySingleton<OnboardingRemoteDataSource>(
      () => fake ? OnboardingFakeDataSource(sl()) : OnboardingApiDataSource(sl(), sl(), sl()),
    )
    ..registerLazySingleton<OnboardingRepository>(() => OnboardingRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetSession(sl()))
    ..registerLazySingleton(() => RequestOtp(sl()))
    ..registerLazySingleton(() => VerifyOtp(sl()))
    ..registerLazySingleton(() => RegisterPartner(sl()))
    ..registerLazySingleton(() => LoginPartner(sl()))
    ..registerLazySingleton(() => RequestPasswordReset(sl()))
    ..registerLazySingleton(() => ResetPassword(sl()))
    ..registerLazySingleton(() => GetDocuments(sl()))
    ..registerLazySingleton(() => UploadDocument(sl()))
    ..registerLazySingleton(() => SubmitForReview(sl()))
    ..registerLazySingleton(() => GetVerification(sl()))
    ..registerLazySingleton(() => CompleteTraining(sl()))
    ..registerLazySingleton(() => Logout(sl()))
    ..registerFactory(() => SessionCubit(sl(), sl()))
    ..registerFactory(
      () => OnboardingCubit(
        requestOtp: sl(),
        verifyOtp: sl(),
        register: sl(),
        login: sl(),
        requestReset: sl(),
        resetPassword: sl(),
        getDocuments: sl(),
        upload: sl(),
        submit: sl(),
        getVerification: sl(),
        completeTraining: sl(),
      ),
    );
}

void _missions(bool fake) {
  sl
    ..registerLazySingleton<MissionsRemoteDataSource>(
      () => fake ? MissionsFakeDataSource(sl()) : MissionsApiDataSource(sl(), sl(), sl(), sl()),
    )
    ..registerLazySingleton<MissionsRepository>(() => MissionsRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetDriverDay(sl()))
    ..registerLazySingleton(() => GetFarePolicy(sl()))
    ..registerLazySingleton(() => SetOnline(sl()))
    ..registerLazySingleton(() => WatchOffers(sl()))
    ..registerLazySingleton(() => GetCurrentMission(sl()))
    ..registerLazySingleton(() => WatchCancellations(sl()))
    ..registerLazySingleton(() => CancelMission(sl()))
    ..registerLazySingleton(() => DeclareNoShow(sl()))
    ..registerLazySingleton(() => ReportDeliveryFailure(sl()))
    ..registerLazySingleton(() => StartReturn(sl()))
    ..registerLazySingleton(() => CompleteReturn(sl()))
    ..registerLazySingleton(() => WatchDestinationChanges(sl()))
    ..registerLazySingleton(() => AnswerDestinationChange(sl()))
    ..registerLazySingleton(() => WatchHotZones(sl()))
    ..registerLazySingleton(() => EstimateDirectRide(sl()))
    ..registerLazySingleton(() => StartDirectRide(sl()))
    ..registerLazySingleton(() => AcceptMission(sl()))
    ..registerLazySingleton(() => DeclineMission(sl()))
    ..registerLazySingleton(() => MarkArrived(sl()))
    ..registerLazySingleton(() => StartTrip(sl()))
    ..registerLazySingleton(() => TogglePause(sl()))
    ..registerLazySingleton(() => CompleteTrip(sl()))
    ..registerLazySingleton(() => ConfirmPickup(sl()))
    ..registerLazySingleton(() => ConfirmHandover(sl()))
    ..registerLazySingleton(() => RateCustomer(sl()))
    ..registerFactory(() => DirectRideCubit(sl(), sl()))
    ..registerFactory(
      () => MissionsBloc(
        getDay: sl(),
        getPolicy: sl(),
        setOnline: sl(),
        watchOffers: sl(),
        currentMission: sl(),
        watchCancellations: sl(),
        cancel: sl(),
        noShow: sl(),
        reportFailure: sl(),
        startReturn: sl(),
        completeReturn: sl(),
        watchDestinationChanges: sl(),
        answerDestination: sl(),
        watchHotZones: sl(),
        accept: sl(),
        decline: sl(),
        arrived: sl(),
        start: sl(),
        togglePause: sl(),
        complete: sl(),
        confirmPickup: sl(),
        handover: sl(),
        rate: sl(),
      ),
    );
}

void _earnings(bool fake) {
  sl
    ..registerLazySingleton<EarningsRemoteDataSource>(
      () => fake ? EarningsFakeDataSource(sl()) : EarningsApiDataSource(sl(), sl()),
    )
    ..registerLazySingleton<EarningsRepository>(() => EarningsRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetEarnings(sl()))
    ..registerLazySingleton(() => GetPartnerWallet(sl()))
    ..registerLazySingleton(() => WithdrawEarnings(sl()))
    ..registerLazySingleton(() => GetPerformance(sl()))
    ..registerFactory(() => EarningsCubit(sl()))
    ..registerFactory(() => PartnerWalletCubit(sl(), sl()))
    ..registerFactory(() => PerformanceCubit(sl()));
}

void _account(bool fake) {
  sl
    ..registerLazySingleton<AccountRemoteDataSource>(
      () => fake ? AccountFakeDataSource(sl()) : AccountApiDataSource(sl(), sl()),
    )
    ..registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetPartnerAccount(sl()))
    ..registerLazySingleton(() => SavePreferences(sl()))
    ..registerLazySingleton(() => ChangePassword(sl()))
    ..registerFactory(() => AccountCubit(sl(), sl()))
    ..registerFactory(() => PasswordCubit(sl()));
}

void _bonus(bool fake) {
  sl
    ..registerLazySingleton<BonusRemoteDataSource>(() => fake ? BonusFakeDataSource(sl()) : BonusApiDataSource(sl(), sl()))
    ..registerLazySingleton<BonusRepository>(() => BonusRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetBonusOverview(sl()))
    ..registerLazySingleton(() => ConsolidateBonus(sl()))
    ..registerFactory(() => BonusCubit(sl(), sl()));
}

void _contract(bool fake) {
  sl
    ..registerLazySingleton<ContractRemoteDataSource>(() => fake ? ContractFakeDataSource(sl()) : ContractApiDataSource(sl()))
    ..registerLazySingleton<ContractRepository>(() => ContractRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetContract(sl()))
    ..registerFactory(() => ContractCubit(sl()));
}

void _notifications(bool fake) {
  sl
    ..registerLazySingleton<NotificationsRemoteDataSource>(
      () => fake ? NotificationsFakeDataSource(sl()) : NotificationsApiDataSource(sl()),
    )
    ..registerLazySingleton<NotificationsRepository>(() => NotificationsRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetNotifications(sl()))
    ..registerLazySingleton(() => MarkNotificationRead(sl()))
    ..registerFactory(() => NotificationsCubit(sl(), sl()));
}
