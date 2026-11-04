import 'package:flutter/material.dart';
import 'package:wami_core/wami_core.dart';

/// Activités qu'un établissement peut exercer sur WAMI.
enum BusinessActivity {
  restaurant('Restaurant', 'Commandes à préparer, livrées par WAMI', Icons.restaurant_rounded, null),
  hotel('Hôtel', 'Réservations de chambres et check-in', Icons.hotel_rounded, ServiceArt.hotel),
  rooms('Chambres', 'Quelques chambres louées à la nuit', Icons.bed_rounded, ServiceArt.chambre),
  apartments('Maisons et appartements', 'Location longue durée et visites', Icons.apartment_rounded, ServiceArt.appartement),
  busCompany('Compagnie de bus', 'Départs, places, embarquement', Icons.directions_bus_rounded, ServiceArt.bus);

  const BusinessActivity(this.label, this.hint, this.icon, this.art);
  final String label;
  final String hint;
  final IconData icon;
  final ServiceArt? art;

  /// Famille d'écrans : décide ce qu'affichent les onglets « Activité » et « Offre ».
  ActivityFamily get family => switch (this) {
        BusinessActivity.restaurant => ActivityFamily.food,
        BusinessActivity.hotel || BusinessActivity.rooms => ActivityFamily.lodging,
        BusinessActivity.apartments => ActivityFamily.rental,
        BusinessActivity.busCompany => ActivityFamily.transport,
      };
}

enum ActivityFamily {
  food('Commandes', 'Menu'),
  lodging('Planning', 'Chambres'),
  rental('Visites', 'Biens'),
  transport('Départs', 'Lignes');

  const ActivityFamily(this.activityTab, this.offerTab);
  final String activityTab;
  final String offerTab;
}
