import 'package:image_picker/image_picker.dart';

/// Prise de photo (caméra) ou choix dans la galerie. Renvoie le chemin du
/// fichier, ou `null` si l'utilisateur annule.
abstract final class PhotoPicker {
  static final _picker = ImagePicker();

  static Future<String?> camera() async =>
      (await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 80))?.path;

  static Future<String?> gallery() async =>
      (await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80))?.path;
}
