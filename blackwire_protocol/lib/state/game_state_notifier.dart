import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../data/content/equipment_catalog.dart';
import '../data/content/research_catalog.dart';
import '../data/content/skill_catalog.dart';
import '../data/models/deployed_operation.dart';
import '../data/models/faction.dart';
import '../data/models/game_save.dart';
import '../data/models/mission_result.dart';
import '../data/models/mission_site.dart';
import '../data/models/research.dart';
import '../data/models/resources.dart';
import '../data/models/skill.dart';
import '../data/models/soldier.dart';
import '../data/models/specialization.dart';
import '../data/repositories/save_repository.dart';
import '../game/auto_operation_resolver.dart';
import '../game/battle_controller.dart';
import '../game/battle_factory.dart';
import '../game/geoscape/mission_generator.dart';
import '../game/soldier_progression.dart';

class FacilityCosts {
  static const Map<String, int> creditCostPerLevel = {
    'barracks': 200,
    'workshop': 250,
    'lab': 250,
    'hangar': 300,
    'warehouse': 180,
    'medbay': 220,
    'intelCenter': 240,
  };
  static const Map<String, int> materialCostPerLevel = {
    'barracks': 20,
    'workshop': 30,
    'lab': 25,
    'hangar': 35,
    'warehouse': 15,
    'medbay': 20,
    'intelCenter': 25,
  };

  static int creditsFor(String facilityId, int nextLevel) =>
      (creditCostPerLevel[facilityId] ?? 200) * nextLevel;
  static int materialsFor(String facilityId, int nextLevel) =>
      (materialCostPerLevel[facilityId] ?? 20) * nextLevel;
}

class GameStateNotifier extends Notifier<GameSave> {
  final SaveRepository _repository = SaveRepository();
  final Random _random = Random();
  Timer? _ticker;
  double gameSpeed = 1.0;
  bool paused = false;

  @override
  GameSave build() {
    ref.onDispose(() => _ticker?.cancel());
    return GameSave.newGame();
  }

  void loadSave(GameSave save) {
    state = save;
  }

  Future<void> startNewGame() async {
    var save = GameSave.newGame();
    final starters = List.generate(
      GameConfig.maxSquadSize,
      (_) => Soldier.generateRandom(_random),
    );
    save = save.copyWith(soldiers: starters);
    state = save;
    await _persist();
    _startTicker();
  }

  Future<void> resumeGame() async {
    final loaded = await _repository.load();
    if (loaded != null) {
      state = loaded;
    } else {
      await startNewGame();
      return;
    }
    _startTicker();
  }

  Future<void> _persist() => _repository.save(state);

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (paused || state.gameOver) return;
      tick(0.25 * gameSpeed);
    });
  }

  void setSpeed(double speed) => gameSpeed = speed;
  void togglePause() => paused = !paused;

  void tick(double dtSeconds) {
    if (state.gameOver) return;

    // Faction threat growth.
    final updatedThreats = state.factionThreats
        .map(
          (f) => f.copyWith(
            threatLevel:
                (f.threatLevel +
                        dtSeconds * GameConfig.factionThreatGrowthPerSecond)
                    .clamp(0, 100),
          ),
        )
        .toList();
    final avgThreat =
        updatedThreats.fold<double>(0, (sum, f) => sum + f.threatLevel) /
        updatedThreats.length;
    final newChaos =
        (state.chaosLevel +
                dtSeconds * (avgThreat / 100) * GameConfig.chaosGrowthFactor)
            .clamp(0, 100)
            .toDouble();

    // Mission expiry & spawning.
    final missions = state.activeMissions
        .map(
          (m) => m.copyWith(secondsRemaining: m.secondsRemaining - dtSeconds),
        )
        .where((m) => !m.isExpired)
        .toList();

    final newElapsed = state.elapsedGameSeconds + dtSeconds;
    final shouldSpawn =
        missions.length < GameConfig.maxActiveMissions &&
        _random.nextDouble() <
            dtSeconds / GameConfig.meanSecondsBetweenMissions;
    if (shouldSpawn) {
      missions.add(MissionGenerator.generate(_random));
    }

    final completedOperations = <DeployedOperation>[];
    final deployedOperations = state.deployedOperations
        .map((operation) {
          final remaining = operation.secondsRemaining - dtSeconds;
          if (remaining <= 0) {
            completedOperations.add(operation);
            return null;
          }
          return operation.copyWith(secondsRemaining: remaining);
        })
        .whereType<DeployedOperation>()
        .toList();

    // Soldier recovery.
    final daysPassed =
        dtSeconds /
        GameConfig.secondsPerGameDay *
        state.base.recoverySpeedMultiplier;
    final updatedSoldiers = state.soldiers.map((s) {
      if (s.status == SoldierStatus.wounded) {
        final remaining = s.recoveryDaysLeft - daysPassed;
        if (remaining <= 0) {
          return s.copyWith(
            status: SoldierStatus.active,
            recoveryDaysLeft: 0,
            currentHp: s.maxHp,
          );
        }
        return s.copyWith(recoveryDaysLeft: remaining);
      }
      return s;
    }).toList();

    final gameOver = newChaos >= GameConfig.chaosGameOverThreshold;

    state = state.copyWith(
      factionThreats: updatedThreats,
      chaosLevel: newChaos,
      activeMissions: missions,
      elapsedGameSeconds: newElapsed,
      soldiers: updatedSoldiers,
      deployedOperations: deployedOperations,
      gameOver: gameOver,
      victory: false,
    );

    for (final operation in completedOperations) {
      _completeDeployedOperation(operation);
    }

    if (state.gameOver) {
      _ticker?.cancel();
    }

    if (newElapsed.toInt() % 8 == 0) {
      unawaited(_persist());
    }
  }

  // ---------------------------------------------------------------------
  // Roster
  // ---------------------------------------------------------------------

  int get hireCost => 120 + state.soldiers.length * 35;

  bool hireSoldier() {
    if (state.soldiers.length >= state.base.rosterCapacity) return false;
    if (state.resources.credits < hireCost) return false;
    final newSoldier = Soldier.generateRandom(_random);
    state = state.copyWith(
      resources: state.resources.copyWith(
        credits: state.resources.credits - hireCost,
      ),
      soldiers: [...state.soldiers, newSoldier],
    );
    unawaited(_persist());
    return true;
  }

  void equipSoldier(String soldierId, {String? weaponId, String? armorId}) {
    final soldiers = [...state.soldiers];
    final index = soldiers.indexWhere((s) => s.id == soldierId);
    if (index == -1) return;
    final soldier = soldiers[index];
    if (deployedSoldierIds.contains(soldier.id)) return;

    final weaponStock = Map<String, int>.from(state.weaponStock);
    final armorStock = Map<String, int>.from(state.armorStock);

    if (weaponId != null && weaponId != soldier.weaponId) {
      if ((weaponStock[weaponId] ?? 0) <= 0 && weaponId != 'pistol_mk1') return;
      if (weaponId != 'pistol_mk1') {
        weaponStock[weaponId] = (weaponStock[weaponId] ?? 0) - 1;
      }
      if (soldier.weaponId != 'pistol_mk1') {
        weaponStock[soldier.weaponId] =
            (weaponStock[soldier.weaponId] ?? 0) + 1;
      }
      soldiers[index] = soldier.copyWith(weaponId: weaponId);
    }

    if (armorId != null && armorId != soldiers[index].armorId) {
      if ((armorStock[armorId] ?? 0) <= 0) return;
      armorStock[armorId] = (armorStock[armorId] ?? 0) - 1;
      final prevArmor = soldiers[index].armorId;
      if (prevArmor != null) {
        armorStock[prevArmor] = (armorStock[prevArmor] ?? 0) + 1;
      }
      soldiers[index] = soldiers[index].copyWith(armorId: armorId);
    }

    state = state.copyWith(
      soldiers: soldiers,
      weaponStock: weaponStock,
      armorStock: armorStock,
    );
    unawaited(_persist());
  }

  // ---------------------------------------------------------------------
  // Rank progression: specialization & skill choices
  // ---------------------------------------------------------------------

  List<Soldier> get soldiersWithPendingPromotion =>
      state.soldiers.where((s) => s.hasPendingPromotion).toList();

  bool chooseSpecialization(String soldierId, Specialization specialization) {
    final soldiers = [...state.soldiers];
    final index = soldiers.indexWhere((s) => s.id == soldierId);
    if (index == -1) return false;
    final soldier = soldiers[index];
    if (!soldier.hasPendingSpecializationChoice) return false;

    soldiers[index] = soldier.copyWith(specialization: specialization);
    state = state.copyWith(soldiers: soldiers);
    unawaited(_persist());
    return true;
  }

  /// The 2 skill options currently offered to [soldier], or an empty list
  /// if they have no pending skill choice.
  List<SkillDef> skillChoicesFor(Soldier soldier) {
    if (!soldier.hasPendingSkillChoice || soldier.specialization == null) {
      return const [];
    }
    final nextSkillRank = soldier.unlockedSkillIds.length + 2;
    return SkillCatalog.choicesForRank(soldier.specialization!, nextSkillRank);
  }

  bool chooseSkill(String soldierId, String skillId) {
    final soldiers = [...state.soldiers];
    final index = soldiers.indexWhere((s) => s.id == soldierId);
    if (index == -1) return false;
    final soldier = soldiers[index];
    final options = skillChoicesFor(soldier);
    if (options.isEmpty || !options.any((s) => s.id == skillId)) return false;

    soldiers[index] = soldier.copyWith(
      unlockedSkillIds: [...soldier.unlockedSkillIds, skillId],
    );
    state = state.copyWith(soldiers: soldiers);
    unawaited(_persist());
    return true;
  }

  // ---------------------------------------------------------------------
  // Base facilities
  // ---------------------------------------------------------------------

  int currentLevel(String facilityId) => switch (facilityId) {
    'barracks' => state.base.barracksLevel,
    'workshop' => state.base.workshopLevel,
    'lab' => state.base.labLevel,
    'hangar' => state.base.hangarLevel,
    'warehouse' => state.base.warehouseLevel,
    'medbay' => state.base.medbayLevel,
    'intelCenter' => state.base.intelCenterLevel,
    _ => 1,
  };

  bool upgradeFacility(String facilityId) {
    if (!FacilityCosts.creditCostPerLevel.containsKey(facilityId)) return false;
    final nextLevel = currentLevel(facilityId) + 1;
    final creditCost = FacilityCosts.creditsFor(facilityId, nextLevel);
    final materialCost = FacilityCosts.materialsFor(facilityId, nextLevel);
    if (state.resources.credits < creditCost ||
        state.resources.materials < materialCost) {
      return false;
    }
    final newBase = switch (facilityId) {
      'barracks' => state.base.copyWith(barracksLevel: nextLevel),
      'workshop' => state.base.copyWith(workshopLevel: nextLevel),
      'lab' => state.base.copyWith(labLevel: nextLevel),
      'hangar' => state.base.copyWith(hangarLevel: nextLevel),
      'warehouse' => state.base.copyWith(warehouseLevel: nextLevel),
      'medbay' => state.base.copyWith(medbayLevel: nextLevel),
      'intelCenter' => state.base.copyWith(intelCenterLevel: nextLevel),
      _ => state.base,
    };
    state = state.copyWith(
      base: newBase,
      resources: state.resources.copyWith(
        credits: state.resources.credits - creditCost,
        materials: state.resources.materials - materialCost,
      ),
    );
    unawaited(_persist());
    return true;
  }

  int trophyCount(EnemyFactionId factionId) =>
      state.intelTrophies[factionId.name] ?? 0;

  int intelYieldFor(EnemyFactionId factionId) {
    final factionBaseYield = switch (factionId) {
      EnemyFactionId.titanDynamics => 4,
      EnemyFactionId.nexusRobotics => 6,
      EnemyFactionId.chimeraLabs => 5,
    };
    return factionBaseYield +
        state.base.intelCenterLevel * GameConfig.intelDataPerFacilityLevel;
  }

  bool canProcessTrophy(EnemyFactionId factionId) =>
      trophyCount(factionId) > 0 &&
      state.resources.data + intelYieldFor(factionId) <=
          state.base.resourceStorageCap;

  bool processIntelTrophy(EnemyFactionId factionId) {
    if (!canProcessTrophy(factionId)) return false;

    final trophies = Map<String, int>.from(state.intelTrophies);
    final remaining = trophyCount(factionId) - 1;
    if (remaining == 0) {
      trophies.remove(factionId.name);
    } else {
      trophies[factionId.name] = remaining;
    }
    state = state.copyWith(
      intelTrophies: trophies,
      resources: state.resources.copyWith(
        data: state.resources.data + intelYieldFor(factionId),
      ),
    );
    unawaited(_persist());
    return true;
  }

  int intensiveCareCost(Soldier soldier) =>
      GameConfig.intensiveCareBaseCost +
      soldier.recoveryDaysLeft.ceil() *
          GameConfig.intensiveCareCostPerRecoveryDay;

  bool provideIntensiveCare(String soldierId) {
    final soldiers = [...state.soldiers];
    final index = soldiers.indexWhere((s) => s.id == soldierId);
    if (index == -1) return false;

    final soldier = soldiers[index];
    if (soldier.status != SoldierStatus.wounded) return false;
    final cost = intensiveCareCost(soldier);
    if (state.resources.credits < cost) return false;

    final remaining = soldier.recoveryDaysLeft - state.base.intensiveCareDays;
    soldiers[index] = remaining <= 0
        ? soldier.copyWith(
            status: SoldierStatus.active,
            currentHp: soldier.maxHp,
            recoveryDaysLeft: 0,
          )
        : soldier.copyWith(recoveryDaysLeft: remaining);
    state = state.copyWith(
      soldiers: soldiers,
      resources: state.resources.copyWith(
        credits: state.resources.credits - cost,
      ),
    );
    unawaited(_persist());
    return true;
  }

  // ---------------------------------------------------------------------
  // Research & crafting
  // ---------------------------------------------------------------------

  bool canResearch(String nodeId) {
    if (state.completedResearchIds.contains(nodeId)) return false;
    final node = kResearchTree.firstWhere((n) => n.id == nodeId);
    final prereqsDone = node.prerequisites.every(
      state.completedResearchIds.contains,
    );
    return prereqsDone && state.resources.data >= node.dataCost;
  }

  bool completeResearch(String nodeId) {
    if (!canResearch(nodeId)) return false;
    final node = kResearchTree.firstWhere((n) => n.id == nodeId);

    final completed = {...state.completedResearchIds, nodeId};
    var weapons = state.unlockedWeaponIds;
    var armors = state.unlockedArmorIds;
    var abilities = state.unlockedAbilityIds;

    switch (node.unlockType) {
      case ResearchUnlockType.weapon:
        weapons = {...weapons, node.unlockId};
      case ResearchUnlockType.armor:
        armors = {...armors, node.unlockId};
      case ResearchUnlockType.ability:
        abilities = {...abilities, node.unlockId};
    }

    state = state.copyWith(
      completedResearchIds: completed,
      unlockedWeaponIds: weapons,
      unlockedArmorIds: armors,
      unlockedAbilityIds: abilities,
      resources: state.resources.copyWith(
        data: state.resources.data - node.dataCost,
      ),
    );
    unawaited(_persist());
    return true;
  }

  int craftCost(String itemId, {required bool isWeapon}) {
    final tier = isWeapon
        ? (kWeaponCatalog[itemId]?.tier ?? 1)
        : (kArmorCatalog[itemId]?.tier ?? 1);
    return 15 * tier;
  }

  bool craftWeapon(String weaponId) {
    if (!state.unlockedWeaponIds.contains(weaponId)) return false;
    final cost = craftCost(weaponId, isWeapon: true);
    if (state.resources.materials < cost) return false;
    final stock = Map<String, int>.from(state.weaponStock);
    stock[weaponId] = (stock[weaponId] ?? 0) + 1;
    state = state.copyWith(
      weaponStock: stock,
      resources: state.resources
          .copyWith(materials: state.resources.materials - cost)
          .clampedTo(state.base.resourceStorageCap),
    );
    unawaited(_persist());
    return true;
  }

  bool craftArmor(String armorId) {
    if (!state.unlockedArmorIds.contains(armorId)) return false;
    final cost = craftCost(armorId, isWeapon: false);
    if (state.resources.materials < cost) return false;
    final stock = Map<String, int>.from(state.armorStock);
    stock[armorId] = (stock[armorId] ?? 0) + 1;
    state = state.copyWith(
      armorStock: stock,
      resources: state.resources
          .copyWith(materials: state.resources.materials - cost)
          .clampedTo(state.base.resourceStorageCap),
    );
    unawaited(_persist());
    return true;
  }

  // ---------------------------------------------------------------------
  // Missions
  // ---------------------------------------------------------------------

  Set<String> get deployedSoldierIds => state.deployedOperations
      .expand((operation) => operation.soldierIds)
      .toSet();

  bool isSoldierAvailable(Soldier soldier) =>
      soldier.isAvailable && !deployedSoldierIds.contains(soldier.id);

  int get inProgressMissionCount => state.deployedOperations.length;

  bool canLaunchMission() =>
      inProgressMissionCount < state.base.parallelMissionSlots;

  double operationDurationFor(MissionSite mission) =>
      GameConfig.autoOperationBaseSeconds +
      mission.difficulty * GameConfig.autoOperationSecondsPerDifficulty;

  bool deployMission(MissionSite mission, List<String> soldierIds) {
    final uniqueIds = soldierIds.toSet();
    final missionExists = state.activeMissions.any((m) => m.id == mission.id);
    final selectedSoldiers = state.soldiers
        .where((s) => uniqueIds.contains(s.id))
        .toList();
    if (!canLaunchMission() ||
        !missionExists ||
        uniqueIds.isEmpty ||
        uniqueIds.length > GameConfig.maxSquadSize ||
        selectedSoldiers.length != uniqueIds.length ||
        selectedSoldiers.any((s) => !isSoldierAvailable(s))) {
      return false;
    }

    final duration = operationDurationFor(mission);
    final operation = DeployedOperation(
      id: 'op_${mission.id}',
      mission: mission,
      soldierIds: uniqueIds.toList(),
      secondsRemaining: duration,
      totalDurationSeconds: duration,
      randomSeed: _random.nextInt(1 << 31),
    );
    state = state.copyWith(
      activeMissions: state.activeMissions
          .where((m) => m.id != mission.id)
          .toList(),
      deployedOperations: [...state.deployedOperations, operation],
    );
    unawaited(_persist());
    return true;
  }

  void dismissOperationReport(String reportId) {
    state = state.copyWith(
      operationReports: state.operationReports
          .where((report) => report.id != reportId)
          .toList(),
    );
    unawaited(_persist());
  }

  void _completeDeployedOperation(DeployedOperation operation) {
    final squad = state.soldiers
        .where((s) => operation.soldierIds.contains(s.id))
        .toList();
    final outcome = AutoOperationResolver.resolve(operation, squad);
    final wounded = <String>[];
    final killed = <String>[];
    final updatedSoldiers = <Soldier>[];

    for (final soldier in state.soldiers) {
      if (!operation.soldierIds.contains(soldier.id)) {
        updatedSoldiers.add(soldier);
        continue;
      }

      final soldierOutcome =
          outcome.soldierOutcomes[soldier.id] ?? AutoSoldierOutcome.ready;
      if (soldierOutcome == AutoSoldierOutcome.killed) {
        killed.add(soldier.name);
        continue;
      }

      var updated = soldier.copyWith(
        missionsSurvived: soldier.missionsSurvived + 1,
      );
      if (soldierOutcome == AutoSoldierOutcome.wounded) {
        wounded.add(soldier.name);
        final improvedMaxHp = updated.maxHp + GameConfig.hpGainPerWound;
        updated = updated.copyWith(
          maxHp: improvedMaxHp,
          currentHp: (improvedMaxHp * 0.35).round(),
          status: SoldierStatus.wounded,
          recoveryDaysLeft: (2 + operation.mission.difficulty).toDouble(),
        );
      } else {
        updated = updated.copyWith(currentHp: updated.maxHp);
      }
      updated = SoldierProgression.applyXpAndRankUp(
        updated,
        GameConfig.xpPerMissionParticipation + (outcome.victory ? 5 : 0),
      );
      updatedSoldiers.add(updated);
    }

    var loot = const Resources();
    var trophiesRecovered = 0;
    var threats = state.factionThreats;
    var chaos = state.chaosLevel;
    final trophies = Map<String, int>.from(state.intelTrophies);
    if (outcome.victory) {
      loot = Resources(
        credits: 60 + operation.mission.difficulty * 40,
        materials: 8 + operation.mission.difficulty * 4,
        data: 6 + operation.mission.difficulty * 3,
      );
      trophiesRecovered = 1 + operation.mission.difficulty ~/ 3;
      trophies[operation.mission.factionId.name] =
          (trophies[operation.mission.factionId.name] ?? 0) + trophiesRecovered;
      threats = threats
          .map(
            (f) => f.factionId == operation.mission.factionId
                ? f.copyWith(
                    threatLevel:
                        (f.threatLevel -
                                (12 + operation.mission.difficulty * 3))
                            .clamp(0, 100),
                  )
                : f,
          )
          .toList();
      chaos = (chaos - 2).clamp(0, 100).toDouble();
    } else {
      threats = threats
          .map(
            (f) => f.factionId == operation.mission.factionId
                ? f.copyWith(threatLevel: (f.threatLevel + 8).clamp(0, 100))
                : f,
          )
          .toList();
      chaos = (chaos + 4).clamp(0, 100).toDouble();
    }

    final report = OperationReport(
      id: operation.id,
      regionName: operation.mission.regionName,
      factionName: kFactionDefs[operation.mission.factionId]!.name,
      victory: outcome.victory,
      loot: loot,
      trophiesRecovered: trophiesRecovered,
      wounded: wounded,
      killedInAction: killed,
    );
    final reports = [...state.operationReports, report];
    final retainedReports = reports.length > GameConfig.maxOperationReports
        ? reports.sublist(reports.length - GameConfig.maxOperationReports)
        : reports;
    state = state.copyWith(
      soldiers: updatedSoldiers,
      resources: (state.resources + loot).clampedTo(
        state.base.resourceStorageCap,
      ),
      intelTrophies: trophies,
      factionThreats: threats,
      chaosLevel: chaos,
      operationReports: retainedReports,
    );
    unawaited(_persist());
  }

  BattleController launchMission(MissionSite mission, List<String> soldierIds) {
    final squad = state.soldiers
        .where((s) => soldierIds.contains(s.id))
        .toList();
    return BattleFactory.createMission(
      squad: squad,
      factionId: mission.factionId,
      difficulty: mission.difficulty,
      random: _random,
    );
  }

  MissionResult resolveMission({
    required MissionSite mission,
    required BattleController battle,
    required List<String> squadSoldierIds,
  }) {
    final victory = battle.phase == BattlePhase.victory;
    final killed = <String>[];
    final wounded = <String>[];

    final updatedSoldiers = [...state.soldiers];
    for (final soldierId in squadSoldierIds) {
      final unit = battle.units
          .where((u) => u.soldierId == soldierId)
          .firstOrNull;
      final index = updatedSoldiers.indexWhere((s) => s.id == soldierId);
      if (unit == null || index == -1) continue;

      if (!unit.isAlive) {
        killed.add(updatedSoldiers[index].name);
        updatedSoldiers[index] = updatedSoldiers[index].copyWith(
          status: SoldierStatus.dead,
        );
        continue;
      }

      final becameWounded = unit.hpFraction < 0.5;
      var soldier = updatedSoldiers[index].copyWith(
        missionsSurvived: updatedSoldiers[index].missionsSurvived + 1,
      );

      if (becameWounded) {
        final recoveryDays = 2 + ((1 - unit.hpFraction) * 6).round();
        wounded.add(soldier.name);
        soldier = soldier.copyWith(
          status: SoldierStatus.wounded,
          currentHp: unit.currentHp,
          recoveryDaysLeft: recoveryDays.toDouble(),
        );
      } else {
        soldier = soldier.copyWith(currentHp: soldier.maxHp);
      }

      soldier = SoldierProgression.applyPracticeGrowth(
        soldier,
        unit,
        becameWounded: becameWounded,
      );
      soldier = SoldierProgression.applyXpAndRankUp(
        soldier,
        SoldierProgression.computeXp(unit),
      );

      updatedSoldiers[index] = soldier;
    }
    final rosterAfterDeaths = updatedSoldiers
        .where((s) => s.status != SoldierStatus.dead)
        .toList();

    Resources loot = const Resources();
    var threats = state.factionThreats;
    var chaos = state.chaosLevel;
    var trophiesRecovered = 0;
    final intelTrophies = Map<String, int>.from(state.intelTrophies);

    if (victory) {
      loot = Resources(
        credits: 60 + mission.difficulty * 40,
        materials: 8 + mission.difficulty * 4,
        data: 6 + mission.difficulty * 3,
      );
      trophiesRecovered = 1 + mission.difficulty ~/ 3;
      intelTrophies[mission.factionId.name] =
          (intelTrophies[mission.factionId.name] ?? 0) + trophiesRecovered;
      threats = threats
          .map(
            (f) => f.factionId == mission.factionId
                ? f.copyWith(
                    threatLevel: (f.threatLevel - (12 + mission.difficulty * 3))
                        .clamp(0, 100),
                  )
                : f,
          )
          .toList();
      chaos = (chaos - 2).clamp(0, 100).toDouble();
    } else {
      threats = threats
          .map(
            (f) => f.factionId == mission.factionId
                ? f.copyWith(threatLevel: (f.threatLevel + 8).clamp(0, 100))
                : f,
          )
          .toList();
      chaos = (chaos + 4).clamp(0, 100).toDouble();
    }

    final newResources = (state.resources + loot).clampedTo(
      state.base.resourceStorageCap,
    );
    final missions = state.activeMissions
        .where((m) => m.id != mission.id)
        .toList();

    state = state.copyWith(
      soldiers: rosterAfterDeaths,
      resources: newResources,
      factionThreats: threats,
      chaosLevel: chaos,
      activeMissions: missions,
      intelTrophies: intelTrophies,
    );
    unawaited(_persist());

    return MissionResult(
      victory: victory,
      loot: loot,
      killedInAction: killed,
      wounded: wounded,
      factionName: kFactionDefs[mission.factionId]!.name,
      trophiesRecovered: trophiesRecovered,
    );
  }
}

final gameStateProvider = NotifierProvider<GameStateNotifier, GameSave>(
  GameStateNotifier.new,
);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
