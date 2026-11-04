import 'package:equatable/equatable.dart';

/// Lieu connu de l'app, avec ses coordonnées.
///
/// ⚠️ Positions **approximatives** (centre de la ville ou du quartier), en attendant un vrai
/// sélecteur d'adresse (service de géocodage à choisir). Elles servent aux trajets interurbains
/// et à la course directe, dont le serveur exige des coordonnées.
class Place extends Equatable {
  const Place(this.name, this.city, this.lat, this.lng);
  final String name;
  final String city;
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [name, city, lat, lng];
}

abstract final class Places {
  /// Villes pour les trajets interurbains.
  static const cities = [
    Place('Cotonou', 'Cotonou', 6.3703, 2.3912),
    Place('Abomey-Calavi', 'Abomey-Calavi', 6.4485, 2.3556),
    Place('Porto-Novo', 'Porto-Novo', 6.4969, 2.6283),
    Place('Sèmè-Podji', 'Sèmè-Podji', 6.3833, 2.6167),
    Place('Ouidah', 'Ouidah', 6.3630, 2.0850),
    Place('Lokossa', 'Lokossa', 6.6386, 1.7168),
    Place('Bohicon', 'Bohicon', 7.1780, 2.0670),
    Place('Abomey', 'Abomey', 7.1829, 1.9912),
    Place('Dassa-Zoumè', 'Dassa-Zoumè', 7.7500, 2.1833),
    Place('Savalou', 'Savalou', 7.9283, 1.9758),
    Place('Parakou', 'Parakou', 9.3370, 2.6303),
    Place('Djougou', 'Djougou', 9.7085, 1.6660),
    Place('Natitingou', 'Natitingou', 10.3042, 1.3796),
    Place('Kandi', 'Kandi', 11.1342, 2.9386),
    Place('Malanville', 'Malanville', 11.8683, 3.3869),
  ];

  /// Quartiers et lieux de Cotonou et environs, pour la course directe.
  static const quarters = [
    Place('Aéroport de Cotonou', 'Cotonou', 6.3573, 2.3844),
    Place('Cadjèhoun', 'Cotonou', 6.3560, 2.3700),
    Place('Fidjrossè', 'Cotonou', 6.3480, 2.3550),
    Place('Haie Vive', 'Cotonou', 6.3640, 2.3900),
    Place('Ganhi', 'Cotonou', 6.3600, 2.4300),
    Place('Marché Dantokpa', 'Cotonou', 6.3677, 2.4390),
    Place('Akpakpa', 'Cotonou', 6.3560, 2.4400),
    Place('Godomey', 'Abomey-Calavi', 6.4140, 2.3250),
    Place('Abomey-Calavi', 'Abomey-Calavi', 6.4485, 2.3556),
    Place('Porto-Novo', 'Porto-Novo', 6.4969, 2.6283),
  ];
}
