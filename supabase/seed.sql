insert into public.categories (name, description, is_active)
values
  ('Komputer', 'Perbaikan dan perawatan komputer desktop.', true),
  ('Laptop', 'Servis laptop, upgrade hardware, dan instalasi software.', true),
  ('Handphone', 'Servis perangkat handphone dan konsultasi kerusakan.', true),
  ('Printer', 'Perbaikan printer, tinta, dan maintenance berkala.', true),
  ('CCTV', 'Instalasi dan perbaikan perangkat CCTV.', true),
  ('Jaringan', 'Instalasi dan perbaikan jaringan rumah atau kantor.', true)
on conflict (name) do update
set description = excluded.description,
    is_active = excluded.is_active,
    updated_at = now();

insert into public.spareparts (name, description)
values
  ('SSD 256GB', 'Storage pengganti atau upgrade untuk laptop dan komputer.'),
  ('RAM 8GB', 'Memori tambahan untuk laptop dan komputer.'),
  ('Adaptor Laptop', 'Adaptor pengganti untuk laptop.'),
  ('Kabel LAN Cat6', 'Kabel jaringan untuk instalasi LAN.'),
  ('Cartridge Printer', 'Cartridge pengganti untuk printer inkjet.')
on conflict (name) do update
set description = excluded.description,
    updated_at = now();

insert into public.app_settings (key, value, description)
values
  ('commission_percentage', '10', 'Default application commission percentage'),
  ('service_city', '"Solo"', 'Initial service area'),
  ('warranty_days', '7', 'Default warranty duration after order completion')
on conflict (key) do update
set value = excluded.value,
    description = excluded.description,
    updated_at = now();
