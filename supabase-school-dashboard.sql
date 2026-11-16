create table if not exists public.schools (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users (id) on delete cascade,
  school_name text not null,
  province text not null,
  phone text not null,
  official_email text not null,
  description text not null default '',
  logo_url text,
  logo_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.school_books (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  title text not null,
  category text not null,
  description text not null,
  cover_url text not null,
  cover_path text not null,
  pdf_url text not null,
  pdf_path text not null,
  created_at timestamptz not null default now()
);

create index if not exists school_books_school_id_created_at_idx
  on public.school_books (school_id, created_at desc);

alter table public.schools enable row level security;
alter table public.school_books enable row level security;

drop policy if exists "Schools are readable by everyone" on public.schools;
create policy "Schools are readable by everyone"
  on public.schools for select
  to anon, authenticated
  using (true);

drop policy if exists "Users can create their own school" on public.schools;
create policy "Users can create their own school"
  on public.schools for insert
  to authenticated
  with check (auth.uid() = owner_id);

drop policy if exists "Owners can update their school" on public.schools;
create policy "Owners can update their school"
  on public.schools for update
  to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "School books are readable by everyone" on public.school_books;
create policy "School books are readable by everyone"
  on public.school_books for select
  to anon, authenticated
  using (true);

drop policy if exists "School owners can add books" on public.school_books;
create policy "School owners can add books"
  on public.school_books for insert
  to authenticated
  with check (
    exists (
      select 1 from public.schools
      where schools.id = school_books.school_id
        and schools.owner_id = auth.uid()
    )
  );

drop policy if exists "School owners can update books" on public.school_books;
create policy "School owners can update books"
  on public.school_books for update
  to authenticated
  using (
    exists (
      select 1 from public.schools
      where schools.id = school_books.school_id
        and schools.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.schools
      where schools.id = school_books.school_id
        and schools.owner_id = auth.uid()
    )
  );

drop policy if exists "School owners can delete books" on public.school_books;
create policy "School owners can delete books"
  on public.school_books for delete
  to authenticated
  using (
    exists (
      select 1 from public.schools
      where schools.id = school_books.school_id
        and schools.owner_id = auth.uid()
    )
  );

grant select on public.schools, public.school_books to anon, authenticated;
grant insert, update on public.schools to authenticated;
grant insert, update, delete on public.school_books to authenticated;

insert into storage.buckets (id, name, public)
values ('school-media', 'school-media', true), ('lesson-pdfs', 'lesson-pdfs', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Public can read school media" on storage.objects;
create policy "Public can read school media"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id in ('school-media', 'lesson-pdfs'));

drop policy if exists "Owners can upload school media" on storage.objects;
create policy "Owners can upload school media"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id in ('school-media', 'lesson-pdfs')
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1 from public.schools
      where schools.id::text = (storage.foldername(name))[2]
        and schools.owner_id = auth.uid()
    )
  );

drop policy if exists "Owners can update school media" on storage.objects;
create policy "Owners can update school media"
  on storage.objects for update
  to authenticated
  using (
    bucket_id in ('school-media', 'lesson-pdfs')
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1 from public.schools
      where schools.id::text = (storage.foldername(name))[2]
        and schools.owner_id = auth.uid()
    )
  )
  with check (
    bucket_id in ('school-media', 'lesson-pdfs')
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1 from public.schools
      where schools.id::text = (storage.foldername(name))[2]
        and schools.owner_id = auth.uid()
    )
  );

drop policy if exists "Owners can delete school media" on storage.objects;
create policy "Owners can delete school media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id in ('school-media', 'lesson-pdfs')
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1 from public.schools
      where schools.id::text = (storage.foldername(name))[2]
        and schools.owner_id = auth.uid()
    )
  );
