/// Chemins de navigation de WAMI Pro (constantes sans dépendance,
/// partagées par les features et le routeur).
abstract final class ProRoutes {
  // Inscription.
  static const welcome = '/welcome';
  static const code = '/welcome/code';
  static const register = '/welcome/profile';
  static const login = '/welcome/login';
  static const forgot = '/welcome/forgot';
  static const documents = '/welcome/documents';
  static const capture = '/welcome/documents/capture';
  static const status = '/welcome/status';

  // Onglets.
  static const missions = '/missions';
  static const earnings = '/earnings';
  static const account = '/account';
  static const notifications = '/account/notifications';
  static const bonus = '/account/bonus';
  static const contract = '/account/contract';
  static const password = '/account/password';
  static const history = '/account/history';
  static const vehicles = '/account/vehicles';
  static const addVehicle = '/account/vehicles/add';
  static const referrals = '/account/referrals';
  static const profile = '/account/profile';
  static const intercity = '/account/intercity';
  static const transfer = '/earnings/transfer';
  static const chat = '/mission/chat';
  static const directRide = '/missions/direct';

  // Mission en cours.
  static const mission = '/mission';
  static const handover = '/mission/handover';
  static const summary = '/mission/summary';

  // Sous-pages.
  static const wallet = '/earnings/wallet';
  static const performance = '/earnings/performance';
}
