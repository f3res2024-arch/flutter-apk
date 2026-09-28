-- Default editable hero media used by the owner studio.
insert into public.app_content(key,image_url)
values('home_hero_image','https://raw.githubusercontent.com/f3res2024-arch/flutter-apk/main/assets/nova_rider.webp')
on conflict(key) do nothing;