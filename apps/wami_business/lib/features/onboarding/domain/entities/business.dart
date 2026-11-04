import 'package:equatable/equatable.dart';

enum BusinessStatus { newcomer, verifying, active, suspended }

class BusinessSession extends Equatable {
  const BusinessSession({required this.phone, required this.status, this.businessName});
  final String phone;
  final BusinessStatus status;
  final String? businessName;

  @override
  List<Object?> get props => [phone, status, businessName];
}

enum ChecklistState {
  todo('À fournir'),
  sent('En vérification'),
  approved('Validé'),
  rejected('À refaire');

  const ChecklistState(this.label);
  final String label;

  bool get needsAction => this == todo || this == rejected;
}

/// Une pièce ou une étape de la vérification de l'établissement.
class ChecklistItem extends Equatable {
  const ChecklistItem({required this.id, required this.label, required this.hint, this.state = ChecklistState.todo, this.rejectReason});
  final String id;
  final String label;
  final String hint;
  final ChecklistState state;
  final String? rejectReason;

  ChecklistItem copyWith({ChecklistState? state}) => ChecklistItem(id: id, label: label, hint: hint, state: state ?? this.state);

  @override
  List<Object?> get props => [id, label, hint, state, rejectReason];
}

class VerificationChecklist extends Equatable {
  const VerificationChecklist(this.items);
  final List<ChecklistItem> items;

  int get approvedCount => items.where((i) => i.state == ChecklistState.approved).length;
  double get progress => items.isEmpty ? 0 : approvedCount / items.length;

  /// Toutes les pièces sont validées : le compte peut être activé.
  bool get isComplete => items.isNotEmpty && approvedCount == items.length;

  @override
  List<Object?> get props => [items];
}
