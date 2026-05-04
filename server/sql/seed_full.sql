-- ============================================================
-- FULL SEED DATA — Open Trips, Events, Buddy Posts, Vendors
-- Image URLs pakai picsum.photos (selalu valid, tidak 404)
-- Jalankan setelah server di-restart (migrasi sudah jalan):
--   psql -U postgres -d petualang -f server/sql/seed_full.sql
-- ============================================================


-- ─────────────────────────────────────────────────────────────
-- 1. MOUNTAINS — refresh image URLs ke picsum.photos
-- ─────────────────────────────────────────────────────────────

UPDATE mountains SET image_url = 'https://picsum.photos/seed/rinjani/1200/750'
  WHERE name = 'Gunung Rinjani';
UPDATE mountains SET image_url = 'https://picsum.photos/seed/semeru/1200/750'
  WHERE name = 'Gunung Semeru';
UPDATE mountains SET image_url = 'https://picsum.photos/seed/bromo/1200/750'
  WHERE name = 'Gunung Bromo';
UPDATE mountains SET image_url = 'https://picsum.photos/seed/kerinci/1200/750'
  WHERE name = 'Gunung Kerinci';
UPDATE mountains SET image_url = 'https://picsum.photos/seed/merapi/1200/750'
  WHERE name = 'Gunung Merapi';
UPDATE mountains SET image_url = 'https://picsum.photos/seed/prau/1200/750'
  WHERE name = 'Gunung Prau';
UPDATE mountains SET image_url = 'https://picsum.photos/seed/papandayan/1200/750'
  WHERE name = 'Gunung Papandayan';


-- ─────────────────────────────────────────────────────────────
-- 2. OPEN TRIPS — buat 8 open trip dengan tanggal upcoming + gambar
-- ─────────────────────────────────────────────────────────────

DO $$
DECLARE
  rinjani_id INT;
  semeru_id INT;
  bromo_id INT;
  kerinci_id INT;
  merapi_id INT;
  prau_id INT;
  papandayan_id INT;
BEGIN
  SELECT id INTO rinjani_id FROM mountains WHERE name = 'Gunung Rinjani' LIMIT 1;
  SELECT id INTO semeru_id FROM mountains WHERE name = 'Gunung Semeru' LIMIT 1;
  SELECT id INTO bromo_id FROM mountains WHERE name = 'Gunung Bromo' LIMIT 1;
  SELECT id INTO kerinci_id FROM mountains WHERE name = 'Gunung Kerinci' LIMIT 1;
  SELECT id INTO merapi_id FROM mountains WHERE name = 'Gunung Merapi' LIMIT 1;
  SELECT id INTO prau_id FROM mountains WHERE name = 'Gunung Prau' LIMIT 1;
  SELECT id INTO papandayan_id FROM mountains WHERE name = 'Gunung Papandayan' LIMIT 1;

  INSERT INTO open_trips (
    mountain_id, title, description, start_date, end_date, price,
    max_participants, current_participants, status, image_url
  ) VALUES
    (rinjani_id,
     'Open Trip Rinjani 4D3N',
     'Pendakian via Sembalun Sunrise Crater Rim. Termasuk transport, porter, makan 4x.',
     NOW() + INTERVAL '5 days', NOW() + INTERVAL '8 days', 1200000,
     12, 8, 'open',
     'https://picsum.photos/seed/trip-rinjani/1200/750'),

    (semeru_id,
     'Tek-Tok Semeru (Muncak Cepat)',
     'Express trip 2D1N. Berangkat malam dari Ranu Pane langsung summit attack.',
     NOW() + INTERVAL '7 days', NOW() + INTERVAL '8 days', 900000,
     10, 7, 'open',
     'https://picsum.photos/seed/trip-semeru/1200/750'),

    (bromo_id,
     'Sunrise Bromo & Madakaripura 2D1N',
     'Paket honeymoon spot. Jeep tour Bromo + waterfall Madakaripura.',
     NOW() + INTERVAL '12 days', NOW() + INTERVAL '13 days', 650000,
     20, 14, 'open',
     'https://picsum.photos/seed/trip-bromo/1200/750'),

    (kerinci_id,
     'Ekspedisi Kerinci 5D4N',
     'Trip pendaki advanced. Puncak tertinggi gunung berapi Indonesia.',
     NOW() + INTERVAL '18 days', NOW() + INTERVAL '22 days', 2500000,
     8, 3, 'open',
     'https://picsum.photos/seed/trip-kerinci/1200/750'),

    (merapi_id,
     'Night Hike Merapi via Selo',
     'Trek malam, sunrise di puncak. Cocok pendaki menengah.',
     NOW() + INTERVAL '25 days', NOW() + INTERVAL '26 days', 450000,
     15, 5, 'open',
     'https://picsum.photos/seed/trip-merapi/1200/750'),

    (prau_id,
     'Sunrise Prau 2D1N (Pemula)',
     'Trip ramah pemula. Sunset golden hour Dieng + sunrise puncak Prau.',
     NOW() + INTERVAL '10 days', NOW() + INTERVAL '11 days', 380000,
     20, 18, 'open',
     'https://picsum.photos/seed/trip-prau/1200/750'),

    (papandayan_id,
     'Family Camping Papandayan',
     'Camping di Pondok Saladah, family friendly. Kawah & padang edelweis.',
     NOW() + INTERVAL '14 days', NOW() + INTERVAL '15 days', 420000,
     25, 12, 'open',
     'https://picsum.photos/seed/trip-papandayan/1200/750'),

    (rinjani_id,
     'Charity Hike Rinjani 5D4N',
     'Trip dengan misi clean-up sampah Plawangan. Sebagian profit untuk konservasi.',
     NOW() + INTERVAL '40 days', NOW() + INTERVAL '44 days', 1500000,
     15, 4, 'open',
     'https://picsum.photos/seed/trip-charity/1200/750')
  ON CONFLICT DO NOTHING;
END $$;


-- ─────────────────────────────────────────────────────────────
-- 3. EVENTS — 5 events upcoming
-- ─────────────────────────────────────────────────────────────

INSERT INTO events (
  title, description, location, event_date, image_url, max_participants, current_participants
) VALUES
  ('Gathering Pendaki Jakarta',
   'Meetup bulanan komunitas pendaki ibukota. Sharing tips, kopdar, dan main games seru.',
   'Taman Menteng, Jakarta',
   NOW() + INTERVAL '8 days',
   'https://picsum.photos/seed/event-jkt/1200/750',
   50, 23),

  ('Workshop Survival di Gunung',
   'Belajar teknik bertahan hidup, pertolongan pertama, dan navigasi outdoor.',
   'Bumi Perkemahan Cikole, Bandung',
   NOW() + INTERVAL '15 days',
   'https://picsum.photos/seed/event-survival/1200/750',
   30, 12),

  ('Aksi Bersih Gunung Salak',
   'Kegiatan peduli lingkungan. Bawa pulang sampah, pulangkan keindahan alam.',
   'Pos 1 Gn. Salak, Bogor',
   NOW() + INTERVAL '22 days',
   'https://picsum.photos/seed/event-salak/1200/750',
   100, 45),

  ('Photography Trip Bromo',
   'Hunting foto sunrise & milky way. Termasuk session edit Lightroom.',
   'Penanjakan, Probolinggo',
   NOW() + INTERVAL '30 days',
   'https://picsum.photos/seed/event-photo/1200/750',
   15, 6),

  ('Talkshow: Mendaki Aman ala SAR',
   'Belajar SAR & emergency response dari tim Basarnas. Free attendance.',
   'Gor Lila Bhuana, Denpasar',
   NOW() + INTERVAL '5 days',
   'https://picsum.photos/seed/event-sar/1200/750',
   200, 87)
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────
-- 4. RENTAL VENDORS — 5 toko sewa alat dengan rating tinggi
-- ─────────────────────────────────────────────────────────────

INSERT INTO rental_vendors (
  name, address, latitude, longitude, rating, review_count, is_open, image_url
) VALUES
  ('Petualang Outdoor Store',
   'Jl. Cikutra No. 145, Bandung', -6.9039, 107.6332, 4.9, 248, TRUE,
   'https://picsum.photos/seed/vendor-1/800/500'),

  ('Gunung Gear Rental',
   'Jl. Kaliurang KM 12, Yogyakarta', -7.7173, 110.4096, 4.8, 187, TRUE,
   'https://picsum.photos/seed/vendor-2/800/500'),

  ('Adventure Equipment Hub',
   'Jl. Veteran No. 89, Malang', -7.9649, 112.6195, 4.7, 156, TRUE,
   'https://picsum.photos/seed/vendor-3/800/500'),

  ('Carrier & Tenda Bromo',
   'Jl. Raya Tosari, Pasuruan', -7.9434, 112.9499, 4.6, 132, TRUE,
   'https://picsum.photos/seed/vendor-4/800/500'),

  ('Rinjani Gear Lombok',
   'Jl. Pariwisata Senaru, Lombok', -8.3289, 116.4007, 4.8, 198, TRUE,
   'https://picsum.photos/seed/vendor-5/800/500')
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────
-- 5. ARTICLES — refresh image URLs
-- ─────────────────────────────────────────────────────────────

UPDATE articles SET image_url = 'https://picsum.photos/seed/article-1/800/450'
  WHERE image_url IS NULL OR image_url = '' OR image_url LIKE '%unsplash%';


-- ─────────────────────────────────────────────────────────────
-- 6. COMMUNITIES — refresh covers
-- ─────────────────────────────────────────────────────────────

UPDATE communities SET
    cover_image_url = 'https://picsum.photos/seed/community-1/800/500',
    icon_image_url  = 'https://picsum.photos/seed/icon-community-1/200/200',
    location = 'Yogyakarta',
    rating = 4.9,
    review_count = 312
  WHERE slug = 'pendaki-rinjani';
UPDATE communities SET
    cover_image_url = 'https://picsum.photos/seed/community-2/800/500',
    icon_image_url  = 'https://picsum.photos/seed/icon-community-2/200/200',
    location = 'Bandung',
    rating = 4.8,
    review_count = 240
  WHERE slug = 'campers-nusantara';
UPDATE communities SET
    cover_image_url = 'https://picsum.photos/seed/community-3/800/500',
    icon_image_url  = 'https://picsum.photos/seed/icon-community-3/200/200',
    location = 'Jakarta',
    rating = 4.7,
    review_count = 178
  WHERE slug = 'fotografi-alam-liar';

-- Tambah komunitas baru agar grid "Semua Komunitas" terisi
INSERT INTO communities
  (name, slug, description, cover_image_url, icon_image_url,
   category, privacy, location, rating, review_count, member_count)
VALUES
  ('Pendaki Jogja', 'pendaki-jogja',
   'Komunitas pendaki terbesar di Yogyakarta. Aktif mengadakan pendakian bareng, sharing info jalur, dan edukasi keselamatan gunung setiap bulan.',
   'https://picsum.photos/seed/community-jogja/800/500',
   'https://picsum.photos/seed/icon-jogja/200/200',
   'Hiking & Trekking', 'public', 'Yogyakarta', 4.9, 312, 2800),
  ('Camping Lovers ID', 'camping-lovers-id',
   'Berbagi spot camping favorit dan tips outdoor untuk camper Indonesia.',
   'https://picsum.photos/seed/community-camp/800/500',
   'https://picsum.photos/seed/icon-camp/200/200',
   'Camping & Outdoor', 'public', 'Indonesia', 4.8, 215, 8400),
  ('Trail Runner Indonesia', 'trail-runner-id',
   'Komunitas pelari trail dari berbagai kota — info lomba, training plan, dan partner lari.',
   'https://picsum.photos/seed/community-run/800/500',
   'https://picsum.photos/seed/icon-run/200/200',
   'Running', 'public', 'Indonesia', 4.6, 98, 1200),
  ('Fotografer Alam', 'fotografer-alam',
   'Wadah fotografer landscape dan wildlife untuk berbagi karya, lokasi, dan teknik.',
   'https://picsum.photos/seed/community-foto/800/500',
   'https://picsum.photos/seed/icon-foto/200/200',
   'Fotografi', 'public', 'Bandung', 4.7, 142, 940),
  ('Climbers Hub', 'climbers-hub',
   'Komunitas panjat tebing & sport climbing Indonesia. Info crag, gear, dan event nasional.',
   'https://picsum.photos/seed/community-climb/800/500',
   'https://picsum.photos/seed/icon-climb/200/200',
   'Climbing', 'public', 'Bandung', 4.5, 67, 520),
  ('Open Trip Hunter', 'open-trip-hunter',
   'Bagi yang suka ikut open trip atau cari peserta — info promo dan testimoni.',
   'https://picsum.photos/seed/community-trip/800/500',
   'https://picsum.photos/seed/icon-trip/200/200',
   'Lainnya', 'public', 'Indonesia', 4.4, 51, 690)
ON CONFLICT (slug) DO NOTHING;

-- Aturan komunitas (sample)
DO $$
DECLARE
  cid INT;
BEGIN
  SELECT id INTO cid FROM communities WHERE slug = 'pendaki-jogja' LIMIT 1;
  IF cid IS NOT NULL THEN
    DELETE FROM community_rules WHERE community_id = cid;
    INSERT INTO community_rules (community_id, ordinal, text) VALUES
      (cid, 1, 'Saling menghormati antar anggota — no hate, no SARA.'),
      (cid, 2, 'Dilarang promosi/jualan tanpa izin admin.'),
      (cid, 3, 'Selalu utamakan keselamatan saat pendakian dan ikuti aturan TN.'),
      (cid, 4, 'Sertakan info jelas saat sharing trip (tanggal, jalur, biaya).'),
      (cid, 5, 'Hormati kearifan lokal & jaga kelestarian alam (no littering).');
  END IF;

  SELECT id INTO cid FROM communities WHERE slug = 'camping-lovers-id' LIMIT 1;
  IF cid IS NOT NULL THEN
    DELETE FROM community_rules WHERE community_id = cid;
    INSERT INTO community_rules (community_id, ordinal, text) VALUES
      (cid, 1, 'Bagikan lokasi camping yang legal dan aman.'),
      (cid, 2, 'Tag lokasi & cantumkan info biaya/akses bila ada.'),
      (cid, 3, 'No spam — promosi gear hanya di thread khusus.'),
      (cid, 4, 'Leave No Trace — bawa pulang sampahmu.');
  END IF;
END $$;

-- Sample community events (kegiatan)
DO $$
DECLARE
  cid_jogja INT;
  cid_camp INT;
  organizer_id INT;
BEGIN
  SELECT id INTO cid_jogja FROM communities WHERE slug = 'pendaki-jogja' LIMIT 1;
  SELECT id INTO cid_camp FROM communities WHERE slug = 'camping-lovers-id' LIMIT 1;
  SELECT id INTO organizer_id FROM users ORDER BY id ASC LIMIT 1;

  IF cid_jogja IS NOT NULL THEN
    INSERT INTO events (title, description, location, event_date, image_url,
                        organizer_id, max_participants, community_id)
    VALUES
      ('Pendakian Bareng Merbabu via Selo',
       'Open trip santai untuk anggota Pendaki Jogja. Berangkat Sabtu pagi.',
       'Boyolali, Jawa Tengah', NOW() + INTERVAL '14 days',
       'https://picsum.photos/seed/event-merbabu/800/400',
       organizer_id, 20, cid_jogja),
      ('Workshop Navigasi & GPS',
       'Belajar baca peta topografi dan pakai aplikasi GPS untuk pendakian aman.',
       'Sekretariat Pendaki Jogja, Sleman', NOW() + INTERVAL '5 days',
       'https://picsum.photos/seed/event-nav/800/400',
       organizer_id, 30, cid_jogja),
      ('Bersih Sampah Gunung Sumbing',
       'Aksi bersih jalur pendakian Sumbing via Garung. Disediakan makan siang.',
       'Wonosobo, Jawa Tengah', NOW() + INTERVAL '30 days',
       'https://picsum.photos/seed/event-bersih/800/400',
       organizer_id, 50, cid_jogja);
  END IF;

  IF cid_camp IS NOT NULL THEN
    INSERT INTO events (title, description, location, event_date, image_url,
                        organizer_id, max_participants, community_id)
    VALUES
      ('Family Camping di Curug Cilember',
       'Camping ramah keluarga, cocok untuk pemula. Tenda disediakan.',
       'Bogor, Jawa Barat', NOW() + INTERVAL '21 days',
       'https://picsum.photos/seed/event-camping/800/400',
       organizer_id, 25, cid_camp);
  END IF;
END $$;


-- ─────────────────────────────────────────────────────────────
-- 7. BUDDY POSTS — sample untuk Cari Barengan
-- ─────────────────────────────────────────────────────────────

DO $$
DECLARE
  user_id_1 INT;
  user_id_2 INT;
  rinjani_id INT;
  semeru_id INT;
  prau_id INT;
BEGIN
  SELECT id INTO user_id_1 FROM users ORDER BY id ASC LIMIT 1;
  SELECT id INTO user_id_2 FROM users ORDER BY id ASC OFFSET 1 LIMIT 1;
  SELECT id INTO rinjani_id FROM mountains WHERE name = 'Gunung Rinjani' LIMIT 1;
  SELECT id INTO semeru_id FROM mountains WHERE name = 'Gunung Semeru' LIMIT 1;
  SELECT id INTO prau_id FROM mountains WHERE name = 'Gunung Prau' LIMIT 1;

  IF user_id_1 IS NOT NULL THEN
    INSERT INTO buddy_posts (
      user_id, mountain_id, title, description, target_date, max_buddies, current_buddies
    ) VALUES
      (user_id_1, rinjani_id,
       'Cari 2 orang ke Rinjani via Sembalun',
       'Plan summit attack 2 hari. Sudah pernah pengalaman gunung 3000+. Sharing biaya transport & guide.',
       (NOW() + INTERVAL '20 days')::DATE, 2, 0),

      (COALESCE(user_id_2, user_id_1), semeru_id,
       'Tek-tok Semeru weekend, butuh 3 buddies',
       'Berangkat Jumat malam dari Malang, balik Minggu pagi. Pengalaman minimal Merapi/Lawu.',
       (NOW() + INTERVAL '12 days')::DATE, 3, 1),

      (user_id_1, prau_id,
       'Pemula yang mau coba Prau? Yuk!',
       'Trek pendek, view oke. Aku juga masih pemula, biar saling support.',
       (NOW() + INTERVAL '6 days')::DATE, 4, 1)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


-- ─────────────────────────────────────────────────────────────
-- VERIFY
-- ─────────────────────────────────────────────────────────────
SELECT 'mountains' AS tbl, COUNT(*) AS rows FROM mountains
UNION ALL SELECT 'open_trips', COUNT(*) FROM open_trips
UNION ALL SELECT 'events', COUNT(*) FROM events
UNION ALL SELECT 'rental_vendors', COUNT(*) FROM rental_vendors
UNION ALL SELECT 'communities', COUNT(*) FROM communities
UNION ALL SELECT 'buddy_posts', COUNT(*) FROM buddy_posts;
