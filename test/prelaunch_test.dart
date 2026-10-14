import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_preethi/screens/prelaunch_gate.dart';

void main() {
  test('days-only counter uses IST calendar dates', () {
    expect(
      launchCountdown(
        DateTime.parse('2026-10-14T10:00:00Z'),
        '2026-10-20',
        null,
      ),
      '6 days to go',
    );
    expect(
      launchCountdown(
        DateTime.parse('2026-10-18T18:30:00Z'),
        '2026-10-20',
        null,
      ),
      '1 day to go',
    );
    expect(
      launchCountdown(
        DateTime.parse('2026-10-19T18:30:00Z'),
        '2026-10-20',
        null,
      ),
      'Launch day is here',
    );
    expect(
      launchCountdown(
        DateTime.parse('2026-10-21T00:00:00Z'),
        '2026-10-20',
        null,
      ),
      'Opening soon',
    );
  });
  test('confirmed instant enables exact counter without negative time', () {
    final target = DateTime.parse('2026-10-20T10:00:00+05:30');
    expect(
      launchCountdown(
        DateTime.parse('2026-10-20T04:29:00Z'),
        '2026-10-20',
        target,
      ),
      '0d 00h 01m 00s',
    );
    expect(
      launchCountdown(
        DateTime.parse('2026-10-20T04:30:01Z'),
        '2026-10-20',
        target,
      ),
      'Launch ceremony is near',
    );
  });
  test('launch date is readable', () {
    expect(formatLaunchDate('2026-10-20'), '20 October 2026');
  });
}
