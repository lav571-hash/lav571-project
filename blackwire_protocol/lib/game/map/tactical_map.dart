import 'tile.dart';

/// A rectangular grid-based tactical battle map.
class TacticalMap {
  final int width;
  final int height;
  final List<List<TileType>> _tiles; // [y][x]

  TacticalMap({
    required this.width,
    required this.height,
    List<List<TileType>>? tiles,
  }) : _tiles =
           tiles ??
           List.generate(
             height,
             (_) => List.generate(width, (_) => TileType.floor),
           );

  TileType tileAt(GridPos pos) => _tiles[pos.y][pos.x];

  void setTile(GridPos pos, TileType type) => _tiles[pos.y][pos.x] = type;

  bool inBounds(GridPos pos) =>
      pos.x >= 0 && pos.x < width && pos.y >= 0 && pos.y < height;

  bool isWalkable(GridPos pos) {
    if (!inBounds(pos)) return false;
    final t = tileAt(pos);
    return t == TileType.floor;
  }

  /// Full cover tiles block line of sight entirely.
  bool blocksSight(GridPos pos) {
    if (!inBounds(pos)) return true;
    return tileAt(pos) == TileType.wall;
  }

  /// Half cover tiles block movement but not sight.
  bool blocksMovement(GridPos pos) {
    if (!inBounds(pos)) return true;
    final t = tileAt(pos);
    return t == TileType.wall || t == TileType.crate;
  }

  List<GridPos> get allPositions => [
    for (int y = 0; y < height; y++)
      for (int x = 0; x < width; x++) GridPos(x, y),
  ];

  List<GridPos> neighbors4(GridPos pos) => [
    GridPos(pos.x + 1, pos.y),
    GridPos(pos.x - 1, pos.y),
    GridPos(pos.x, pos.y + 1),
    GridPos(pos.x, pos.y - 1),
  ].where(inBounds).toList();
}
