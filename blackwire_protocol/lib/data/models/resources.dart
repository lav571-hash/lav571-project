/// The three strategic resources of Reclaim.
class Resources {
  final int credits;
  final int materials;
  final int data;

  const Resources({this.credits = 0, this.materials = 0, this.data = 0});

  Resources copyWith({int? credits, int? materials, int? data}) => Resources(
    credits: credits ?? this.credits,
    materials: materials ?? this.materials,
    data: data ?? this.data,
  );

  Resources operator +(Resources other) => Resources(
    credits: credits + other.credits,
    materials: materials + other.materials,
    data: data + other.data,
  );

  Resources operator -(Resources other) => Resources(
    credits: credits - other.credits,
    materials: materials - other.materials,
    data: data - other.data,
  );

  /// Clamp each resource to a storage cap (warehouse limit).
  Resources clampedTo(int cap) => Resources(
    credits: credits, // credits are not capped by warehouse in MVP.
    materials: materials > cap ? cap : materials,
    data: data > cap ? cap : data,
  );

  bool canAfford(Resources cost) =>
      credits >= cost.credits &&
      materials >= cost.materials &&
      data >= cost.data;

  Map<String, dynamic> toJson() => {
    'credits': credits,
    'materials': materials,
    'data': data,
  };

  factory Resources.fromJson(Map<String, dynamic> json) => Resources(
    credits: json['credits'] as int? ?? 0,
    materials: json['materials'] as int? ?? 0,
    data: json['data'] as int? ?? 0,
  );
}
