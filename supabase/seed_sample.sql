do $$
declare
  u uuid := (select id from auth.users order by created_at limit 1);
  m date := date_trunc('month', current_date)::date;
begin
  if u is null then
    raise exception 'No hay usuarios: registrate primero desde la app.';
  end if;

  insert into public.transactions (user_id, title, amount, type, category_id, payment_method, date, is_paid)
  select u, v.title, v.amount, v.kind, c.id, v.pm, m + (v.day - 1), v.paid
  from (values
    ('Sueldo',         1591350.00, 'income',  'Ingresos',  'transfer', 1,  true),
    ('Otros ingresos',  148392.24, 'income',  'Ingresos',  'transfer', 5,  true),
    ('Pago tarjeta',    630000.00, 'expense', 'T Crédito', 'debit',    2,  true),
    ('ARCA',             75099.08, 'expense', 'Impuestos', 'debit',    20, true),
    ('Wifi',             38000.00, 'expense', 'Casa',      'transfer', 10, false),
    ('Luz',              33900.00, 'expense', 'Casa',      'debit',    12, false),
    ('Gas',              75991.69, 'expense', 'Casa',      'debit',    6,  false),
    ('Seguro auto',      35000.00, 'expense', 'Auto',      'cash',     10, false),
    ('Garage',           60000.00, 'expense', 'Auto',      'transfer', 10, false),
    ('Netflix',          11756.00, 'expense', 'Subs',      'debit',    6,  false),
    ('Pilates',          46000.00, 'expense', 'Valen',     'transfer', 3,  true),
    ('Mecánico',         80000.00, 'expense', 'Auto',      'transfer', 8,  true),
    ('Mostaza',          28090.00, 'expense', 'Comida',    'debit',    4,  true),
    ('Kiosco',            5800.00, 'expense', 'Comida',    'debit',    6,  true),
    ('Compra dólares',  140000.00, 'expense', 'T Crédito', 'debit',    4,  true)
  ) as v(title, amount, kind, cat, pm, day, paid)
  left join public.categories c on c.user_id = u and c.name = v.cat;

  insert into public.installment_plans
    (user_id, title, entity, purchase_date, total, installments, paid_installments, next_due_date)
  values
    (u, 'Zapatillas',    'TC Provincia', m - 62, 119000, 3, 2, (m + interval '1 month')::date + 1),
    (u, 'Óptica',        'TC Provincia', m - 35, 220000, 4, 1, (m + interval '1 month')::date + 1),
    (u, 'Jean + remera', 'Estancias',    m - 80, 219430, 6, 1, m + 9);

  update public.wallets set balance = 318450 where user_id = u and name = 'Cuenta principal';
  update public.wallets set balance = 45000  where user_id = u and name = 'Efectivo';
  update public.wallets set balance = 646900, credit_limit = 1280000
   where user_id = u and name = 'Tarjeta de crédito';
end $$;