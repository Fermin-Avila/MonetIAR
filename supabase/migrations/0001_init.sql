-- =====================================================================
-- MonetiAr · esquema inicial
-- =====================================================================

create table public.categories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 60),
  icon_key    text not null default 'other',
  color_value bigint not null default x'FF8E8E93'::bigint,   -- ARGB (excede int32)
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id, name),
  unique (user_id, id)
);

create table public.wallets (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name         text not null check (char_length(name) between 1 and 60),
  type         text not null check (type in ('bank','virtual','cash','creditCard','investment')),
  balance      numeric(14,2) not null default 0,   -- en creditCard: monto utilizado
  credit_limit numeric(14,2),
  currency     text not null default 'ARS',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (user_id, name),
  unique (user_id, id)
);

create table public.transactions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title          text not null check (char_length(title) between 1 and 120),
  amount         numeric(14,2) not null,            -- admite negativos (bonificaciones)
  type           text not null check (type in ('income','expense')),
  category_id    uuid,
  payment_method text not null default 'debit'
                 check (payment_method in ('debit','credit','transfer','cash','qr','additional')),
  date           date not null default current_date,
  is_paid        boolean not null default true,
  wallet_id      uuid,
  note           text,
  currency       text not null default 'ARS',
  fx_rate        numeric(14,4),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  -- FK compuestas: impiden referenciar categorías/cuentas de otro usuario
  foreign key (user_id, category_id) references public.categories (user_id, id)
    on delete set null (category_id),
  foreign key (user_id, wallet_id) references public.wallets (user_id, id)
    on delete set null (wallet_id)
);

create table public.installment_plans (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title             text not null check (char_length(title) between 1 and 120),
  entity            text not null,
  purchase_date     date not null,
  total             numeric(14,2) not null,
  installments      int not null check (installments > 0),
  paid_installments int not null default 0 check (paid_installments >= 0),
  next_due_date     date not null,
  wallet_id         uuid,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  foreign key (user_id, wallet_id) references public.wallets (user_id, id)
    on delete set null (wallet_id)
);

create index transactions_user_date_idx on public.transactions (user_id, date desc);
create index transactions_category_idx  on public.transactions (category_id);
create index transactions_wallet_idx    on public.transactions (wallet_id);
create index plans_user_due_idx         on public.installment_plans (user_id, next_due_date);

-- updated_at ------------------------------------------------------------
create function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- Triggers + RLS en todas las tablas --------------------------------------
do $$
declare t text;
begin
  foreach t in array array['categories','wallets','transactions','installment_plans'] loop
    execute format('create trigger set_updated_at before update on public.%I
                    for each row execute function public.set_updated_at()', t);
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "own rows" on public.%I for all to authenticated
                    using (user_id = (select auth.uid()))
                    with check (user_id = (select auth.uid()))', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
end $$;

-- Datos iniciales por usuario (categorías de tu hoja Config) ----------------
create function public.seed_user_defaults(p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.categories (user_id, name, icon_key, color_value) values
    (p_user, 'Ingresos',  'income',     x'FF30D158'::bigint),
    (p_user, 'Casa',      'home',       x'FF0A84FF'::bigint),
    (p_user, 'Impuestos', 'receipt',    x'FF8E8E93'::bigint),
    (p_user, 'Comida',    'restaurant', x'FFFF9F0A'::bigint),
    (p_user, 'Salud',     'health',     x'FFFF375F'::bigint),
    (p_user, 'Auto',      'car',        x'FF64D2FF'::bigint),
    (p_user, 'Ocio',      'leisure',    x'FFBF5AF2'::bigint),
    (p_user, 'Subs',      'subs',       x'FF5E5CE6'::bigint),
    (p_user, 'Valen',     'person',     x'FFFF6482'::bigint),
    (p_user, 'Fer',       'person',     x'FF34C759'::bigint),
    (p_user, 'T Crédito', 'card',       x'FFFFD60A'::bigint)
  on conflict (user_id, name) do nothing;

  insert into public.wallets (user_id, name, type) values
    (p_user, 'Cuenta principal',    'bank'),
    (p_user, 'Efectivo',            'cash'),
    (p_user, 'Tarjeta de crédito',  'creditCard')
  on conflict (user_id, name) do nothing;
end $$;

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform public.seed_user_defaults(new.id);
  return new;
end $$;

revoke all on function public.seed_user_defaults(uuid) from public, anon, authenticated;
revoke all on function public.handle_new_user()        from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Si ya habías registrado un usuario antes de correr este script:
select public.seed_user_defaults(id) from auth.users;