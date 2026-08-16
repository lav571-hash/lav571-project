import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../core/constants.dart';
import '../battle_controller.dart';
import '../map/tile.dart';
import '../units/tactical_unit.dart';
import 'battlefield_component.dart';

/// The Flame game hosting a single tactical battle. All gameplay state
/// lives in [controller]; this class only handles rendering + input and
/// notifies [onStateChanged] so the Flutter HUD overlay can rebuild.
class TacticalGame extends FlameGame {
  final BattleController controller;
  final VoidCallback onStateChanged;
  late final BattlefieldComponent battlefield;

  TacticalGame({required this.controller, required this.onStateChanged});

  @override
  Color backgroundColor() => const Color(0xFF06070C);

  @override
  Future<void> onLoad() async {
    battlefield = BattlefieldComponent(
      controller: controller,
      onTileTap: _handleTileTap,
    );
    await world.add(battlefield);

    final mapSize = Vector2(
      controller.map.width * GameConfig.tileSize,
      controller.map.height * GameConfig.tileSize,
    );
    camera.viewfinder.visibleGameSize = mapSize;
    camera.viewfinder.position = mapSize / 2;
    camera.viewfinder.anchor = Anchor.center;
  }

  void _handleTileTap(GridPos pos) {
    if (controller.phase != BattlePhase.playerTurn) return;

    TacticalUnit? unitAtPos;
    for (final u in controller.units) {
      if (u.isAlive && u.position == pos) {
        unitAtPos = u;
        break;
      }
    }

    final selected = controller.selectedUnit;

    if (selected != null &&
        controller.aimMode == TacticalAimMode.deployTurret) {
      controller.deployTurretAt(pos);
      onStateChanged();
      return;
    }

    if (selected != null &&
        controller.aimMode == TacticalAimMode.hack &&
        unitAtPos != null) {
      controller.hackTarget(unitAtPos.id);
      onStateChanged();
      return;
    }

    if (selected == null) {
      if (unitAtPos != null && unitAtPos.team == Team.player) {
        controller.selectUnit(unitAtPos.id);
      }
    } else {
      if (unitAtPos != null && unitAtPos.team == Team.enemy) {
        controller.attackTarget(unitAtPos.id);
      } else if (unitAtPos != null && unitAtPos.team == Team.player) {
        if (unitAtPos.id == selected.id) {
          controller.clearSelection();
        } else {
          controller.selectUnit(unitAtPos.id);
        }
      } else {
        controller.moveSelectedTo(pos);
      }
    }
    onStateChanged();
  }
}
