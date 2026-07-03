import 'dart:math' as math;

enum TileType {
  floor,
  wall, // full cover, blocks movement & line of sight entirely.
  crate, // half cover, blocks movement but not line of sight.
}

class GridPos {
  final int x;
  final int y;
  const GridPos(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is GridPos && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  double distanceTo(GridPos other) {
    final dx = (x - other.x).toDouble();
    final dy = (y - other.y).toDouble();
    return math.sqrt(dx * dx + dy * dy);
  }

  int chebyshevDistanceTo(GridPos other) {
    final dx = (x - other.x).abs();
    final dy = (y - other.y).abs();
    return dx > dy ? dx : dy;
  }

  @override
  String toString() => '($x,$y)';
}
