/// A soldier's specialization, chosen once at Rank 1. Determines which
/// skill pool is offered on subsequent rank-ups (Ranks 2-10).
enum Specialization { assault, sniper, heavy, medic, technician }

class SpecializationDef {
  final Specialization id;
  final String name;
  final String description;

  const SpecializationDef({
    required this.id,
    required this.name,
    required this.description,
  });
}

const Map<Specialization, SpecializationDef> kSpecializationDefs = {
  Specialization.assault: SpecializationDef(
    id: Specialization.assault,
    name: 'Штурмовик',
    description:
        'Ближний бой, дробовики/ПП, высокая мобильность и напор в атаке.',
  ),
  Specialization.sniper: SpecializationDef(
    id: Specialization.sniper,
    name: 'Снайпер',
    description:
        'Дальний бой, максимальный урон по одиночной цели, низкая мобильность.',
  ),
  Specialization.heavy: SpecializationDef(
    id: Specialization.heavy,
    name: 'Тяжёлый',
    description:
        'Высокое HP, тяжёлое вооружение, устойчивость к получаемому урону.',
  ),
  Specialization.medic: SpecializationDef(
    id: Specialization.medic,
    name: 'Медик',
    description:
        'Поддержка отряда, устойчивость к панике, забота о выживании бойцов.',
  ),
  Specialization.technician: SpecializationDef(
    id: Specialization.technician,
    name: 'Техник',
    description:
        'Взлом вражеских дроидов и развёртывание турелей/дронов-помощников.',
  ),
};
