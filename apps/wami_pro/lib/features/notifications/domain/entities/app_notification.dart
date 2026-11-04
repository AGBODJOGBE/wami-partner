import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  const AppNotification({required this.id, required this.message, required this.createdAt, required this.read, this.type = ''});
  final String id;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String type;

  AppNotification markRead() => AppNotification(id: id, message: message, createdAt: createdAt, read: true, type: type);

  @override
  List<Object?> get props => [id, message, createdAt, read, type];
}
