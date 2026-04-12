import 'package:postgres/postgres.dart';
import 'package:petualang_server/utils/env_config.dart';

class Database {
  static PostgreSQLConnection? _connection;

  static Future<PostgreSQLConnection> get connection async {
    if (_connection == null || _connection!.isClosed) {
      await _connect();
    }
    return _connection!;
  }

  static Future<void> _connect() async {
    try {
      _connection = PostgreSQLConnection(
        EnvConfig.dbHost,
        EnvConfig.dbPort,
        EnvConfig.dbName,
        username: EnvConfig.dbUser,
        password: EnvConfig.dbPassword,
      );
      
      print('⏳ Connecting to PostgreSQL at ${EnvConfig.dbHost}:${EnvConfig.dbPort}...');
      await _connection!.open();
      print('✅ Connected to PostgreSQL database: ${EnvConfig.dbName}');
      await _runMigrations();
    } catch (e) {
      print('❌ Database Connection Error: $e');
      print('⚠️ Please check your .env configuration and make sure PostgreSQL is running.');
      // Don't rethrow if we want the server to still start, but in this app 
      // most routes need DB, so we let it fail or just log it.
    }
  }

  static Future<void> _runMigrations() async {
    final conn = _connection!;

    // Create users table if not exists
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(150) UNIQUE NOT NULL,
        phone VARCHAR(20),
        password_hash VARCHAR(255) NOT NULL,
        password_salt VARCHAR(100) NOT NULL,
        profile_picture TEXT,
        reset_token VARCHAR(100),
        reset_token_expires_at TIMESTAMPTZ,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    // Add columns to users table if they don't exist
    await conn.execute('''
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS reset_token VARCHAR(100),
      ADD COLUMN IF NOT EXISTS reset_token_expires_at TIMESTAMPTZ,
      ADD COLUMN IF NOT EXISTS nik VARCHAR(20),
      ADD COLUMN IF NOT EXISTS date_of_birth DATE,
      ADD COLUMN IF NOT EXISTS gender VARCHAR(10),
      ADD COLUMN IF NOT EXISTS ktp_address TEXT,
      ADD COLUMN IF NOT EXISTS domicile_address TEXT,
      ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(100),
      ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(20),
      ADD COLUMN IF NOT EXISTS height_cm INTEGER,
      ADD COLUMN IF NOT EXISTS weight_kg INTEGER;
    ''');

    // Create refresh_tokens table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS refresh_tokens (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        token TEXT NOT NULL UNIQUE,
        expires_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    // Create mountains table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS mountains (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE,
        location VARCHAR(150) NOT NULL,
        elevation INTEGER NOT NULL,
        difficulty VARCHAR(50) NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        image_url TEXT NOT NULL,
        description TEXT NOT NULL
      );
    ''');

    // Create mountain_routes table (Jalur Pendakian)
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS mountain_routes (
        id SERIAL PRIMARY KEY,
        mountain_id INTEGER REFERENCES mountains(id) ON DELETE CASCADE,
        name VARCHAR(150) NOT NULL,
        description TEXT,
        UNIQUE (mountain_id, name)
      );
    ''');

    // Create tickets table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS tickets (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        mountain_id INTEGER REFERENCES mountains(id) ON DELETE CASCADE,
        mountain_route_id INTEGER REFERENCES mountain_routes(id) ON DELETE SET NULL,
        booking_code VARCHAR(50) NOT NULL UNIQUE,
        date TIMESTAMPTZ NOT NULL,
        climbers_count INTEGER NOT NULL,
        total_price DECIMAL(10, 2) NOT NULL,
        status VARCHAR(50) DEFAULT 'success',
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    // ============================================================
    // KOMUNITAS TABLES
    // ============================================================
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS communities (
        id SERIAL PRIMARY KEY,
        name VARCHAR(150) NOT NULL,
        slug VARCHAR(150) NOT NULL UNIQUE,
        description TEXT,
        cover_image_url TEXT,
        icon_image_url TEXT,
        category VARCHAR(100),
        privacy VARCHAR(20) DEFAULT 'public',
        member_count INTEGER DEFAULT 0,
        post_count INTEGER DEFAULT 0,
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS community_members (
        id SERIAL PRIMARY KEY,
        community_id INTEGER REFERENCES communities(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        role VARCHAR(20) DEFAULT 'member',
        joined_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (community_id, user_id)
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS community_posts (
        id SERIAL PRIMARY KEY,
        community_id INTEGER REFERENCES communities(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        image_url TEXT,
        like_count INTEGER DEFAULT 0,
        comment_count INTEGER DEFAULT 0,
        is_pinned BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS community_comments (
        id SERIAL PRIMARY KEY,
        post_id INTEGER REFERENCES community_posts(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        parent_id INTEGER REFERENCES community_comments(id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        image_url TEXT,
        like_count INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    // Add column if not exists (for existing tables)
    await conn.execute('''
      ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS image_url TEXT;
      ALTER TABLE community_comments ADD COLUMN IF NOT EXISTS image_url TEXT;
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS community_likes (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        post_id INTEGER REFERENCES community_posts(id) ON DELETE CASCADE,
        comment_id INTEGER REFERENCES community_comments(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (user_id, post_id),
        UNIQUE (user_id, comment_id)
      );
    ''');

    // ============================================================
    // CHAT TABLES
    // ============================================================
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS chat_conversations (
        id SERIAL PRIMARY KEY,
        community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (community_id)
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id SERIAL PRIMARY KEY,
        conversation_id INTEGER REFERENCES chat_conversations(id) ON DELETE CASCADE,
        sender_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        type VARCHAR(20) DEFAULT 'text',
        content TEXT NOT NULL,
        image_url TEXT,
        is_deleted BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS chat_read_status (
        id SERIAL PRIMARY KEY,
        conversation_id INTEGER REFERENCES chat_conversations(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        last_read_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (conversation_id, user_id)
      );
    ''');

    // ============================================================
    // REPORT TABLE
    // ============================================================
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS reports (
        id SERIAL PRIMARY KEY,
        reporter_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        reason VARCHAR(200) NOT NULL,
        post_id INTEGER REFERENCES community_posts(id) ON DELETE CASCADE,
        comment_id INTEGER REFERENCES community_comments(id) ON DELETE CASCADE,
        message_id INTEGER REFERENCES chat_messages(id) ON DELETE CASCADE,
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    // ============================================================
    // RENTAL ALAT TABLES
    // ============================================================
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS rental_vendors (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        mountain_id INTEGER REFERENCES mountains(id) ON DELETE CASCADE,
        name VARCHAR(150) NOT NULL,
        contact_phone VARCHAR(20),
        address TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await conn.execute('''
      ALTER TABLE rental_vendors 
      ADD COLUMN IF NOT EXISTS rating DECIMAL(3, 1) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0,
      ADD COLUMN IF NOT EXISTS is_open BOOLEAN DEFAULT TRUE,
      ADD COLUMN IF NOT EXISTS image_url TEXT,
      ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 6),
      ADD COLUMN IF NOT EXISTS longitude DECIMAL(10, 6);
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS rental_items (
        id SERIAL PRIMARY KEY,
        vendor_id INTEGER REFERENCES rental_vendors(id) ON DELETE CASCADE,
        mountain_id INTEGER REFERENCES mountains(id) ON DELETE CASCADE,
        name VARCHAR(150) NOT NULL,
        category VARCHAR(50) NOT NULL,
        description TEXT,
        price_per_day DECIMAL(10, 2) NOT NULL,
        image_url TEXT,
        stock INTEGER DEFAULT 0,
        available_stock INTEGER DEFAULT 0,
        brand VARCHAR(100),
        condition VARCHAR(50) DEFAULT 'Baik',
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await conn.execute('''
      ALTER TABLE rental_items 
      ADD COLUMN IF NOT EXISTS vendor_id INTEGER REFERENCES rental_vendors(id) ON DELETE CASCADE,
      ADD COLUMN IF NOT EXISTS mountain_id INTEGER REFERENCES mountains(id) ON DELETE CASCADE;
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS rentals (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        mountain_id INTEGER REFERENCES mountains(id) ON DELETE SET NULL,
        entry_route_id INTEGER REFERENCES mountain_routes(id) ON DELETE SET NULL,
        exit_route_id INTEGER REFERENCES mountain_routes(id) ON DELETE SET NULL,
        rental_code VARCHAR(50) NOT NULL UNIQUE,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        total_price DECIMAL(10, 2) NOT NULL,
        delivery_fee DECIMAL(10, 2) DEFAULT 0,
        status VARCHAR(30) DEFAULT 'pending',
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await conn.execute('''
      ALTER TABLE rentals 
      ADD COLUMN IF NOT EXISTS mountain_id INTEGER REFERENCES mountains(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS entry_route_id INTEGER REFERENCES mountain_routes(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS exit_route_id INTEGER REFERENCES mountain_routes(id) ON DELETE SET NULL,
      ADD COLUMN IF NOT EXISTS delivery_fee DECIMAL(10, 2) DEFAULT 0;
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS rental_details (
        id SERIAL PRIMARY KEY,
        rental_id INTEGER REFERENCES rentals(id) ON DELETE CASCADE,
        item_id INTEGER REFERENCES rental_items(id),
        quantity INTEGER NOT NULL,
        price_per_day DECIMAL(10, 2) NOT NULL,
        subtotal DECIMAL(10, 2) NOT NULL
      );
    ''');

    // ============================================================
    // EXPLORE TABLES
    // ============================================================
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS open_trips (
        id SERIAL PRIMARY KEY,
        mountain_id INTEGER REFERENCES mountains(id) ON DELETE CASCADE,
        organizer_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        title VARCHAR(200) NOT NULL,
        description TEXT,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        max_participants INTEGER DEFAULT 10,
        current_participants INTEGER DEFAULT 0,
        status VARCHAR(30) DEFAULT 'open',
        image_url TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS articles (
        id SERIAL PRIMARY KEY,
        title VARCHAR(200) NOT NULL,
        content TEXT NOT NULL,
        category VARCHAR(50) DEFAULT 'Tips',
        image_url TEXT,
        author VARCHAR(100),
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS open_trip_bookings (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        open_trip_id INTEGER REFERENCES open_trips(id) ON DELETE CASCADE,
        booking_code VARCHAR(50) NOT NULL UNIQUE,
        payment_status VARCHAR(30) DEFAULT 'unpaid',
        total_price DECIMAL(10, 2) NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (user_id, open_trip_id)
      );
    ''');

    // ============================================================
    // INDEXES
    // ============================================================
    await conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_messages_conv 
        ON chat_messages(conversation_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_posts_community 
        ON community_posts(community_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_community_members_user 
        ON community_members(user_id);
    ''');

    // Seed data
    await conn.execute('''
      INSERT INTO mountains (name, location, elevation, difficulty, price, image_url, description)
      VALUES 
        ('Gunung Rinjani', 'Lombok, Nusa Tenggara Barat', 3726, 'Sulit', 250000.00, 'assets/images/mountain_rinjani.png', 'Gunung Rinjani adalah gunung yang berlokasi di Pulau Lombok, Nusa Tenggara Barat. Gunung yang merupakan gunung berapi kedua tertinggi di Indonesia ini merupakan primadona bagi pendaki karena keindahannya, terutama danau kawah Segara Anak yang luar biasa mempesona.'),
        ('Gunung Semeru', 'Jawa Timur', 3676, 'Sulit', 150000.00, 'assets/images/mountain_semeru.png', 'Gunung Semeru adalah gunung berapi kerucut di Jawa Timur, Indonesia. Puncak Mahameru memancarkan pesona megah. Jalur pendakian di Semeru dikelilingi padang savana, danau Ranu Kumbolo, dan pesona edelweiss yang legendaris.')
      ON CONFLICT (name) DO NOTHING;
    ''');

    // Seed routes data
    await conn.execute('''
      INSERT INTO mountain_routes (mountain_id, name, description)
      SELECT id, 'Jalur Sembalun', 'Jalur ini populer karena pemandangan savana yang luas dan jalur yang cenderung landai di awal.' FROM mountains WHERE name = 'Gunung Rinjani'
      ON CONFLICT DO NOTHING;
      INSERT INTO mountain_routes (mountain_id, name, description)
      SELECT id, 'Jalur Senaru', 'Jalur ini lebih teduh dengan banyak pepohonan hutan tropis namun menanjak terjal.' FROM mountains WHERE name = 'Gunung Rinjani'
      ON CONFLICT DO NOTHING;
      INSERT INTO mountain_routes (mountain_id, name, description)
      SELECT id, 'Jalur Ranu Pani-Kalimati', 'Jalur utama menuju puncak Semeru dengan melewati danau legendaris Ranu Kumbolo.' FROM mountains WHERE name = 'Gunung Semeru'
      ON CONFLICT DO NOTHING;
      INSERT INTO mountain_routes (mountain_id, name, description)
      SELECT id, 'Jalur Watu Rejeng', 'Jalur alternatif yang menawarkan pemandangan tebing batu yang megah.' FROM mountains WHERE name = 'Gunung Semeru'
      ON CONFLICT DO NOTHING;
    ''');

    // Seed komunitas data
    await conn.execute('''
      INSERT INTO communities (name, slug, description, category, privacy, cover_image_url)
      VALUES
        ('Pendaki Rinjani', 'pendaki-rinjani', 'Komunitas para pendaki dan pecinta Gunung Rinjani. Berbagi pengalaman, tips, dan jadwal pendakian bersama.', 'Pendakian', 'public', null),
        ('Campers Nusantara', 'campers-nusantara', 'Tempat berkumpul para pecinta camping dari seluruh Nusantara. Share spot camping, gear review, dan trip bareng!', 'Camping', 'public', null),
        ('Fotografi Alam Liar', 'fotografi-alam-liar', 'Komunitas fotografer alam dan wildlife. Bagikan karya terbaik dan tips fotografi di alam terbuka.', 'Fotografi', 'public', null)
      ON CONFLICT (slug) DO NOTHING;
    ''');

    // Create chat conversations for each community
    await conn.execute('''
      INSERT INTO chat_conversations (community_id)
      SELECT id FROM communities
      ON CONFLICT (community_id) DO NOTHING;
    ''');

    // Seed / Upsert data untuk rental vendor
    // Use ON CONFLICT DO UPDATE so data always stays fresh on restart
    // First, clean up any existing duplicates that might prevent index creation
    await conn.execute('''
      DELETE FROM rental_vendors a USING rental_vendors b
      WHERE a.id > b.id AND a.name = b.name;
    ''');

    // Then ensure unique constraint exists
    await conn.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_rental_vendors_name ON rental_vendors (name);
    ''');

    await conn.execute('''
      INSERT INTO rental_vendors (name, mountain_id, contact_phone, address, rating, review_count, is_open, image_url, latitude, longitude)
      SELECT 'Rinjani Outdoor Rental', id, '08123456789', 'Jl. Raya Sembalun No.1, Sembalun Lawang, Lombok Timur, Nusa Tenggara Barat', 4.8, 120, TRUE, 'assets/images/rental_store_2.png', -8.361548, 116.518606 FROM mountains WHERE name = 'Gunung Rinjani'
      ON CONFLICT (name) DO UPDATE SET address = EXCLUDED.address, image_url = EXCLUDED.image_url, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude;

      INSERT INTO rental_vendors (name, mountain_id, contact_phone, address, rating, review_count, is_open, image_url, latitude, longitude)
      SELECT 'Semeru Outdoor Services', id, '08987654321', 'Ranu Pani, Senduro, Lumajang, Jawa Timur 67373', 4.5, 80, FALSE, 'assets/images/rental_store_3.png', -7.942732, 112.618685 FROM mountains WHERE name = 'Gunung Semeru'
      ON CONFLICT (name) DO UPDATE SET address = EXCLUDED.address, image_url = EXCLUDED.image_url, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude;
    ''');

    await conn.execute('''
      INSERT INTO rental_vendors (name, mountain_id, contact_phone, address, rating, review_count, is_open, image_url, latitude, longitude)
      VALUES
        ('Basecamp Adventure Store', NULL, '085512341234', 'Jl. MH Thamrin No.1, Menteng, Jakarta Pusat, DKI Jakarta 10310', 4.9, 210, TRUE, 'assets/images/store_jakarta.png', -6.208763, 106.845599),
        ('Summit Gear Indonesia', NULL, '08111222333', 'Jl. Ir. H. Juanda No.15, Dago, Bandung Utara, Jawa Barat 40132', 4.7, 150, TRUE, 'assets/images/store_bandung.png', -6.890333, 107.610214),
        ('Malioboro Outdoor', NULL, '082212341234', 'Jl. Malioboro No.52, Gedongtengen, Kota Yogyakarta, DIY 55213', 4.8, 205, TRUE, 'assets/images/store_yogya.png', -7.797068, 110.370529),
        ('Lumpia Adventure Camp', NULL, '083312341234', 'Jl. Pahlawan No.10, Simpang Lima, Semarang Tengah, Jawa Tengah 50243', 4.6, 95, TRUE, 'assets/images/store_semarang.png', -6.981822, 110.420822),
        ('Pahlawan Rent Gear', NULL, '084412341234', 'Jl. Tunjungan No.1, Genteng, Surabaya, Jawa Timur 60275', 4.9, 320, TRUE, 'assets/images/store_surabaya.png', -7.265691, 112.743152),
        ('Osing Trekking Center', NULL, '085512341234', 'Jl. Ahmad Yani No.105, Taman Baru, Banyuwangi, Jawa Timur 68416', 4.8, 140, TRUE, 'assets/images/store_banyuwangi.png', -8.219233, 114.369227)
      ON CONFLICT (name) DO UPDATE SET
        address = EXCLUDED.address,
        contact_phone = EXCLUDED.contact_phone,
        rating = EXCLUDED.rating,
        review_count = EXCLUDED.review_count,
        is_open = EXCLUDED.is_open,
        image_url = EXCLUDED.image_url,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude;
    ''');


    await conn.execute('''
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Tenda Dome 4P', 'TENDA', 'Tenda kapasitas 4 orang, double layer tahan hujan.', 50000.00, 'assets/images/rental_tenda_1775786628804.png', 10, 10, 'Consina', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Rinjani Outdoor Rental'
      ON CONFLICT DO NOTHING;
      
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Carrier 60L', 'CARRIER', 'Tas punggung gunung kapasitas besar 60 Liter.', 40000.00, 'assets/images/rental_carrier_1775786645881.png', 15, 15, 'Eiger', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Rinjani Outdoor Rental'
      ON CONFLICT DO NOTHING;

      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Sleeping Bag Polar', 'SLEEPING BAG', 'Kantung tidur tebal dan hangat.', 25000.00, 'assets/images/rental_sb_1775786660007.png', 20, 20, 'Arei', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Basecamp Adventure Store'
      ON CONFLICT DO NOTHING;

      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Sepatu Trekking', 'SEPATU', 'Sepatu anti slip untuk medan terjal.', 35000.00, 'assets/images/rental_tenda_1775786628804.png', 15, 15, 'Eiger', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Basecamp Adventure Store'
      ON CONFLICT DO NOTHING;
      
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Sleeping Bag Polar', 'Shelter', 'Kantung tidur tebal.', 15000.00, 'assets/images/rental_sb_1775786660007.png', 20, 20, 'Arei', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Semeru Outdoor Services'
      ON CONFLICT DO NOTHING;
      
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Kompor Portable', 'COOKING', 'Kompor lipat kecil untk pendakian, ringan dan praktis.', 15000.00, 'assets/images/rental_kompor_1775786676160.png', 12, 12, 'Kovar', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Semeru Outdoor Services'
      ON CONFLICT DO NOTHING;

      -- Bandung
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Tenda Pramuka', 'TENDA', 'Tenda klasik untuk grup besar', 75000.00, 'assets/images/rental_tenda_1775786628804.png', 5, 5, 'Local', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Summit Gear Indonesia'
      ON CONFLICT DO NOTHING;
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Nesting Set', 'COOKING', 'Alat masak komplit 4 orang', 25000.00, 'assets/images/rental_kompor_1775786676160.png', 15, 15, 'DS300', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Summit Gear Indonesia'
      ON CONFLICT DO NOTHING;

      -- Yogya
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Matras Foil', 'MATRAS', 'Matras hangat anti dingin', 10000.00, 'assets/images/rental_sb_1775786660007.png', 30, 30, 'Klymit', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Malioboro Outdoor'
      ON CONFLICT DO NOTHING;
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Tenda Kapasitas 2', 'TENDA', 'Tenda ringan 2 orang', 35000.00, 'assets/images/rental_tenda_1775786628804.png', 12, 12, 'Eiger', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Malioboro Outdoor'
      ON CONFLICT DO NOTHING;

      -- Semarang
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Headlamp LED', 'PENERANGAN', 'Lampu kepala sangat terang', 15000.00, 'assets/images/rental_tenda_1775786628804.png', 25, 25, 'Energizer', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Lumpia Adventure Camp'
      ON CONFLICT DO NOTHING;
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Tenda Lapisan Ganda', 'TENDA', 'Tenda dome 4 orang', 45000.00, 'assets/images/rental_tenda_1775786628804.png', 8, 8, 'Consina', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Lumpia Adventure Camp'
      ON CONFLICT DO NOTHING;

      -- Surabaya
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Sepatu Gunung', 'SEPATU', 'Sepatu kokoh vibram', 40000.00, 'assets/images/rental_tenda_1775786628804.png', 20, 20, 'Arei', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Pahlawan Rent Gear'
      ON CONFLICT DO NOTHING;
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Jaket Gunung', 'PAKAIAN', 'Jaket waterproof dan windproof', 30000.00, 'assets/images/rental_sb_1775786660007.png', 15, 15, 'Eiger', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Pahlawan Rent Gear'
      ON CONFLICT DO NOTHING;
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Carrier 40L', 'CARRIER', 'Tas gunung medium', 35000.00, 'assets/images/rental_carrier_1775786645881.png', 12, 12, 'Osprey', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Pahlawan Rent Gear'
      ON CONFLICT DO NOTHING;

      -- Banyuwangi
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Tenda Raung', 'TENDA', 'Tenda siap badai Raung', 60000.00, 'assets/images/rental_tenda_1775786628804.png', 5, 5, 'Naturehike', 'Sangat Baik'
      FROM rental_vendors v WHERE v.name = 'Osing Trekking Center'
      ON CONFLICT DO NOTHING;
      INSERT INTO rental_items (vendor_id, mountain_id, name, category, description, price_per_day, image_url, stock, available_stock, brand, condition)
      SELECT v.id, v.mountain_id, 'Kompor Gas Lipat', 'COOKING', 'Include gas', 25000.00, 'assets/images/rental_kompor_1775786676160.png', 10, 10, 'Kovar', 'Baik'
      FROM rental_vendors v WHERE v.name = 'Osing Trekking Center'
      ON CONFLICT DO NOTHING;
    ''');

    // Seed Open Trips data
    await conn.execute('''
      INSERT INTO open_trips (mountain_id, organizer_id, title, description, start_date, end_date, price, max_participants, current_participants, status, image_url)
      SELECT id, NULL, 'Ekspedisi Puncak Segara Anak', 'Pendakian santai 4 Hari 3 Malam menikmati indahnya Danau Segara Anak dan Puncak Rinjani.', CURRENT_DATE + INTERVAL '14 days', CURRENT_DATE + INTERVAL '17 days', 1500000.00, 15, 8, 'open', 'assets/images/event_1.png'
      FROM mountains WHERE name = 'Gunung Rinjani'
      ON CONFLICT DO NOTHING;

      INSERT INTO open_trips (mountain_id, organizer_id, title, description, start_date, end_date, price, max_participants, current_participants, status, image_url)
      SELECT id, NULL, 'Tek-Tok Semeru (Muncak Cepat)', 'Pendakian cepat untuk yang sudah berpengalaman. 2 Hari 1 Malam menuju Mahameru.', CURRENT_DATE + INTERVAL '21 days', CURRENT_DATE + INTERVAL '22 days', 900000.00, 10, 5, 'open', 'assets/images/mountain_semeru.png'
      FROM mountains WHERE name = 'Gunung Semeru'
      ON CONFLICT DO NOTHING;
    ''');

    // Seed Articles data
    await conn.execute('''
      INSERT INTO articles (title, content, category, image_url, author)
      VALUES 
      ('Tips Packing Carrier agar Punggung Tidak Pegal', 'Packing yang benar sangat krusial. Letakkan barang berat di tengah dekat punggung, barang ringan di bawah (seperti sleeping bag), dan barang yang sering dipakai di bagian paling atas atau kantong luar.', 'Tips', 'assets/images/rental_carrier_1775786645881.png', 'Tim Petualang'),
      ('Mengenal Gejala Hipotermia dan Cara Mengatasinya', 'Hipotermia terjadi saat suhu tubuh turun drastis. Gejalanya mulai dari menggigil hebat, meracau, hingga kehilangan kesadaran. Segera ganti pakaian basah korban, lapisi tubuh dengan thermal blanket, beri minuman hangat manis jika masih sadar, dan peluk korban kulit-ke-kulit jika perlu.', 'Edukasi', 'assets/images/mountain_rinjani.png', 'Dr. Gunung')
      ON CONFLICT DO NOTHING;
    ''');

    print('✅ Database migrations completed');
  }

  static Future<void> close() async {
    if (_connection != null && !_connection!.isClosed) {
      await _connection!.close();
    }
  }
}
