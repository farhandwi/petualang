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
      ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS share_count INTEGER DEFAULT 0;
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
    // DM (DIRECT MESSAGE) TABLES
    // ============================================================
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS dm_conversations (
        id SERIAL PRIMARY KEY,
        user1_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        user2_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (user1_id, user2_id)
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS dm_messages (
        id SERIAL PRIMARY KEY,
        dm_conversation_id INTEGER REFERENCES dm_conversations(id) ON DELETE CASCADE,
        sender_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        type VARCHAR(20) DEFAULT 'text',
        content TEXT NOT NULL,
        image_url TEXT,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS dm_blocks (
        id SERIAL PRIMARY KEY,
        blocker_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        blocked_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (blocker_id, blocked_id)
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
        ('Osing Trekking Center', NULL, '085512341234', 'Jl. Ahmad Yani No.105, Taman Baru, Banyuwangi, Jawa Timur 68416', 4.8, 140, TRUE, 'assets/images/store_banyuwangi.png', -8.219233, 114.369227),
        ('Dummy Gear Camping Bandung 1', NULL, '084163119785', 'Jl. Dummy No. 1, Bandung', 4.5, 466, TRUE, 'assets/images/store_jakarta.png', -6.964999, 107.596603),
        ('Dummy Gear Gear Padang 2', NULL, '089703905715', 'Jl. Dummy No. 2, Padang', 3.8, 342, TRUE, 'assets/images/store_jakarta.png', -0.957008, 100.307280),
        ('Dummy Outdoor Camping Semarang 3', NULL, '088293453178', 'Jl. Dummy No. 3, Semarang', 4.0, 89, FALSE, 'assets/images/store_jakarta.png', -6.998279, 110.398119),
        ('Dummy Trek Trek Denpasar 4', NULL, '087887950851', 'Jl. Dummy No. 4, Denpasar', 4.7, 383, TRUE, 'assets/images/store_jakarta.png', -8.710279, 115.200793),
        ('Dummy Adventure Summit Medan 5', NULL, '081298737106', 'Jl. Dummy No. 5, Medan', 4.5, 405, TRUE, 'assets/images/store_jakarta.png', 3.557683, 98.714430),
        ('Dummy Camp Rental Bandung 6', NULL, '088877444318', 'Jl. Dummy No. 6, Bandung', 3.7, 191, FALSE, 'assets/images/store_jakarta.png', -6.881968, 107.655748),
        ('Dummy Adventure Basecamp Surabaya 7', NULL, '083727210979', 'Jl. Dummy No. 7, Surabaya', 4.3, 135, FALSE, 'assets/images/store_jakarta.png', -7.230218, 112.787155),
        ('Dummy Summit Gear Makassar 8', NULL, '088235363119', 'Jl. Dummy No. 8, Makassar', 4.8, 407, TRUE, 'assets/images/store_jakarta.png', -5.159654, 119.481652),
        ('Dummy Camp Rental Semarang 9', NULL, '081284277889', 'Jl. Dummy No. 9, Semarang', 4.9, 300, TRUE, 'assets/images/store_jakarta.png', -6.961020, 110.450805),
        ('Dummy Hike Camping Semarang 10', NULL, '082137651678', 'Jl. Dummy No. 10, Semarang', 3.9, 297, TRUE, 'assets/images/store_jakarta.png', -6.977656, 110.409863),
        ('Dummy Trek Gear Padang 11', NULL, '083119634399', 'Jl. Dummy No. 11, Padang', 4.6, 450, TRUE, 'assets/images/store_jakarta.png', -0.956357, 100.362653),
        ('Dummy Camp Basecamp Yogyakarta 12', NULL, '085567816720', 'Jl. Dummy No. 12, Yogyakarta', 4.1, 249, TRUE, 'assets/images/store_jakarta.png', -7.782855, 110.398708),
        ('Dummy Adventure Summit Medan 13', NULL, '088519962896', 'Jl. Dummy No. 13, Medan', 4.7, 184, TRUE, 'assets/images/store_jakarta.png', 3.631278, 98.623348),
        ('Dummy Rental Summit Surabaya 14', NULL, '084272602734', 'Jl. Dummy No. 14, Surabaya', 4.3, 64, TRUE, 'assets/images/store_jakarta.png', -7.256923, 112.764172),
        ('Dummy Camping Summit Medan 15', NULL, '084944899549', 'Jl. Dummy No. 15, Medan', 4.4, 260, TRUE, 'assets/images/store_jakarta.png', 3.606097, 98.637484),
        ('Dummy Rental Gear Bandung 16', NULL, '081248786714', 'Jl. Dummy No. 16, Bandung', 4.8, 494, TRUE, 'assets/images/store_jakarta.png', -6.874590, 107.656972),
        ('Dummy Summit Camping Bandung 17', NULL, '083361388464', 'Jl. Dummy No. 17, Bandung', 3.9, 456, TRUE, 'assets/images/store_jakarta.png', -6.894309, 107.650702),
        ('Dummy Gear Rental Semarang 18', NULL, '086898796145', 'Jl. Dummy No. 18, Semarang', 4.8, 241, TRUE, 'assets/images/store_jakarta.png', -6.950309, 110.445827),
        ('Dummy Basecamp Summit Semarang 19', NULL, '081945826486', 'Jl. Dummy No. 19, Semarang', 3.6, 333, TRUE, 'assets/images/store_jakarta.png', -7.020730, 110.404109),
        ('Dummy Trek Adventure Semarang 20', NULL, '083208283728', 'Jl. Dummy No. 20, Semarang', 3.9, 258, FALSE, 'assets/images/store_jakarta.png', -7.036460, 110.373441),
        ('Dummy Basecamp Basecamp Medan 21', NULL, '083030106617', 'Jl. Dummy No. 21, Medan', 4.7, 423, TRUE, 'assets/images/store_jakarta.png', 3.558431, 98.715751),
        ('Dummy Trek Camp Semarang 22', NULL, '087060638140', 'Jl. Dummy No. 22, Semarang', 4.8, 37, TRUE, 'assets/images/store_jakarta.png', -7.033767, 110.436198),
        ('Dummy Adventure Gear Jakarta 23', NULL, '081822873088', 'Jl. Dummy No. 23, Jakarta', 4.3, 81, TRUE, 'assets/images/store_jakarta.png', -6.218538, 106.829530),
        ('Dummy Adventure Hike Yogyakarta 24', NULL, '081420514789', 'Jl. Dummy No. 24, Yogyakarta', 4.5, 286, TRUE, 'assets/images/store_jakarta.png', -7.817745, 110.344481),
        ('Dummy Camping Camp Bandung 25', NULL, '087380780055', 'Jl. Dummy No. 25, Bandung', 3.8, 215, TRUE, 'assets/images/store_jakarta.png', -6.874863, 107.653970),
        ('Dummy Rental Hike Yogyakarta 26', NULL, '086520103410', 'Jl. Dummy No. 26, Yogyakarta', 4.5, 384, TRUE, 'assets/images/store_jakarta.png', -7.807703, 110.418031),
        ('Dummy Outdoor Basecamp Yogyakarta 27', NULL, '089851745355', 'Jl. Dummy No. 27, Yogyakarta', 4.0, 35, TRUE, 'assets/images/store_jakarta.png', -7.826610, 110.341270),
        ('Dummy Outdoor Summit Medan 28', NULL, '081798112150', 'Jl. Dummy No. 28, Medan', 4.4, 355, FALSE, 'assets/images/store_jakarta.png', 3.637139, 98.675313),
        ('Dummy Gear Basecamp Banjarmasin 29', NULL, '083553440342', 'Jl. Dummy No. 29, Banjarmasin', 4.4, 224, TRUE, 'assets/images/store_jakarta.png', -3.357411, 114.629129),
        ('Dummy Gear Rental Surabaya 30', NULL, '082699887270', 'Jl. Dummy No. 30, Surabaya', 4.5, 163, TRUE, 'assets/images/store_jakarta.png', -7.279974, 112.790419),
        ('Dummy Outdoor Hike Denpasar 31', NULL, '081429416213', 'Jl. Dummy No. 31, Denpasar', 4.3, 269, TRUE, 'assets/images/store_jakarta.png', -8.627598, 115.256373),
        ('Dummy Gear Trek Yogyakarta 32', NULL, '082224011538', 'Jl. Dummy No. 32, Yogyakarta', 4.2, 288, TRUE, 'assets/images/store_jakarta.png', -7.752274, 110.407586),
        ('Dummy Summit Outdoor Padang 33', NULL, '087676965974', 'Jl. Dummy No. 33, Padang', 4.9, 63, FALSE, 'assets/images/store_jakarta.png', -0.900815, 100.385010),
        ('Dummy Summit Camping Surabaya 34', NULL, '086464693977', 'Jl. Dummy No. 34, Surabaya', 4.4, 377, TRUE, 'assets/images/store_jakarta.png', -7.288857, 112.729504),
        ('Dummy Summit Hike Semarang 35', NULL, '081218179599', 'Jl. Dummy No. 35, Semarang', 4.5, 434, TRUE, 'assets/images/store_jakarta.png', -6.974450, 110.455591),
        ('Dummy Rental Camping Jakarta 36', NULL, '088478529823', 'Jl. Dummy No. 36, Jakarta', 4.3, 228, TRUE, 'assets/images/store_jakarta.png', -6.258445, 106.872712),
        ('Dummy Camping Summit Bandung 37', NULL, '083373077218', 'Jl. Dummy No. 37, Bandung', 4.1, 31, TRUE, 'assets/images/store_jakarta.png', -6.959976, 107.657411),
        ('Dummy Outdoor Trek Denpasar 38', NULL, '085736462531', 'Jl. Dummy No. 38, Denpasar', 4.7, 462, TRUE, 'assets/images/store_jakarta.png', -8.630602, 115.242412),
        ('Dummy Gear Camping Padang 39', NULL, '084482238042', 'Jl. Dummy No. 39, Padang', 4.8, 22, FALSE, 'assets/images/store_jakarta.png', -0.924252, 100.396876),
        ('Dummy Gear Rental Denpasar 40', NULL, '084011966884', 'Jl. Dummy No. 40, Denpasar', 4.1, 29, TRUE, 'assets/images/store_jakarta.png', -8.642261, 115.203971),
        ('Dummy Trek Rental Semarang 41', NULL, '084742303947', 'Jl. Dummy No. 41, Semarang', 3.8, 347, FALSE, 'assets/images/store_jakarta.png', -7.023243, 110.462145),
        ('Dummy Rental Trek Banjarmasin 42', NULL, '087597996327', 'Jl. Dummy No. 42, Banjarmasin', 4.9, 69, TRUE, 'assets/images/store_jakarta.png', -3.336574, 114.626535),
        ('Dummy Outdoor Adventure Yogyakarta 43', NULL, '087857221324', 'Jl. Dummy No. 43, Yogyakarta', 4.0, 412, TRUE, 'assets/images/store_jakarta.png', -7.787541, 110.417855),
        ('Dummy Camp Basecamp Banjarmasin 44', NULL, '086111349421', 'Jl. Dummy No. 44, Banjarmasin', 3.6, 233, TRUE, 'assets/images/store_jakarta.png', -3.308779, 114.591242),
        ('Dummy Gear Trek Medan 45', NULL, '082852408227', 'Jl. Dummy No. 45, Medan', 4.9, 481, TRUE, 'assets/images/store_jakarta.png', 3.637758, 98.676045),
        ('Dummy Rental Summit Padang 46', NULL, '087049001493', 'Jl. Dummy No. 46, Padang', 4.1, 161, FALSE, 'assets/images/store_jakarta.png', -0.967808, 100.389102),
        ('Dummy Camping Basecamp Semarang 47', NULL, '087739255769', 'Jl. Dummy No. 47, Semarang', 4.1, 436, TRUE, 'assets/images/store_jakarta.png', -7.001155, 110.464336),
        ('Dummy Basecamp Basecamp Surabaya 48', NULL, '088106906538', 'Jl. Dummy No. 48, Surabaya', 4.2, 236, FALSE, 'assets/images/store_jakarta.png', -7.271709, 112.761789),
        ('Dummy Camping Adventure Medan 49', NULL, '087954672204', 'Jl. Dummy No. 49, Medan', 3.6, 497, FALSE, 'assets/images/store_jakarta.png', 3.592519, 98.712318),
        ('Dummy Outdoor Outdoor Surabaya 50', NULL, '085607762160', 'Jl. Dummy No. 50, Surabaya', 4.1, 332, FALSE, 'assets/images/store_jakarta.png', -7.277936, 112.738713),
        ('Dummy Outdoor Adventure Banjarmasin 51', NULL, '088638257497', 'Jl. Dummy No. 51, Banjarmasin', 3.8, 421, TRUE, 'assets/images/store_jakarta.png', -3.319962, 114.564498),
        ('Dummy Adventure Hike Jakarta 52', NULL, '088995059760', 'Jl. Dummy No. 52, Jakarta', 4.2, 394, FALSE, 'assets/images/store_jakarta.png', -6.203059, 106.887347),
        ('Dummy Gear Rental Surabaya 53', NULL, '082889238423', 'Jl. Dummy No. 53, Surabaya', 4.6, 130, TRUE, 'assets/images/store_jakarta.png', -7.223819, 112.770930),
        ('Dummy Camping Camping Denpasar 54', NULL, '086288227800', 'Jl. Dummy No. 54, Denpasar', 4.5, 371, FALSE, 'assets/images/store_jakarta.png', -8.688529, 115.216815),
        ('Dummy Hike Camp Bandung 55', NULL, '081267429212', 'Jl. Dummy No. 55, Bandung', 4.7, 209, TRUE, 'assets/images/store_jakarta.png', -6.926013, 107.602188),
        ('Dummy Trek Rental Padang 56', NULL, '088531118333', 'Jl. Dummy No. 56, Padang', 4.8, 498, TRUE, 'assets/images/store_jakarta.png', -0.961162, 100.304890),
        ('Dummy Basecamp Gear Medan 57', NULL, '083096929657', 'Jl. Dummy No. 57, Medan', 3.9, 258, TRUE, 'assets/images/store_jakarta.png', 3.619952, 98.676813),
        ('Dummy Camp Camping Banjarmasin 58', NULL, '088904911624', 'Jl. Dummy No. 58, Banjarmasin', 4.9, 328, TRUE, 'assets/images/store_jakarta.png', -3.335787, 114.608014),
        ('Dummy Adventure Camp Banjarmasin 59', NULL, '082982979741', 'Jl. Dummy No. 59, Banjarmasin', 3.6, 204, TRUE, 'assets/images/store_jakarta.png', -3.310211, 114.606400),
        ('Dummy Camp Rental Semarang 60', NULL, '088868054898', 'Jl. Dummy No. 60, Semarang', 3.9, 51, TRUE, 'assets/images/store_jakarta.png', -6.997730, 110.404050),
        ('Dummy Trek Gear Jakarta 61', NULL, '083792347639', 'Jl. Dummy No. 61, Jakarta', 4.7, 343, TRUE, 'assets/images/store_jakarta.png', -6.183898, 106.800809),
        ('Dummy Outdoor Basecamp Jakarta 62', NULL, '081654477195', 'Jl. Dummy No. 62, Jakarta', 3.7, 352, TRUE, 'assets/images/store_jakarta.png', -6.163839, 106.815536),
        ('Dummy Rental Trek Padang 63', NULL, '084518871744', 'Jl. Dummy No. 63, Padang', 4.9, 65, TRUE, 'assets/images/store_jakarta.png', -0.904424, 100.350803),
        ('Dummy Camp Camp Surabaya 64', NULL, '081851819913', 'Jl. Dummy No. 64, Surabaya', 4.4, 435, FALSE, 'assets/images/store_jakarta.png', -7.242820, 112.809603),
        ('Dummy Basecamp Adventure Bandung 65', NULL, '085471357886', 'Jl. Dummy No. 65, Bandung', 4.3, 348, TRUE, 'assets/images/store_jakarta.png', -6.897781, 107.599258),
        ('Dummy Camp Hike Bandung 66', NULL, '085748253283', 'Jl. Dummy No. 66, Bandung', 4.9, 335, TRUE, 'assets/images/store_jakarta.png', -6.916904, 107.603223),
        ('Dummy Rental Basecamp Yogyakarta 67', NULL, '087371573279', 'Jl. Dummy No. 67, Yogyakarta', 4.2, 384, TRUE, 'assets/images/store_jakarta.png', -7.802051, 110.392880),
        ('Dummy Adventure Rental Denpasar 68', NULL, '089081544414', 'Jl. Dummy No. 68, Denpasar', 3.9, 247, TRUE, 'assets/images/store_jakarta.png', -8.635329, 115.245873),
        ('Dummy Camping Hike Denpasar 69', NULL, '086206015111', 'Jl. Dummy No. 69, Denpasar', 4.7, 184, TRUE, 'assets/images/store_jakarta.png', -8.717630, 115.247895),
        ('Dummy Outdoor Summit Padang 70', NULL, '085071897791', 'Jl. Dummy No. 70, Padang', 3.6, 378, TRUE, 'assets/images/store_jakarta.png', -0.929082, 100.331927),
        ('Dummy Hike Hike Makassar 71', NULL, '081074059253', 'Jl. Dummy No. 71, Makassar', 3.9, 217, FALSE, 'assets/images/store_jakarta.png', -5.142082, 119.406732),
        ('Dummy Summit Summit Surabaya 72', NULL, '086771394050', 'Jl. Dummy No. 72, Surabaya', 5.0, 291, TRUE, 'assets/images/store_jakarta.png', -7.234004, 112.755702),
        ('Dummy Rental Gear Denpasar 73', NULL, '086122110529', 'Jl. Dummy No. 73, Denpasar', 3.7, 284, FALSE, 'assets/images/store_jakarta.png', -8.650215, 115.189892),
        ('Dummy Basecamp Summit Semarang 74', NULL, '087858164010', 'Jl. Dummy No. 74, Semarang', 5.0, 436, FALSE, 'assets/images/store_jakarta.png', -7.021562, 110.418720),
        ('Dummy Outdoor Summit Surabaya 75', NULL, '085838636972', 'Jl. Dummy No. 75, Surabaya', 3.6, 37, TRUE, 'assets/images/store_jakarta.png', -7.277652, 112.736744),
        ('Dummy Adventure Outdoor Yogyakarta 76', NULL, '087760554363', 'Jl. Dummy No. 76, Yogyakarta', 4.2, 235, TRUE, 'assets/images/store_jakarta.png', -7.781813, 110.394779),
        ('Dummy Hike Adventure Yogyakarta 77', NULL, '084530959836', 'Jl. Dummy No. 77, Yogyakarta', 4.1, 47, TRUE, 'assets/images/store_jakarta.png', -7.749050, 110.344748),
        ('Dummy Rental Adventure Yogyakarta 78', NULL, '085268845844', 'Jl. Dummy No. 78, Yogyakarta', 3.7, 401, TRUE, 'assets/images/store_jakarta.png', -7.830680, 110.375784),
        ('Dummy Summit Camp Padang 79', NULL, '087196439534', 'Jl. Dummy No. 79, Padang', 4.8, 229, TRUE, 'assets/images/store_jakarta.png', -0.939587, 100.366142),
        ('Dummy Adventure Gear Padang 80', NULL, '083686566602', 'Jl. Dummy No. 80, Padang', 3.9, 51, FALSE, 'assets/images/store_jakarta.png', -0.937097, 100.365263),
        ('Dummy Outdoor Camp Semarang 81', NULL, '087845366946', 'Jl. Dummy No. 81, Semarang', 3.9, 128, TRUE, 'assets/images/store_jakarta.png', -7.025819, 110.377806),
        ('Dummy Gear Rental Surabaya 82', NULL, '085010075517', 'Jl. Dummy No. 82, Surabaya', 4.1, 288, FALSE, 'assets/images/store_jakarta.png', -7.230101, 112.764203),
        ('Dummy Adventure Outdoor Yogyakarta 83', NULL, '086534540349', 'Jl. Dummy No. 83, Yogyakarta', 3.7, 362, TRUE, 'assets/images/store_jakarta.png', -7.754759, 110.402163),
        ('Dummy Hike Hike Banjarmasin 84', NULL, '089935429720', 'Jl. Dummy No. 84, Banjarmasin', 3.6, 231, TRUE, 'assets/images/store_jakarta.png', -3.275132, 114.590147),
        ('Dummy Basecamp Basecamp Padang 85', NULL, '085083595988', 'Jl. Dummy No. 85, Padang', 5.0, 354, TRUE, 'assets/images/store_jakarta.png', -0.974163, 100.313433),
        ('Dummy Hike Summit Padang 86', NULL, '088093179263', 'Jl. Dummy No. 86, Padang', 4.9, 102, TRUE, 'assets/images/store_jakarta.png', -0.995177, 100.379927),
        ('Dummy Camp Trek Makassar 87', NULL, '085985704790', 'Jl. Dummy No. 87, Makassar', 4.1, 263, TRUE, 'assets/images/store_jakarta.png', -5.100694, 119.429701),
        ('Dummy Hike Adventure Banjarmasin 88', NULL, '086645808194', 'Jl. Dummy No. 88, Banjarmasin', 4.0, 405, TRUE, 'assets/images/store_jakarta.png', -3.288043, 114.595110),
        ('Dummy Summit Hike Medan 89', NULL, '082774884818', 'Jl. Dummy No. 89, Medan', 3.8, 195, TRUE, 'assets/images/store_jakarta.png', 3.627693, 98.622315),
        ('Dummy Summit Camping Makassar 90', NULL, '089279291478', 'Jl. Dummy No. 90, Makassar', 4.2, 367, TRUE, 'assets/images/store_jakarta.png', -5.121601, 119.403056),
        ('Dummy Gear Camping Bandung 91', NULL, '089648665968', 'Jl. Dummy No. 91, Bandung', 4.1, 125, TRUE, 'assets/images/store_jakarta.png', -6.964613, 107.632102),
        ('Dummy Camping Hike Makassar 92', NULL, '088324687182', 'Jl. Dummy No. 92, Makassar', 4.1, 257, TRUE, 'assets/images/store_jakarta.png', -5.102894, 119.447471),
        ('Dummy Gear Basecamp Semarang 93', NULL, '084776677517', 'Jl. Dummy No. 93, Semarang', 4.8, 151, TRUE, 'assets/images/store_jakarta.png', -6.997521, 110.384764),
        ('Dummy Outdoor Rental Denpasar 94', NULL, '088413332538', 'Jl. Dummy No. 94, Denpasar', 4.8, 306, TRUE, 'assets/images/store_jakarta.png', -8.627075, 115.213574),
        ('Dummy Trek Summit Yogyakarta 95', NULL, '086915072151', 'Jl. Dummy No. 95, Yogyakarta', 4.9, 455, FALSE, 'assets/images/store_jakarta.png', -7.800945, 110.367934),
        ('Dummy Camp Outdoor Semarang 96', NULL, '086932342612', 'Jl. Dummy No. 96, Semarang', 5.0, 415, FALSE, 'assets/images/store_jakarta.png', -6.986020, 110.393656),
        ('Dummy Basecamp Trek Makassar 97', NULL, '084735334423', 'Jl. Dummy No. 97, Makassar', 4.8, 235, TRUE, 'assets/images/store_jakarta.png', -5.101118, 119.395325),
        ('Dummy Camping Camp Medan 98', NULL, '085165932723', 'Jl. Dummy No. 98, Medan', 3.6, 410, TRUE, 'assets/images/store_jakarta.png', 3.636244, 98.623735),
        ('Dummy Adventure Trek Denpasar 99', NULL, '088556573246', 'Jl. Dummy No. 99, Denpasar', 4.8, 28, TRUE, 'assets/images/store_jakarta.png', -8.658174, 115.202548),
        ('Dummy Gear Adventure Semarang 100', NULL, '084747699292', 'Jl. Dummy No. 100, Semarang', 4.2, 365, TRUE, 'assets/images/store_jakarta.png', -6.980084, 110.462393)
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
