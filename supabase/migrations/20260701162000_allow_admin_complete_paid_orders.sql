create or replace function public.complete_order_with_documents(
  p_order_id uuid,
  p_payment_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  order_row public.orders%rowtype;
  warranty_days integer := 7;
  jwt_role text := current_setting('request.jwt.claim.role', true);
  db_role text := current_user;
begin
  select *
  into order_row
  from public.orders
  where id = p_order_id;

  if not found then
    raise exception 'Order tidak ditemukan';
  end if;

  if coalesce(jwt_role, '') <> 'service_role'
    and db_role not in ('postgres', 'supabase_admin', 'service_role')
    and not public.is_admin()
    and order_row.technician_id is distinct from public.current_technician_profile_id()
  then
    raise exception 'Tidak memiliki akses menyelesaikan order';
  end if;

  select coalesce((value #>> '{}')::integer, 7)
  into warranty_days
  from public.app_settings
  where key = 'warranty_days';

  update public.orders
  set status = 'completed'
  where id = p_order_id;

  insert into public.invoices (
    order_id,
    invoice_number,
    payment_id,
    total_amount
  )
  values (
    p_order_id,
    public.generate_invoice_number(),
    p_payment_id,
    case when order_row.final_total > 0 then order_row.final_total else order_row.estimated_total end
  )
  on conflict (order_id) do update
  set
    payment_id = coalesce(excluded.payment_id, public.invoices.payment_id),
    total_amount = excluded.total_amount;

  insert into public.warranties (
    order_id,
    warranty_number,
    start_date,
    end_date,
    status
  )
  values (
    p_order_id,
    public.generate_warranty_number(),
    current_date,
    current_date + warranty_days,
    'active'
  )
  on conflict (order_id) do nothing;
end;
$$;
