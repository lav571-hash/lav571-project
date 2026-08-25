import 'package:flutter/material.dart';
import '../../core/constants.dart';

enum EnemyFactionId { titanDynamics, nexusRobotics, chimeraLabs }

class FactionDef {
  final EnemyFactionId id;
  final String name;
  final String enemyTypeName;
  final Color color;
  final String description;
  final String trophyName;

  const FactionDef({
    required this.id,
    required this.name,
    required this.enemyTypeName,
    required this.color,
    required this.description,
    required this.trophyName,
  });
}

const Map<EnemyFactionId, FactionDef> kFactionDefs = {
  EnemyFactionId.titanDynamics: FactionDef(
    id: EnemyFactionId.titanDynamics,
    name: 'Titan Dynamics',
    enemyTypeName: 'PMC-оперативник',
    color: AppColors.titanDynamics,
    description: 'Частная военная корпорация. Хорошо вооружённые наёмники.',
    trophyName: 'Шифрованный архив ЧВК',
  ),
  EnemyFactionId.nexusRobotics: FactionDef(
    id: EnemyFactionId.nexusRobotics,
    name: 'Nexus Robotics',
    enemyTypeName: 'Боевой дроид',
    color: AppColors.nexusRobotics,
    description: 'Корпорация автономных боевых систем и дронов.',
    trophyName: 'Ядро памяти дроида',
  ),
  EnemyFactionId.chimeraLabs: FactionDef(
    id: EnemyFactionId.chimeraLabs,
    name: 'Chimera Labs',
    enemyTypeName: 'Мутант-биоформ',
    color: AppColors.chimeraLabs,
    description: 'Биотех-корпорация, создающая нестабильные организмы.',
    trophyName: 'Биообразец Chimera',
  ),
};

/// Mutable runtime threat level for a faction (0-100). Rises over time and
/// contributes to the global chaos meter; missions against a faction lower
/// its threat level.
class FactionThreat {
  final EnemyFactionId factionId;
  final double threatLevel;

  const FactionThreat({required this.factionId, this.threatLevel = 10});

  FactionThreat copyWith({double? threatLevel}) => FactionThreat(
    factionId: factionId,
    threatLevel: threatLevel ?? this.threatLevel,
  );

  Map<String, dynamic> toJson() => {
    'factionId': factionId.name,
    'threatLevel': threatLevel,
  };

  factory FactionThreat.fromJson(Map<String, dynamic> json) => FactionThreat(
    factionId: EnemyFactionId.values.firstWhere(
      (e) => e.name == json['factionId'],
    ),
    threatLevel: (json['threatLevel'] as num).toDouble(),
  );
}
