import 'package:blackwire_protocol/data/models/faction.dart';
import 'package:blackwire_protocol/data/models/mission_site.dart';
import 'package:blackwire_protocol/data/models/soldier.dart';
import 'package:blackwire_protocol/features/geoscape/geoscape_screen.dart';
import 'package:blackwire_protocol/state/game_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mission sheet dispatches a squad through the hangar', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameStateProvider.notifier)..paused = true;
    const soldier = Soldier(id: 's1', name: 'Alpha');
    const mission = MissionSite(
      id: 'dispatch',
      factionId: EnemyFactionId.nexusRobotics,
      type: MissionType.raid,
      regionName: 'Neon Docks',
      x: 0.5,
      y: 0.5,
      difficulty: 1,
      secondsRemaining: 100,
      totalLifetimeSeconds: 100,
    );
    notifier.loadSave(
      container
          .read(gameStateProvider)
          .copyWith(soldiers: const [soldier], activeMissions: const [mission]),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: GeoscapeScreen())),
      ),
    );

    await tester.tap(find.text('Отряд'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha'));
    await tester.pump();
    await tester.tap(find.text('ОТПРАВИТЬ ЧЕРЕЗ АНГАР'));
    await tester.pumpAndSettle();

    expect(find.text('АНГАР: ОПЕРАЦИИ 1/1'), findsOneWidget);
    expect(find.textContaining('Neon Docks'), findsOneWidget);
    expect(container.read(gameStateProvider).deployedOperations, hasLength(1));
    expect(container.read(gameStateProvider).activeMissions, isEmpty);
  });
}
