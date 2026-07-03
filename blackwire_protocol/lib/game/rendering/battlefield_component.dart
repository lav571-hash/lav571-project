import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../core/constants.dart';
import '../../data/models/faction.dart';
import '../battle_controller.dart';
import '../map/tile.dart';
import '../units/tactical_unit.dart';

typedef TileTapCallback = void Function(GridPos pos);

/// Renders the tactical grid (tiles, cover, fog of war), movement/attack
/// highlights and units, and converts taps into grid coordinates.
class BattlefieldComponent extends PositionComponent with TapCallbacks {
  final BattleController controller;
  final TileTapCallback onTileTap;

  BattlefieldComponent({required this.controller, required this.onTileTap}) {
    size = Vector2(
      controller.map.width * GameConfig.tileSize,
      controller.map.height * GameConfig.tileSize,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    final local = event.localPosition;
    final gx = (local.x / GameConfig.tileSize).floor();
    final gy = (local.y / GameConfig.tileSize).floor();
    onTileTap(GridPos(gx, gy));
  }

  @override
  void render(Canvas canvas) {
    _renderTiles(canvas);
    _renderHighlights(canvas);
    _renderUnits(canvas);
  }

  void _renderTiles(Canvas canvas) {
    const ts = GameConfig.tileSize;
    for (final pos in controller.map.allPositions) {
      final rect = Rect.fromLTWH(pos.x * ts, pos.y * ts, ts, ts);
      final explored = controller.isTileExplored(pos);
      final visible = controller.isTileVisible(pos);
      final type = controller.map.tileAt(pos);

      if (!explored) {
        canvas.drawRect(rect, Paint()..color = const Color(0xFF000000));
        continue;
      }

      Color base;
      switch (type) {
        case TileType.floor:
          base = const Color(0xFF1B2333);
        case TileType.wall:
          base = const Color(0xFF262C3B);
        case TileType.crate:
          base = const Color(0xFF1B2333);
      }
      if (!visible) {
        base = Color.lerp(base, const Color(0xFF000000), 0.65)!;
      }
      canvas.drawRect(rect.deflate(0.5), Paint()..color = base);

      if (type == TileType.crate) {
        final crateColor = visible
            ? const Color(0xFFB8862B)
            : const Color(0xFF4A3A1C);
        canvas.drawRect(rect.deflate(ts * 0.24), Paint()..color = crateColor);
      } else if (type == TileType.wall) {
        final edgeColor = visible
            ? const Color(0xFF0A0C12)
            : const Color(0xFF060709);
        canvas.drawRect(rect.deflate(2), Paint()..color = edgeColor);
      } else {
        // Subtle grid line on floor tiles.
        canvas.drawRect(
          rect,
          Paint()
            ..color = const Color(0x14FFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }
  }

  void _renderHighlights(Canvas canvas) {
    const ts = GameConfig.tileSize;
    if (controller.selectedUnit == null) return;

    final moveOptions = controller.movementOptionsForSelected();
    for (final pos in moveOptions.keys) {
      final rect = Rect.fromLTWH(pos.x * ts, pos.y * ts, ts, ts);
      canvas.drawRect(
        rect.deflate(3),
        Paint()..color = AppColors.neonCyan.withValues(alpha: 0.22),
      );
      canvas.drawRect(
        rect.deflate(3),
        Paint()
          ..color = AppColors.neonCyan.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final attackable = controller.attackableTargetsForSelected();
    for (final t in attackable) {
      final rect = Rect.fromLTWH(t.position.x * ts, t.position.y * ts, ts, ts);
      canvas.drawRect(
        rect.deflate(2),
        Paint()
          ..color = AppColors.danger
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _renderUnits(Canvas canvas) {
    const ts = GameConfig.tileSize;
    for (final unit in controller.units) {
      if (!unit.isAlive) continue;
      if (unit.team == Team.enemy && !controller.isEnemyVisible(unit)) continue;

      final center = Offset(
        unit.position.x * ts + ts / 2,
        unit.position.y * ts + ts / 2,
      );
      final color = unit.team == Team.player
          ? AppColors.neonCyan
          : (kFactionDefs[unit.enemyFactionId]?.color ?? AppColors.danger);
      final radius = ts * 0.32;

      if (controller.selectedUnitId == unit.id) {
        canvas.drawCircle(
          center,
          radius + 5,
          Paint()
            ..color = const Color(0xFFFFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      canvas.drawCircle(center, radius, Paint()..color = color);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0x99000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final barWidth = ts * 0.72;
      final barRect = Rect.fromLTWH(
        center.dx - barWidth / 2,
        center.dy - radius - 10,
        barWidth,
        5,
      );
      canvas.drawRect(barRect, Paint()..color = const Color(0x99000000));
      final hpFrac = unit.hpFraction.clamp(0.0, 1.0);
      final hpColor = hpFrac > 0.5
          ? AppColors.neonGreen
          : (hpFrac > 0.25 ? AppColors.neonYellow : AppColors.danger);
      canvas.drawRect(
        Rect.fromLTWH(barRect.left, barRect.top, barWidth * hpFrac, 5),
        Paint()..color = hpColor,
      );
    }
  }
}
