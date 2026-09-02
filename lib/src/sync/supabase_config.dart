/// Supabase kalitlari build vaqtida beriladi:
///
///   flutter build web --dart-define-from-file=env.json
///
/// `env.json` git'ga tushmaydi (.gitignore'da). Namuna: `env.example.json`.
/// Kalitlar berilmasa, ilova faqat shu brauzer xotirasida ishlaydi.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment("SUPABASE_URL");
  /// Supabase paneli -> Project Settings -> API Keys da turadi
  /// ("anon public" yoki "publishable key"). Bu kalit ochiq bo'lishi normal:
  /// himoya RLS qoidalari va foydalanuvchi kirishi orqali ta'minlanadi.
  /// `service_role` kalitini bu yerga ASLO qo'ymang.
  static const String anonKey = String.fromEnvironment("SUPABASE_ANON_KEY");

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
