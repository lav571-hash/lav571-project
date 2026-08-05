import 'package:blackwire_protocol/data/models/soldier.dart';
import 'package:blackwire_protocol/features/base/base_screen.dart';
import 'package:blackwire_protocol/state/game_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('medbay lists wounded soldiers and intensive care heals them', (
    tester,
  ) async {
    const wounded = Soldier(
      id: 'patient',
      name: 'Patient Zero',
      currentHp: 35,
      status: SoldierStatus.wounded,
      recoveryDaysLeft: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              if (ref.read(gameStateProvider).soldiers.isEmpty) {
                Future.microtask(() {
                  final save = ref.read(gameStateProvider);
                  ref
                      .read(gameStateProvider.notifier)
                      .loadSave(
                        save.copyWith(
                          soldiers: [wounded],
                          resources: save.resources.copyWith(credits: 500),
                        ),
                      );
                });
              }
              return const Scaffold(body: BaseScreen());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Медотсек · ур.1'), findsOneWidget);
    expect(find.text('Patient Zero'), findsOneWidget);
    expect(find.text('Лечить (₡70)'), findsOneWidget);

    await tester.ensureVisible(find.text('Лечить (₡70)'));
    await tester.tap(find.text('Лечить (₡70)'));
    await tester.pumpAndSettle();

    expect(find.text('Patient Zero'), findsNothing);
    expect(find.text('Все оперативники готовы к бою.'), findsOneWidget);
  });
}
