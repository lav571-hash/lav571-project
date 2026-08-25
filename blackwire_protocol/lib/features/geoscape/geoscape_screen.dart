import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/models/deployed_operation.dart';
import '../../data/models/faction.dart';
import '../../data/models/mission_result.dart';
import '../../data/models/mission_site.dart';
import '../../data/models/soldier.dart';
import '../../state/game_state_notifier.dart';
import '../tactical/tactical_screen.dart';

class GeoscapeScreen extends ConsumerStatefulWidget {
  const GeoscapeScreen({super.key});

  @override
  ConsumerState<GeoscapeScreen> createState() => _GeoscapeScreenState();
}

class _GeoscapeScreenState extends ConsumerState<GeoscapeScreen> {
  double _speed = 1;
  bool _paused = false;

  void _setSpeed(double speed) {
    setState(() {
      _speed = speed;
      _paused = false;
    });
    final notifier = ref.read(gameStateProvider.notifier);
    notifier.paused = false;
    notifier.setSpeed(speed);
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    ref.read(gameStateProvider.notifier).paused = _paused;
  }

  Future<void> _openMissionSheet(MissionSite mission) async {
    final save = ref.read(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);
    final available = save.soldiers.where(notifier.isSoldierAvailable).toList();
    final selected = await showModalBottomSheet<_MissionLaunchChoice>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => _MissionSheet(
        mission: mission,
        availableSoldiers: available,
        canAutoDeploy: notifier.canLaunchMission(),
      ),
    );
    if (selected == null || selected.soldierIds.isEmpty) return;
    if (!mounted) return;
    if (selected.autoDeploy) {
      final deployed = notifier.deployMission(mission, selected.soldierIds);
      if (mounted && !deployed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить операцию.')),
        );
      }
      return;
    }
    await _launchMission(mission, selected.soldierIds);
  }

  Future<void> _launchMission(
    MissionSite mission,
    List<String> soldierIds,
  ) async {
    final notifier = ref.read(gameStateProvider.notifier);
    final battle = notifier.launchMission(mission, soldierIds);
    final resultController = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TacticalScreen(controller: battle, mission: mission),
      ),
    );
    if (resultController == null || !mounted) return;

    final result = notifier.resolveMission(
      mission: mission,
      battle: battle,
      squadSoldierIds: soldierIds,
    );
    if (!mounted) return;
    await _showResultDialog(result);
  }

  Future<void> _showResultDialog(MissionResult result) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          result.victory ? 'МИССИЯ ВЫПОЛНЕНА' : 'МИССИЯ ПРОВАЛЕНА',
          style: TextStyle(
            color: result.victory ? AppColors.neonGreen : AppColors.danger,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Фракция: ${result.factionName}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (result.victory)
              Text(
                'Награда: ₡${result.loot.credits} · ⚙${result.loot.materials} · ◆${result.loot.data}',
                style: const TextStyle(color: AppColors.neonGreen),
              ),
            if (result.trophiesRecovered > 0)
              Text(
                'Трофеи разведки: ${result.trophiesRecovered}',
                style: const TextStyle(color: AppColors.neonCyan),
              ),
            if (result.wounded.isNotEmpty)
              Text(
                'Ранены: ${result.wounded.join(', ')}',
                style: const TextStyle(color: AppColors.neonYellow),
              ),
            if (result.killedInAction.isNotEmpty)
              Text(
                'Погибли: ${result.killedInAction.join(', ')}',
                style: const TextStyle(color: AppColors.danger),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(gameStateProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              const Text(
                'ГЕОСКЕЙП',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              _speedButton(Icons.pause, _paused, _togglePause),
              _speedButton(
                null,
                _speed == 1 && !_paused,
                () => _setSpeed(1),
                label: '1x',
              ),
              _speedButton(
                null,
                _speed == 2 && !_paused,
                () => _setSpeed(2),
                label: '2x',
              ),
              _speedButton(
                null,
                _speed == 4 && !_paused,
                () => _setSpeed(4),
                label: '4x',
              ),
            ],
          ),
        ),
        SizedBox(
          height: 112,
          child: _OperationsPanel(
            operations: save.deployedOperations,
            reports: save.operationReports,
            usedSlots: save.deployedOperations.length,
            totalSlots: save.base.parallelMissionSlots,
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _GeoMap(
              missions: save.activeMissions,
              onTapMission: _openMissionSheet,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: EnemyFactionId.values.map((f) {
              final threat = save.factionThreats.firstWhere(
                (t) => t.factionId == f,
              );
              final def = kFactionDefs[f]!;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Text(
                        def.name,
                        style: TextStyle(color: def.color, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (threat.threatLevel / 100).clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: Colors.black45,
                          color: def.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          flex: 2,
          child: save.activeMissions.isEmpty
              ? const Center(
                  child: Text(
                    'Нет активных миссий. Ожидайте сигналов о новых инцидентах...',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: save.activeMissions.length,
                  itemBuilder: (context, i) {
                    final m = save.activeMissions[i];
                    final def = kFactionDefs[m.factionId]!;
                    return Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.warning_amber, color: def.color),
                        title: Text(
                          '${m.regionName} · ${kMissionTypeNames[m.type]}',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          '${def.name} · сложность ${m.difficulty} · осталось ${(m.secondsRemaining).toInt()}с',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _openMissionSheet(m),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonMagenta,
                          ),
                          child: const Text('Отряд'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _speedButton(
    IconData? icon,
    bool active,
    VoidCallback onTap, {
    String? label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? AppColors.neonCyan.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: active ? AppColors.neonCyan : AppColors.textSecondary,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: icon != null
              ? Icon(
                  icon,
                  size: 14,
                  color: active ? AppColors.neonCyan : AppColors.textSecondary,
                )
              : Text(
                  label!,
                  style: TextStyle(
                    color: active
                        ? AppColors.neonCyan
                        : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OperationsPanel extends ConsumerWidget {
  final List<DeployedOperation> operations;
  final List<OperationReport> reports;
  final int usedSlots;
  final int totalSlots;

  const _OperationsPanel({
    required this.operations,
    required this.reports,
    required this.usedSlots,
    required this.totalSlots,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <Widget>[
      ...operations.map((operation) {
        final progress =
            1 - operation.secondsRemaining / operation.totalDurationSeconds;
        final faction = kFactionDefs[operation.mission.factionId]!;
        return Container(
          width: 250,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: faction.color),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${operation.mission.regionName} · ${operation.soldierIds.length} бойц.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${faction.name} · ${operation.secondsRemaining.ceil()}с',
                style: TextStyle(color: faction.color, fontSize: 10),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 5,
                color: AppColors.neonCyan,
                backgroundColor: Colors.black45,
              ),
            ],
          ),
        );
      }),
      ...reports.map((report) {
        final color = report.victory ? AppColors.neonGreen : AppColors.danger;
        return Container(
          width: 270,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              Icon(
                report.victory ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      report.victory
                          ? 'ОПЕРАЦИЯ УСПЕШНА'
                          : 'ОПЕРАЦИЯ ПРОВАЛЕНА',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${report.regionName} · ₡${report.loot.credits} ◆${report.loot.data}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Закрыть отчёт',
                onPressed: () => ref
                    .read(gameStateProvider.notifier)
                    .dismissOperationReport(report.id),
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      }),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'АНГАР: ОПЕРАЦИИ $usedSlots/$totalSlots',
            style: const TextStyle(
              color: AppColors.neonCyan,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: items.isEmpty
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Нет активных операций. Выберите миссию и отправьте отряд.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  )
                : ListView(scrollDirection: Axis.horizontal, children: items),
          ),
        ],
      ),
    );
  }
}

class _GeoMap extends StatelessWidget {
  final List<MissionSite> missions;
  final void Function(MissionSite) onTapMission;

  const _GeoMap({required this.missions, required this.onTapMission});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1220),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceAlt),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _GridPainter(),
              ),
              for (final m in missions)
                Positioned(
                  left: m.x * constraints.maxWidth - 14,
                  top: m.y * constraints.maxHeight - 14,
                  child: GestureDetector(
                    onTap: () => onTapMission(m),
                    child: _MissionMarker(mission: m),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MissionMarker extends StatelessWidget {
  final MissionSite mission;
  const _MissionMarker({required this.mission});

  @override
  Widget build(BuildContext context) {
    final def = kFactionDefs[mission.factionId]!;
    final urgency = mission.secondsRemaining / mission.totalLifetimeSeconds;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: def.color.withValues(alpha: 0.25),
            border: Border.all(color: def.color, width: 2),
          ),
          child: Icon(Icons.priority_high, size: 16, color: def.color),
        ),
        SizedBox(
          width: 28,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: urgency.clamp(0, 1),
              minHeight: 3,
              color: def.color,
              backgroundColor: Colors.black45,
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1400E5FF)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MissionLaunchChoice {
  final List<String> soldierIds;
  final bool autoDeploy;

  const _MissionLaunchChoice({
    required this.soldierIds,
    required this.autoDeploy,
  });
}

class _MissionSheet extends StatefulWidget {
  final MissionSite mission;
  final List<Soldier> availableSoldiers;
  final bool canAutoDeploy;

  const _MissionSheet({
    required this.mission,
    required this.availableSoldiers,
    required this.canAutoDeploy,
  });

  @override
  State<_MissionSheet> createState() => _MissionSheetState();
}

class _MissionSheetState extends State<_MissionSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final def = kFactionDefs[widget.mission.factionId]!;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.mission.regionName} · ${kMissionTypeNames[widget.mission.type]}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${def.name} · сложность ${widget.mission.difficulty}',
            style: TextStyle(color: def.color, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text(
            'Выберите отряд (макс. 4):',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          if (widget.availableSoldiers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Нет доступных бойцов. Наймите или дождитесь выздоровления.',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView(
              shrinkWrap: true,
              children: widget.availableSoldiers.map((s) {
                final checked = _selected.contains(s.id);
                return CheckboxListTile(
                  value: checked,
                  activeColor: AppColors.neonCyan,
                  title: Text(
                    s.name,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    'HP ${s.currentHp}/${s.maxHp}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        if (_selected.length < GameConfig.maxSquadSize) {
                          _selected.add(s.id);
                        }
                      } else {
                        _selected.remove(s.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(
                      _MissionLaunchChoice(
                        soldierIds: _selected.toList(),
                        autoDeploy: false,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonMagenta,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'ВОЗГЛАВИТЬ МИССИЮ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _selected.isEmpty || !widget.canAutoDeploy
                  ? null
                  : () => Navigator.of(context).pop(
                      _MissionLaunchChoice(
                        soldierIds: _selected.toList(),
                        autoDeploy: true,
                      ),
                    ),
              icon: const Icon(Icons.flight_takeoff, size: 18),
              label: Text(
                widget.canAutoDeploy
                    ? 'ОТПРАВИТЬ ЧЕРЕЗ АНГАР'
                    : 'НЕТ СВОБОДНЫХ СЛОТОВ АНГАРА',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
