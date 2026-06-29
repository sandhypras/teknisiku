alter table public.technician_profiles
  add column if not exists latitude numeric(10,7),
  add column if not exists longitude numeric(10,7);

create index if not exists technician_profiles_location_idx
  on public.technician_profiles(latitude, longitude)
  where latitude is not null and longitude is not null;

