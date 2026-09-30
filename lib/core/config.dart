/// Build-time configuration.
///
/// Values are supplied with --dart-define. No project credentials are
/// hard-coded into the source tree.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isValid =>
      supabaseUrl.startsWith('https://') &&
      supabasePublishableKey.startsWith('sb_publishable_') &&
      supabasePublishableKey.length > 'sb_publishable_'.length;

  const AppConfig._();
}
