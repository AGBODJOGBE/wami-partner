/// Chemins de WAMI Business. Aucune dépendance : importable partout.
abstract final class BizRoutes {
  // Inscription
  static const welcome = '/welcome';
  static const code = '/welcome/code';
  static const verification = '/welcome/verification';

  // Onglets
  static const dashboard = '/dashboard';
  static const activity = '/activity';
  static const offer = '/offer';
  static const finances = '/finances';
  static const account = '/account';

  // Pages plein écran
  static const deskBooking = '/activity/desk-booking';
  static const checkIn = '/activity/check-in';
  static const seats = '/activity/seats'; // extra : id du départ
  static const boarding = '/activity/boarding'; // extra : id du départ
  static const payout = '/finances/payout'; // extra : Payout
  static const reviews = '/account/reviews';
  static const team = '/account/team';
}
