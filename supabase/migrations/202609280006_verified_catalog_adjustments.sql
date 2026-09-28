-- Verified public menu adjustment (Bazooka Mansoura 2 official menu, September 2026)
update public.menu_items
set price=225,
    image_url='https://www.bazookaegy.com/public/uploads/meals/s_1738104474961829.jpg'
where id='30000000-0000-0000-0000-000000000007'
  and restaurant_id=(select id from public.restaurants where name='بازوكا' limit 1);