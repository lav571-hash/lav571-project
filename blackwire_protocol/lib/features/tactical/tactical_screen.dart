import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/faction.dart';
import '../../data/models/mission_site.dart';
import '../../game/battle_controller.dart';
import '../../game/rendering/tactical_game.dart';
import '../../game/units/tactical_unit.dart';

class TacticalScreen extends StatefulWidget {
  final BattleController controller;
  final MissionSite mission;

  const TacticalScreen({
    super.key,
    required this.controller,
    required this.mission,
  });

  @override
  State<TacticalScreen> createState() => _TacticalScreenState();
}

class _TacticalScreenState extends State<TacticalScreen> {
  late final TacticalGame _game;
  bool _resultReturned = false;

  @override
  void initState() {
    super.initState();
    _game = TacticalGame(
      controller: widget.controller,
      onStateChanged: () => setState(() {}),
    );
  }

  BattleController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final faction = kFactionDefs[widget.mission.factionId]!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(faction),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: GameWidget(game: _game)),
                  if (controller.phase == BattlePhase.victory ||
                      controller.phase == BattlePhase.defeat)
                    _buildEndOverlay(),
                ],
              ),
            ),
            _buildBottomHud(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(FactionDef faction) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(Icons.gps_fixed, color: faction.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.mission.regionName} · ${kMissionTypeNames[widget.mission.type]} · ${faction.name}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            controller.phase == BattlePhase.enemyTurn
                ? 'ХОД ПРОТИВНИКА'
                : 'ХОД ${controller.turnNumber}',
            style: const TextStyle(
              color: AppColors.neonCyan,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomHud() {
    final selected = controller.selectedUnit;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 78,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: controller.playerUnits
                  .map((u) => _unitChip(u))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          if (selected != null) _buildSelectedUnitPanel(selected),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildLog()),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: controller.phase == BattlePhase.playerTurn
                    ? () => setState(() => controller.endPlayerTurn())
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonMagenta,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'ЗАКОНЧИТЬ ХОД',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unitChip(TacticalUnit u) {
    final selected = controller.selectedUnitId == u.id;
    final canAct =
        u.isAlive && u.canAct && controller.phase == BattlePhase.playerTurn;
    return GestureDetector(
      onTap: canAct
          ? () => setState(() => controller.selectUnit(u.id))
          : (u.isAlive
                ? () => setState(() => controller.selectUnit(u.id))
                : null),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: u.isAlive ? AppColors.surfaceAlt : Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.neonCyan : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              u.displayName,
              style: TextStyle(
                color: u.isAlive
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: u.isAlive ? null : TextDecoration.lineThrough,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: u.isAlive ? u.hpFraction.clamp(0, 1) : 0,
                minHeight: 5,
                backgroundColor: Colors.black45,
                color: !u.isAlive
                    ? AppColors.danger
                    : (u.hpFraction > 0.5
                          ? AppColors.neonGreen
                          : AppColors.neonYellow),
              ),
            ),
            if (u.isAlive && !canAct)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'ход завершён',
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUnitPanel(TacticalUnit unit) {
    final canMove =
        !unit.hasMoved && controller.phase == BattlePhase.playerTurn;
    final canAttack =
        !unit.hasActed && controller.phase == BattlePhase.playerTurn;
    final targets = controller.attackableTargetsForSelected();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${unit.displayName} · ${unit.weapon.name} · HP ${unit.currentHp}/${unit.maxHp}'
              '${canMove ? ' · можно двигаться' : ''}'
              '${canAttack ? (targets.isNotEmpty ? ' · есть цель в зоне поражения' : '') : ''}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => controller.skipSelectedUnit()),
            child: const Text(
              'Пропустить',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLog() {
    final entries = controller.log.reversed.take(3).toList();
    return SizedBox(
      height: 56,
      child: ListView(
        reverse: true,
        physics: const NeverScrollableScrollPhysics(),
        children: entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  e.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEndOverlay() {
    final victory = controller.phase == BattlePhase.victory;
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              victory ? 'МИССИЯ ВЫПОЛНЕНА' : 'МИССИЯ ПРОВАЛЕНА',
              style: TextStyle(
                color: victory ? AppColors.neonGreen : AppColors.danger,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resultReturned
                  ? null
                  : () {
                      _resultReturned = true;
                      Navigator.of(context).pop(controller);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'ВЕРНУТЬСЯ НА БАЗУ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
