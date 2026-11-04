/// Illustrations 3D du design system (assets du paquet wami_core).
enum ServiceArt {
  moto('moto', 'Moto'),
  auto('auto', 'Voiture'),
  colis('colis', 'Colis'),
  bus('bus', 'Bus'),
  hotel('hotel', 'Hôtel'),
  chambre('chambre', 'Chambre'),
  appartement('appartement', 'Appartement');

  const ServiceArt(this.file, this.label);
  final String file;
  final String label;

  String get assetPath => 'assets/illustrations/illustration-$file.svg';
}
