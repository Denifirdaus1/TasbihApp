import 'package:flutter_test/flutter_test.dart';

import 'package:smarttasbih/features/dzikir/presentation/zikir_counter_controller.dart';

void main() {
  test('Progress reset ketika mencapai kelipatan target sesi', () {
    const state = ZikirCounterState(
      totalCount: 66,
      pendingCount: 0,
      sessionTarget: 33,
    );

    expect(state.progress, 0);
  });
}
