import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/wami_colors.dart';

/// Carte stylisée sombre avec le trajet lumineux.
///
/// C'est un *rendu de maquette*. En production, remplacer par une vraie carte
/// (google_maps_flutter avec un style sombre, ou flutter_map) — à valider.
/// [progress] (0 → 1) place le véhicule sur le trajet.
class RouteMapView extends StatelessWidget {
  const RouteMapView({super.key, this.progress, this.showRoute = true});

  final double? progress;
  final bool showRoute;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _MapPainter(progress: progress, showRoute: showRoute),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.progress, required this.showRoute});

  final double? progress;
  final bool showRoute;

  // Repère de conception : 360 × 460.
  static const _w = 360.0;
  static const _h = 460.0;
  static const _route = [Offset(70, 330), Offset(70, 250), Offset(210, 250), Offset(210, 140), Offset(300, 110)];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _w;
    final sy = size.height / _h;
    canvas.save();
    canvas.scale(sx, sy);

    canvas.drawRect(const Rect.fromLTWH(0, 0, _w, _h), Paint()..color = WamiColors.map);

    final block = Paint()..color = WamiColors.mapBlock;
    for (final r in const [
      Rect.fromLTWH(84, 152, 112, 84),
      Rect.fromLTWH(224, 152, 120, 84),
      Rect.fromLTWH(84, 264, 112, 90),
      Rect.fromLTWH(0, 152, 56, 84),
      Rect.fromLTWH(224, 264, 120, 90),
      Rect.fromLTWH(84, 20, 112, 106),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), block);
    }

    final lane = Paint()
      ..color = WamiColors.mapLane
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-20, 60), const Offset(380, 200), lane);
    canvas.drawLine(const Offset(0, 400), const Offset(360, 400), lane);
    canvas.drawLine(const Offset(140, 0), const Offset(140, 460), lane);

    final road = Paint()
      ..color = WamiColors.mapRoad
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    for (final y in const [140.0, 250.0, 340.0]) {
      canvas.drawLine(Offset(0, y), Offset(_w, y), road);
    }
    for (final x in const [70.0, 210.0]) {
      canvas.drawLine(Offset(x, 0), Offset(x, _h), road);
    }

    if (showRoute) _paintRoute(canvas);
    canvas.restore();
  }

  void _paintRoute(Canvas canvas) {
    final p = (progress ?? 0).clamp(0.0, 1.0);
    final split = _pointAt(p);

    final done = Path()..moveTo(_route.first.dx, _route.first.dy);
    for (var i = 1; i <= split.segment; i++) {
      done.lineTo(_route[i].dx, _route[i].dy);
    }
    done.lineTo(split.point.dx, split.point.dy);

    final rest = Path()..moveTo(split.point.dx, split.point.dy);
    for (var i = split.segment + 1; i < _route.length; i++) {
      rest.lineTo(_route[i].dx, _route[i].dy);
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(done, stroke..color = const Color(0x38FFFFFF)..strokeWidth = 5);
    canvas.drawPath(rest, stroke..color = const Color(0x47F25C05)..strokeWidth = 16);
    canvas.drawPath(
      rest,
      stroke
        ..strokeWidth = 5
        ..shader = ui.Gradient.linear(const Offset(70, 330), const Offset(300, 110), const [
          Color(0xFFFFB27A),
          WamiColors.orange,
        ]),
    );

    // Départ et arrivée.
    canvas.drawCircle(_route.first, 7, Paint()..color = Colors.white);
    _glow(canvas, _route.last, 24);
    canvas.drawCircle(_route.last, 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      _route.last,
      9,
      Paint()
        ..color = WamiColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    // Véhicule.
    if (progress != null) {
      _glow(canvas, split.point, 28);
      final car = RRect.fromRectAndRadius(Rect.fromCenter(center: split.point, width: 20, height: 20), const Radius.circular(7));
      canvas.drawRRect(car, Paint()..color = WamiColors.orangeLight);
      canvas.drawRRect(
        car,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _glow(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c, r, [
          WamiColors.orangeLight.withValues(alpha: 0.7),
          WamiColors.orangeLight.withValues(alpha: 0),
        ]),
    );
  }

  ({int segment, Offset point}) _pointAt(double t) {
    final lengths = <double>[];
    var total = 0.0;
    for (var i = 0; i < _route.length - 1; i++) {
      final l = (_route[i + 1] - _route[i]).distance;
      lengths.add(l);
      total += l;
    }
    var target = t * total;
    for (var i = 0; i < lengths.length; i++) {
      if (target <= lengths[i] || i == lengths.length - 1) {
        final f = lengths[i] == 0 ? 0.0 : (target / lengths[i]).clamp(0.0, 1.0);
        return (segment: i, point: Offset.lerp(_route[i], _route[i + 1], f)!);
      }
      target -= lengths[i];
    }
    return (segment: _route.length - 2, point: _route.last);
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.progress != progress || old.showRoute != showRoute;
}
