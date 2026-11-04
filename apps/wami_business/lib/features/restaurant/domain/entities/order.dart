import 'package:equatable/equatable.dart';

enum OrderStatus {
  incoming('Nouvelle'),
  kitchen('En cuisine'),
  ready('Prête'),
  pickedUp('Récupérée'),
  rejected('Refusée');

  const OrderStatus(this.label);
  final String label;
}

class OrderLine extends Equatable {
  const OrderLine({required this.name, required this.quantity, required this.unitPrice, this.note});
  final String name;
  final int quantity;
  final int unitPrice;
  final String? note;

  int get total => quantity * unitPrice;

  @override
  List<Object?> get props => [name, quantity, unitPrice, note];
}

/// Règles de préparation communes à toutes les commandes.
abstract final class PrepRules {
  static const minMinutes = 5;
  static const maxMinutes = 90;
  static const extensionMinutes = 5;

  /// Au-delà, il faut prévenir le client autrement (à valider : appel du support ?).
  static const maxExtensions = 2;

  /// Délai pour accepter une nouvelle commande avant expiration (à valider).
  static const acceptWindowSeconds = 180;

  static const presets = [10, 15, 20, 30, 45];
}

class FoodOrder extends Equatable {
  const FoodOrder({
    required this.id,
    required this.number,
    required this.customerName,
    required this.lines,
    required this.placedAt,
    this.status = OrderStatus.incoming,
    this.prepMinutes,
    this.acceptedAt,
    this.extensions = 0,
    this.readyAt,
    this.courierName,
    this.rejectReason,
  });

  final String id;
  final String number;
  final String customerName;
  final List<OrderLine> lines;
  final DateTime placedAt;
  final OrderStatus status;
  final int? prepMinutes;
  final DateTime? acceptedAt;
  final int extensions;
  final DateTime? readyAt;

  /// Livreur WAMI assigné, une fois la commande prête.
  final String? courierName;
  final String? rejectReason;

  int get total => lines.fold(0, (s, l) => s + l.total);
  int get itemCount => lines.fold(0, (s, l) => s + l.quantity);

  /// Heure à laquelle la commande doit être prête.
  DateTime? get dueAt => acceptedAt?.add(Duration(minutes: (prepMinutes ?? 0) + extensions * PrepRules.extensionMinutes));

  /// Secondes restantes avant l'heure promise (négatif : en retard).
  int remainingSeconds(DateTime now) => dueAt == null ? 0 : dueAt!.difference(now).inSeconds;

  /// Secondes restantes pour accepter une nouvelle commande.
  int acceptSecondsLeft(DateTime now) => PrepRules.acceptWindowSeconds - now.difference(placedAt).inSeconds;

  bool get canExtend => status == OrderStatus.kitchen && extensions < PrepRules.maxExtensions;

  FoodOrder copyWith({
    OrderStatus? status,
    int? prepMinutes,
    DateTime? acceptedAt,
    int? extensions,
    DateTime? readyAt,
    String? courierName,
    String? rejectReason,
  }) {
    return FoodOrder(
      id: id,
      number: number,
      customerName: customerName,
      lines: lines,
      placedAt: placedAt,
      status: status ?? this.status,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      extensions: extensions ?? this.extensions,
      readyAt: readyAt ?? this.readyAt,
      courierName: courierName ?? this.courierName,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }

  @override
  List<Object?> get props =>
      [id, number, customerName, lines, placedAt, status, prepMinutes, acceptedAt, extensions, readyAt, courierName, rejectReason];
}

class MenuItem extends Equatable {
  const MenuItem({required this.id, required this.name, required this.category, required this.price, this.available = true});
  final String id;
  final String name;
  final String category;
  final int price;
  final bool available;

  MenuItem copyWith({bool? available}) =>
      MenuItem(id: id, name: name, category: category, price: price, available: available ?? this.available);

  @override
  List<Object?> get props => [id, name, category, price, available];
}

class RestaurantMenu extends Equatable {
  const RestaurantMenu({required this.items, required this.paused, required this.hours});
  final List<MenuItem> items;

  /// Pause : plus de nouvelles commandes, sans fermer l'établissement.
  final bool paused;
  final String hours;

  /// Catégories dans l'ordre d'apparition.
  List<String> get categories => [for (final i in items) i.category].toSet().toList();

  RestaurantMenu copyWith({List<MenuItem>? items, bool? paused}) =>
      RestaurantMenu(items: items ?? this.items, paused: paused ?? this.paused, hours: hours);

  @override
  List<Object?> get props => [items, paused, hours];
}
