import 'dart:math';

import '../map/line_of_sight.dart';
import '../map/tactical_map.dart';
import '../map/tile.dart';
import '../units/tactical_unit.dart';

enum CoverLevel { none, half, full }

class AttackResult {
  final bool hit;
  final int damage;
  final int hitChance;
  final CoverLevel cover;
  final bool targetKilled;

  const AttackResult({
    required this.hit,
    required this.damage,
    required this.hitChance,
    required this.cover,
    required this.targetKilled,
  });
}

class CombatResolver {
  final Random random;
  CombatResolver({Random? random}) : random = random ?? Random();

  /// Determines the cover level a [target] benefits from when attacked by a
  /// unit standing at [shooterPos]. Cover comes from the tile adjacent to
  /// the target that lies along the shooter's approach direction.
  static CoverLevel coverLevelFor(
    TacticalMap map,
    GridPos target,
    GridPos shooterPos,
  ) {
    final dx = shooterPos.x - target.x;
    final dy = shooterPos.y - target.y;
    int dirX = 0, dirY = 0;
    if (dx.abs() >= dy.abs()) {
      dirX = dx.sign.toInt();
    } else {
      dirY = dy.sign.toInt();
    }
    if (dirX == 0 && dirY == 0) return CoverLevel.none;
    final coverTile = GridPos(target.x + dirX, target.y + dirY);
    if (!map.inBounds(coverTile)) return CoverLevel.none;
    switch (map.tileAt(coverTile)) {
      case TileType.wall:
        return CoverLevel.full;
      case TileType.crate:
        return CoverLevel.half;
      case TileType.floor:
        return CoverLevel.none;
    }
  }

  static int coverPenalty(CoverLevel cover) => switch (cover) {
    CoverLevel.none => 0,
    CoverLevel.half => 20,
    CoverLevel.full => 40,
  };

  bool canAttack(TacticalMap map, TacticalUnit shooter, TacticalUnit target) {
    if (!target.isAlive || !shooter.isAlive) return false;
    final distance = shooter.position.chebyshevDistanceTo(target.position);
    if (distance > shooter.weapon.range) return false;
    return LineOfSight.hasLineOfSight(map, shooter.position, target.position);
  }

  int computeHitChance(
    TacticalMap map,
    TacticalUnit shooter,
    TacticalUnit target,
  ) {
    final distance = shooter.position.chebyshevDistanceTo(target.position);
    final distancePenalty = (distance / shooter.weapon.range * 15).round();
    final cover = coverLevelFor(map, target.position, shooter.position);
    final chance =
        shooter.weapon.baseAccuracy +
        (shooter.baseAccuracy - 65) -
        distancePenalty -
        coverPenalty(cover);
    return chance.clamp(5, 95);
  }

  AttackResult resolveAttack(
    TacticalMap map,
    TacticalUnit shooter,
    TacticalUnit target,
  ) {
    final cover = coverLevelFor(map, target.position, shooter.position);
    final hitChance = computeHitChance(map, shooter, target);
    final roll = random.nextInt(100);
    final hit = roll < hitChance;
    int damage = 0;
    if (hit) {
      damage =
          shooter.weapon.minDamage +
          random.nextInt(
            shooter.weapon.maxDamage - shooter.weapon.minDamage + 1,
          );
      target.applyDamage(damage);
    }
    return AttackResult(
      hit: hit,
      damage: damage,
      hitChance: hitChance,
      cover: cover,
      targetKilled: hit && !target.isAlive,
    );
  }
}
