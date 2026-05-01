-- ============================================================
-- IMAGE FIX v2 — pakai placehold.co (PNG colored, super reliable)
-- picsum.photos kadang return format yang Android decoder reject
-- placehold.co return simple PNG dengan warna solid + text
-- Jalankan: psql -U postgres -d petualang -f server/sql/seed_images_v2.sql
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- MOUNTAINS
-- ─────────────────────────────────────────────────────────────
UPDATE mountains SET image_url = 'https://placehold.co/1200x750/FF6B35/FFFFFF/png?text=Gunung+Rinjani'
  WHERE name = 'Gunung Rinjani';
UPDATE mountains SET image_url = 'https://placehold.co/1200x750/10B981/FFFFFF/png?text=Gunung+Semeru'
  WHERE name = 'Gunung Semeru';
UPDATE mountains SET image_url = 'https://placehold.co/1200x750/8B5CF6/FFFFFF/png?text=Gunung+Bromo'
  WHERE name = 'Gunung Bromo';
UPDATE mountains SET image_url = 'https://placehold.co/1200x750/0EA5E9/FFFFFF/png?text=Gunung+Kerinci'
  WHERE name = 'Gunung Kerinci';
UPDATE mountains SET image_url = 'https://placehold.co/1200x750/EAB308/FFFFFF/png?text=Gunung+Merapi'
  WHERE name = 'Gunung Merapi';
UPDATE mountains SET image_url = 'https://placehold.co/1200x750/EC4899/FFFFFF/png?text=Gunung+Prau'
  WHERE name = 'Gunung Prau';
UPDATE mountains SET image_url = 'https://placehold.co/1200x750/14B8A6/FFFFFF/png?text=Gunung+Papandayan'
  WHERE name = 'Gunung Papandayan';

-- ─────────────────────────────────────────────────────────────
-- OPEN TRIPS
-- ─────────────────────────────────────────────────────────────
UPDATE open_trips SET image_url = 'https://placehold.co/1200x750/FF6B35/FFFFFF/png?text=Open+Trip+Rinjani'
  WHERE title = 'Open Trip Rinjani 4D3N';
UPDATE open_trips SET image_url = 'https://placehold.co/1200x750/10B981/FFFFFF/png?text=Tek-Tok+Semeru'
  WHERE title = 'Tek-Tok Semeru (Muncak Cepat)';
UPDATE open_trips SET image_url = 'https://placehold.co/1200x750/8B5CF6/FFFFFF/png?text=Sunrise+Bromo'
  WHERE title LIKE 'Sunrise Bromo%';
UPDATE open_trips SET image_url = 'https://placehold.co/1200x750/0EA5E9/FFFFFF/png?text=Ekspedisi+Kerinci'
  WHERE title = 'Ekspedisi Kerinci 5D4N';
UPDATE open_trips SET image_url = 'https://placehold.co/1200x750/EAB308/FFFFFF/png?text=Night+Hike+Merapi'
  WHERE title = 'Night Hike Merapi via Selo';
UPDATE open_trips SET image_url = 'https://placehold.co/1200x750/EC4899/FFFFFF/png?text=Sunrise+Prau'
  WHERE title LIKE 'Sunrise Prau%';
UPDATE open_trips SET image_url = 'https://placehold.co/1200x750/14B8A6/FFFFFF/png?text=Family+Camping'
  WHERE title = 'Family Camping Papandayan';
UPDATE open_trips SET image_url = 'https://placehold.co/1200x750/F97316/FFFFFF/png?text=Charity+Hike'
  WHERE title = 'Charity Hike Rinjani 5D4N';

-- Fallback untuk open_trips lain yang belum punya image
UPDATE open_trips
  SET image_url = 'https://placehold.co/1200x750/FF6B35/FFFFFF/png?text=Open+Trip'
  WHERE image_url IS NULL OR image_url LIKE '%picsum%' OR image_url LIKE '%unsplash%';

-- ─────────────────────────────────────────────────────────────
-- EVENTS
-- ─────────────────────────────────────────────────────────────
UPDATE events SET image_url = 'https://placehold.co/1200x750/3B82F6/FFFFFF/png?text=Gathering+Pendaki'
  WHERE title = 'Gathering Pendaki Jakarta';
UPDATE events SET image_url = 'https://placehold.co/1200x750/10B981/FFFFFF/png?text=Workshop+Survival'
  WHERE title = 'Workshop Survival di Gunung';
UPDATE events SET image_url = 'https://placehold.co/1200x750/14B8A6/FFFFFF/png?text=Bersih+Gn.+Salak'
  WHERE title = 'Aksi Bersih Gunung Salak';
UPDATE events SET image_url = 'https://placehold.co/1200x750/EC4899/FFFFFF/png?text=Photo+Trip+Bromo'
  WHERE title = 'Photography Trip Bromo';
UPDATE events SET image_url = 'https://placehold.co/1200x750/F59E0B/FFFFFF/png?text=Talkshow+SAR'
  WHERE title LIKE 'Talkshow%';

-- ─────────────────────────────────────────────────────────────
-- RENTAL VENDORS
-- ─────────────────────────────────────────────────────────────
UPDATE rental_vendors SET image_url = 'https://placehold.co/800x500/10B981/FFFFFF/png?text=Petualang+Outdoor'
  WHERE name = 'Petualang Outdoor Store';
UPDATE rental_vendors SET image_url = 'https://placehold.co/800x500/0EA5E9/FFFFFF/png?text=Gunung+Gear'
  WHERE name = 'Gunung Gear Rental';
UPDATE rental_vendors SET image_url = 'https://placehold.co/800x500/8B5CF6/FFFFFF/png?text=Adventure+Hub'
  WHERE name = 'Adventure Equipment Hub';
UPDATE rental_vendors SET image_url = 'https://placehold.co/800x500/EC4899/FFFFFF/png?text=Carrier+%26+Tenda'
  WHERE name = 'Carrier & Tenda Bromo';
UPDATE rental_vendors SET image_url = 'https://placehold.co/800x500/F59E0B/FFFFFF/png?text=Rinjani+Gear'
  WHERE name = 'Rinjani Gear Lombok';

-- Fallback untuk vendors dummy lain
UPDATE rental_vendors
  SET image_url = 'https://placehold.co/800x500/10B981/FFFFFF/png?text=Sewa+Alat'
  WHERE image_url IS NULL OR image_url LIKE '%picsum%' OR image_url LIKE '%unsplash%';

-- ─────────────────────────────────────────────────────────────
-- ARTICLES
-- ─────────────────────────────────────────────────────────────
UPDATE articles SET image_url = 'https://placehold.co/800x450/FF6B35/FFFFFF/png?text=Tips+Pendaki'
  WHERE image_url IS NULL OR image_url LIKE '%picsum%' OR image_url LIKE '%unsplash%';

-- ─────────────────────────────────────────────────────────────
-- COMMUNITIES
-- ─────────────────────────────────────────────────────────────
UPDATE communities SET cover_image_url = 'https://placehold.co/800x500/FF6B35/FFFFFF/png?text=Pendaki+Rinjani'
  WHERE slug = 'pendaki-rinjani';
UPDATE communities SET cover_image_url = 'https://placehold.co/800x500/10B981/FFFFFF/png?text=Campers+Nusantara'
  WHERE slug = 'campers-nusantara';
UPDATE communities SET cover_image_url = 'https://placehold.co/800x500/8B5CF6/FFFFFF/png?text=Fotografi+Alam'
  WHERE slug = 'fotografi-alam-liar';

-- ─────────────────────────────────────────────────────────────
-- VERIFY
-- ─────────────────────────────────────────────────────────────
SELECT 'mountains' AS tbl, COUNT(*) FILTER (WHERE image_url LIKE '%placehold%') AS done, COUNT(*) AS total FROM mountains
UNION ALL SELECT 'open_trips', COUNT(*) FILTER (WHERE image_url LIKE '%placehold%'), COUNT(*) FROM open_trips
UNION ALL SELECT 'events', COUNT(*) FILTER (WHERE image_url LIKE '%placehold%'), COUNT(*) FROM events
UNION ALL SELECT 'rental_vendors', COUNT(*) FILTER (WHERE image_url LIKE '%placehold%'), COUNT(*) FROM rental_vendors
UNION ALL SELECT 'articles', COUNT(*) FILTER (WHERE image_url LIKE '%placehold%'), COUNT(*) FROM articles
UNION ALL SELECT 'communities', COUNT(*) FILTER (WHERE cover_image_url LIKE '%placehold%'), COUNT(*) FROM communities;
