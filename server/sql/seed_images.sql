-- ============================================================
-- SEED IMAGES — pakai Unsplash (free, no attribution required)
-- Jalankan di psql:
--   psql -U postgres -d petualang -f server/sql/seed_images.sql
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. MOUNTAINS — gambar gunung Indonesia + featured + rating
-- ─────────────────────────────────────────────────────────────

-- Insert atau update gunung populer Indonesia
INSERT INTO mountains (name, location, elevation, difficulty, price, image_url, description, is_featured, rating)
VALUES
  ('Gunung Rinjani', 'Lombok, NTB', 3726, 'Sulit', 350000,
   'https://images.unsplash.com/photo-1605649487212-47bdab064df7?w=1200&q=80',
   'Puncak tertinggi kedua di Indonesia. Pemandangan Danau Segara Anak yang spektakuler.',
   TRUE, 4.8),

  ('Gunung Semeru', 'Jawa Timur', 3676, 'Sulit', 250000,
   'https://images.unsplash.com/photo-1583245177184-4c7a05ec0bee?w=1200&q=80',
   'Gunung tertinggi di Pulau Jawa dengan kawah Mahameru yang ikonik.',
   FALSE, 4.7),

  ('Gunung Bromo', 'Jawa Timur', 2329, 'Mudah', 150000,
   'https://images.unsplash.com/photo-1589802757922-757fc34e7c80?w=1200&q=80',
   'Lautan pasir & sunrise terbaik di Jawa. Cocok untuk pemula.',
   FALSE, 4.6),

  ('Gunung Kerinci', 'Jambi', 3805, 'Sulit', 400000,
   'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1200&q=80',
   'Gunung berapi tertinggi di Indonesia. Hutan tropis lebat dan kawah aktif.',
   FALSE, 4.5),

  ('Gunung Merapi', 'Yogyakarta', 2930, 'Menengah', 200000,
   'https://images.unsplash.com/photo-1486870591958-9b9d0d1dda99?w=1200&q=80',
   'Salah satu gunung berapi paling aktif di dunia. Trek malam dengan view matahari terbit.',
   FALSE, 4.4),

  ('Gunung Prau', 'Jawa Tengah', 2565, 'Mudah', 100000,
   'https://images.unsplash.com/photo-1551632811-561732d1e306?w=1200&q=80',
   'Sunrise terbaik di Dieng. Trek pendek, cocok untuk pendaki pemula.',
   FALSE, 4.6),

  ('Gunung Papandayan', 'Garut, Jawa Barat', 2665, 'Mudah', 120000,
   'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?w=1200&q=80',
   'Padang edelweis Tegal Alun & kawah aktif. Family-friendly.',
   FALSE, 4.5)
ON CONFLICT (name) DO UPDATE SET
  image_url = EXCLUDED.image_url,
  is_featured = EXCLUDED.is_featured,
  rating = EXCLUDED.rating;

-- Pastikan hanya 1 gunung yang featured (Rinjani)
UPDATE mountains SET is_featured = FALSE WHERE name != 'Gunung Rinjani';
UPDATE mountains SET is_featured = TRUE WHERE name = 'Gunung Rinjani';


-- ─────────────────────────────────────────────────────────────
-- 2. ARTICLES — gambar untuk artikel/tips
-- ─────────────────────────────────────────────────────────────

UPDATE articles SET image_url = 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800&q=80'
  WHERE LOWER(title) LIKE '%packing%' OR LOWER(title) LIKE '%carrier%';

UPDATE articles SET image_url = 'https://images.unsplash.com/photo-1533873984035-25970ab07461?w=800&q=80'
  WHERE LOWER(title) LIKE '%pemula%' OR LOWER(title) LIKE '%mulai%';

UPDATE articles SET image_url = 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80'
  WHERE LOWER(title) LIKE '%tenda%' OR LOWER(title) LIKE '%camping%';

UPDATE articles SET image_url = 'https://images.unsplash.com/photo-1517398658956-3b50c5e9f9d3?w=800&q=80'
  WHERE LOWER(title) LIKE '%navigasi%' OR LOWER(title) LIKE '%peta%';

UPDATE articles SET image_url = 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&q=80'
  WHERE LOWER(category) = 'tips' AND image_url IS NULL;

-- Fallback untuk artikel yang masih null
UPDATE articles SET image_url = 'https://images.unsplash.com/photo-1455156218388-5e61b526818b?w=800&q=80'
  WHERE image_url IS NULL;


-- ─────────────────────────────────────────────────────────────
-- 3. OPEN TRIPS — gambar untuk trip cards
-- ─────────────────────────────────────────────────────────────

UPDATE open_trips ot SET image_url =
  CASE
    WHEN m.name = 'Gunung Rinjani' THEN 'https://images.unsplash.com/photo-1605649487212-47bdab064df7?w=800&q=80'
    WHEN m.name = 'Gunung Semeru' THEN 'https://images.unsplash.com/photo-1583245177184-4c7a05ec0bee?w=800&q=80'
    WHEN m.name = 'Gunung Bromo'  THEN 'https://images.unsplash.com/photo-1589802757922-757fc34e7c80?w=800&q=80'
    WHEN m.name = 'Gunung Kerinci' THEN 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80'
    WHEN m.name = 'Gunung Merapi' THEN 'https://images.unsplash.com/photo-1486870591958-9b9d0d1dda99?w=800&q=80'
    WHEN m.name = 'Gunung Prau' THEN 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800&q=80'
    WHEN m.name = 'Gunung Papandayan' THEN 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?w=800&q=80'
    ELSE 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&q=80'
  END
FROM mountains m
WHERE ot.mountain_id = m.id;


-- ─────────────────────────────────────────────────────────────
-- 4. COMMUNITIES — cover & icon
-- ─────────────────────────────────────────────────────────────

UPDATE communities SET cover_image_url =
  CASE
    WHEN slug = 'pendaki-rinjani' THEN 'https://images.unsplash.com/photo-1605649487212-47bdab064df7?w=800&q=80'
    WHEN slug = 'campers-nusantara' THEN 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=800&q=80'
    WHEN slug = 'fotografi-alam-liar' THEN 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800&q=80'
    ELSE 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&q=80'
  END
WHERE cover_image_url IS NULL;


-- ─────────────────────────────────────────────────────────────
-- VERIFY
-- ─────────────────────────────────────────────────────────────
SELECT name, is_featured, rating, image_url FROM mountains ORDER BY id;
