# MonetiAr

App de finanzas personales (Flutter + Supabase + Riverpod), iOS primero.

## Setup
1. `flutter pub get`
2. Copiá `env.example.json` a `env.json` y completá URL y key de Supabase.
3. Ejecutá el SQL de `supabase/migrations/0001_init.sql` en el SQL Editor de Supabase.
4. Correr: `flutter run -d chrome --dart-define-from-file=env.json`
   (sin backend: `--dart-define=USE_MOCK=true`).

## Estructura
`lib/features/<feature>/{domain,data,application,presentation}` + `lib/core`.

## Seguridad
- Toda tabla tiene RLS por `user_id = auth.uid()`.
- Nunca usar la `service_role` key en la app.
- `env.json` está en `.gitignore`.
