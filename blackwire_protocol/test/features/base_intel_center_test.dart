import 'package:blackwire_protocol/data/models/faction.dart';
import 'package:blackwire_protocol/features/base/base_screen.dart';
import 'package:blackwire_protocol/state/game_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('intel center processes a recovered trophy into data', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier);
    final save = container.read(gameStateProvider);
    notifier.loadSave(
      save.copyWith(intelTrophies: {EnemyFactionId.nexusRobotics.name: 1}),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: BaseScreen())),
      ),
    );

    expect(find.text('Разведцентр · ур.1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ядро памяти дроида'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Анализ (+◆8)'), findsOneWidget);

    await tester.tap(find.text('Анализ (+◆8)'));
    await tester.pumpAndSettle();

    expect(find.text('Ядро памяти дроида'), findsNothing);
    expect(container.read(gameStateProvider).resources.data, 8);
    expect(
      find.text('Нет трофеев для анализа. Побеждайте корпорации на миссиях.'),
      findsOneWidget,
    );
  });
}
