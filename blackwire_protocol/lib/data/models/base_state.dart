import '../../core/constants.dart';

/// Levels of every base facility. Each level increases capacity/output.
///
/// - barracksLevel  -> roster capacity
/// - workshopLevel  -> crafting speed / unlocks higher-tier crafting
/// - labLevel       -> research speed
/// - hangarLevel    -> number of simultaneous missions that can be launched
/// - warehouseLevel -> resource storage cap (materials & data)
/// - medbayLevel    -> wound recovery speed and intensive care efficiency
class BaseState {
  final int barracksLevel;
  final int workshopLevel;
  final int labLevel;
  final int hangarLevel;
  final int warehouseLevel;
  final int medbayLevel;

  const BaseState({
    this.barracksLevel = 1,
    this.workshopLevel = 1,
    this.labLevel = 1,
    this.hangarLevel = 1,
    this.warehouseLevel = 1,
    this.medbayLevel = 1,
  });

  int get rosterCapacity => 4 + (barracksLevel - 1) * 2;
  int get parallelMissionSlots => hangarLevel;
  int get resourceStorageCap => 100 + (warehouseLevel - 1) * 100;
  double get recoverySpeedMultiplier =>
      1 + (medbayLevel - 1) * GameConfig.medbayRecoveryBonusPerLevel;
  double get intensiveCareDays => 1.0 + medbayLevel;

  BaseState copyWith({
    int? barracksLevel,
    int? workshopLevel,
    int? labLevel,
    int? hangarLevel,
    int? warehouseLevel,
    int? medbayLevel,
  }) => BaseState(
    barracksLevel: barracksLevel ?? this.barracksLevel,
    workshopLevel: workshopLevel ?? this.workshopLevel,
    labLevel: labLevel ?? this.labLevel,
    hangarLevel: hangarLevel ?? this.hangarLevel,
    warehouseLevel: warehouseLevel ?? this.warehouseLevel,
    medbayLevel: medbayLevel ?? this.medbayLevel,
  );

  Map<String, dynamic> toJson() => {
    'barracksLevel': barracksLevel,
    'workshopLevel': workshopLevel,
    'labLevel': labLevel,
    'hangarLevel': hangarLevel,
    'warehouseLevel': warehouseLevel,
    'medbayLevel': medbayLevel,
  };

  factory BaseState.fromJson(Map<String, dynamic> json) => BaseState(
    barracksLevel: json['barracksLevel'] as int? ?? 1,
    workshopLevel: json['workshopLevel'] as int? ?? 1,
    labLevel: json['labLevel'] as int? ?? 1,
    hangarLevel: json['hangarLevel'] as int? ?? 1,
    warehouseLevel: json['warehouseLevel'] as int? ?? 1,
    medbayLevel: json['medbayLevel'] as int? ?? 1,
  );
}

/// Cost & effect of upgrading a facility by one level.
class FacilityUpgrade {
  final String facilityId;
  final String name;
  final int nextLevelCost; // in credits
  final int materialsCost;

  const FacilityUpgrade({
    required this.facilityId,
    required this.name,
    required this.nextLevelCost,
    required this.materialsCost,
  });
}
