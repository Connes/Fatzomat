import 'dart:io';

void main() {
  final required = <String>[
    'pubspec.yaml',
    'lib/main.dart',
    'supabase/migrations/20260917193000_v130_security_hardening.sql',
    'docs/RELEASE_V140.md',
    'supabase/migrations/202609090001_initial.sql',
    'supabase/migrations/202609090012_weekly_shopping_aggregation.sql',
  ];

  final missing = required.where((p) => !File(p).existsSync()).toList();
  if (missing.isNotEmpty) {
    stderr.writeln('Release check failed. Missing files: ${missing.join(', ')}');
    exitCode = 1;
    return;
  }

  stdout.writeln('Release structure check passed.');
}
