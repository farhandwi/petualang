-- ============================================================
-- ASSET PATHS — pakai gambar lokal yang sudah di-bundle di Flutter
-- Tidak perlu network, paling reliable
--   psql -U postgres -d petualang -f server/sql/seed_assets.sql
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- MOUNTAINS — 7 gunung. 2 punya asset spesifik, 5 sisanya
-- pakai semeru.png/rinjani.png sebagai placeholder.
-- (Kalau Anda punya foto gunung lain, drop ke
--  assets/images/mountains/<nama>.jpg lalu update SQL ini.)
-- ─────────────────────────────────────────────────────────────
UPDATE mountains SET image_url = 'assets/images/mountains/rinjani.png'
  WHERE name = 'Gunung Rinjani';
UPDATE mountains SET image_url = 'assets/images/mountains/semeru.png'
  WHERE name = 'Gunung Semeru';
UPDATE mountains SET image_url = 'assets/images/mountains/semeru.png'
  WHERE name = 'Gunung Bromo';
UPDATE mountains SET image_url = 'assets/images/mountains/rinjani.png'
  WHERE name = 'Gunung Kerinci';
UPDATE mountains SET image_url = 'assets/images/mountains/semeru.png'
  WHERE name = 'Gunung Merapi';
UPDATE mountains SET image_url = 'assets/images/mountains/semeru.png'
  WHERE name = 'Gunung Prau';
UPDATE mountains SET image_url = 'assets/images/mountains/rinjani.png'
  WHERE name = 'Gunung Papandayan';

-- ─────────────────────────────────────────────────────────────
-- OPEN TRIPS — pakai foto gunung tujuan
-- ─────────────────────────────────────────────────────────────
UPDATE open_trips SET image_url = 'assets/images/trips/rinjani.png'
  WHERE title LIKE '%Rinjani%';
UPDATE open_trips SET image_url = 'assets/images/trips/semeru.png'
  WHERE title LIKE '%Semeru%';
UPDATE open_trips SET image_url = 'assets/images/trips/semeru.png'
  WHERE title LIKE '%Bromo%';
UPDATE open_trips SET image_url = 'assets/images/trips/rinjani.png'
  WHERE title LIKE '%Kerinci%';
UPDATE open_trips SET image_url = 'assets/images/trips/semeru.png'
  WHERE title LIKE '%Merapi%';
UPDATE open_trips SET image_url = 'assets/images/trips/semeru.png'
  WHERE title LIKE '%Prau%';
UPDATE open_trips SET image_url = 'assets/images/trips/rinjani.png'
  WHERE title LIKE '%Papandayan%';

-- Fallback untuk trips lain
UPDATE open_trips SET image_url = 'assets/images/trips/rinjani.png'
  WHERE image_url IS NULL OR image_url LIKE 'http%';

-- ─────────────────────────────────────────────────────────────
-- EVENTS — pakai event_1.png yang sudah ada
-- ─────────────────────────────────────────────────────────────
UPDATE events SET image_url = 'assets/images/events/event_1.png'
  WHERE image_url IS NULL OR image_url LIKE 'http%';

-- ─────────────────────────────────────────────────────────────
-- RENTAL VENDORS — pakai 6 store yang sudah ada
-- ─────────────────────────────────────────────────────────────
UPDATE rental_vendors SET image_url = 'assets/images/vendors/bandung.png'
  WHERE name = 'Petualang Outdoor Store';
UPDATE rental_vendors SET image_url = 'assets/images/vendors/yogya.png'
  WHERE name = 'Gunung Gear Rental';
UPDATE rental_vendors SET image_url = 'assets/images/vendors/jakarta.png'
  WHERE name = 'Adventure Equipment Hub';
UPDATE rental_vendors SET image_url = 'assets/images/vendors/banyuwangi.png'
  WHERE name = 'Carrier & Tenda Bromo';
UPDATE rental_vendors SET image_url = 'assets/images/vendors/surabaya.png'
  WHERE name = 'Rinjani Gear Lombok';

-- Fallback untuk vendors lain (rotation antara 6 toko)
UPDATE rental_vendors SET image_url = 'assets/images/vendors/semarang.png'
  WHERE image_url IS NULL OR image_url LIKE 'http%';

-- ─────────────────────────────────────────────────────────────
-- ARTICLES
-- ─────────────────────────────────────────────────────────────
UPDATE articles SET image_url = 'assets/images/articles/article_1.png'
  WHERE image_url IS NULL OR image_url LIKE 'http%';

-- ─────────────────────────────────────────────────────────────
-- COMMUNITIES
-- ─────────────────────────────────────────────────────────────
UPDATE communities SET cover_image_url = 'assets/images/communities/community_1.png'
  WHERE slug = 'pendaki-rinjani';
UPDATE communities SET cover_image_url = 'assets/images/communities/community_2.png'
  WHERE slug = 'campers-nusantara';
UPDATE communities SET cover_image_url = 'assets/images/communities/community_1.png'
  WHERE slug = 'fotografi-alam-liar';

-- Fallback untuk komunitas lain
UPDATE communities SET cover_image_url = 'assets/images/communities/community_1.png'
  WHERE cover_image_url IS NULL OR cover_image_url LIKE 'http%';

-- ─────────────────────────────────────────────────────────────
-- VERIFY
-- ─────────────────────────────────────────────────────────────
SELECT 'mountains' AS tbl, COUNT(*) FILTER (WHERE image_url LIKE 'assets/%') AS local, COUNT(*) AS total FROM mountains
UNION ALL SELECT 'open_trips', COUNT(*) FILTER (WHERE image_url LIKE 'assets/%'), COUNT(*) FROM open_trips
UNION ALL SELECT 'events', COUNT(*) FILTER (WHERE image_url LIKE 'assets/%'), COUNT(*) FROM events
UNION ALL SELECT 'rental_vendors', COUNT(*) FILTER (WHERE image_url LIKE 'assets/%'), COUNT(*) FROM rental_vendors
UNION ALL SELECT 'articles', COUNT(*) FILTER (WHERE image_url LIKE 'assets/%'), COUNT(*) FROM articles
UNION ALL SELECT 'communities', COUNT(*) FILTER (WHERE cover_image_url LIKE 'assets/%'), COUNT(*) FROM communities;
