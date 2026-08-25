import 'package:blackwire_protocol/data/models/soldier.dart';
import 'package:blackwire_protocol/data/models/specialization.dart';
import 'package:blackwire_protocol/features/roster/roster_screen.dart';
import 'package:blackwire_protocol/state/game_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'roster shows a promotion button for a Rank 1 soldier and choosing a specialization updates the card',
    (tester) async {
      const soldier = Soldier(id: 's1', name: 'Test Soldier', rank: 1);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                // Seed the roster once, on first build.
                if (ref.read(gameStateProvider).soldiers.isEmpty) {
                  Future.microtask(
                    () => ref
                        .read(gameStateProvider.notifier)
                        .loadSave(
                          ref
                              .read(gameStateProvider)
                              .copyWith(soldiers: [soldier]),
                        ),
                  );
                }
                return const Scaffold(body: RosterScreen());
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ПОВЫШЕНИЕ ДОСТУПНО!'), findsOneWidget);
      expect(find.textContaining('Новобранец (Ранг 1)'), findsOneWidget);

      await tester.tap(find.text('ПОВЫШЕНИЕ ДОСТУПНО!'));
      await tester.pumpAndSettle();

      expect(find.text('Test Soldier получает Ранг 1!'), findsOneWidget);
      expect(find.text('Штурмовик'), findsOneWidget);
      expect(find.text('Снайпер'), findsOneWidget);
      expect(find.text('Тяжёлый'), findsOneWidget);
      expect(find.text('Медик'), findsOneWidget);
      expect(find.text('Техник'), findsOneWidget);

      await tester.tap(find.text('Штурмовик'));
      await tester.pumpAndSettle();

      // Dialog closed, and the soldier's card now reflects the chosen spec.
      expect(find.text('Test Soldier получает Ранг 1!'), findsNothing);
      expect(find.textContaining('Штурмовик'), findsOneWidget);
      expect(find.text('ПОВЫШЕНИЕ ДОСТУПНО!'), findsNothing);
    },
  );

  testWidgets(
    'roster shows a skill choice dialog for a Rank 2+ soldier with a chosen specialization',
    (tester) async {
      const soldier = Soldier(
        id: 's2',
        name: 'Ranked Up',
        rank: 2,
        specialization: Specialization.heavy,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                if (ref.read(gameStateProvider).soldiers.isEmpty) {
                  Future.microtask(
                    () => ref
                        .read(gameStateProvider.notifier)
                        .loadSave(
                          ref
                              .read(gameStateProvider)
                              .copyWith(soldiers: [soldier]),
                        ),
                  );
                }
                return const Scaffold(body: RosterScreen());
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ПОВЫШЕНИЕ ДОСТУПНО!'), findsOneWidget);
      await tester.tap(find.text('ПОВЫШЕНИЕ ДОСТУПНО!'));
      await tester.pumpAndSettle();

      expect(find.text('Ranked Up · Оперативник (Ранг 2)'), findsOneWidget);
      // Heavy's ranks-2..10 generic pair: Стойкость (+HP) / Бронеплиты (+damage reduction).
      expect(find.text('Стойкость'), findsOneWidget);
      expect(find.text('Бронеплиты'), findsOneWidget);

      await tester.tap(find.text('Стойкость'));
      await tester.pumpAndSettle();

      expect(find.text('ПОВЫШЕНИЕ ДОСТУПНО!'), findsNothing);
      expect(
        find.text('Стойкость'),
        findsOneWidget,
      ); // now shown as an equipped skill chip.
    },
  );
}
