/**
 * Multi-Language & Multi-Tenant Migration Script
 * Adds languages table, tenants table, and language_code / tenant_id columns.
 */
const { pool } = require('../config/db');

async function migrate() {
  console.log('--- Starting Multi-Language & Multi-Tenant Migration ---');
  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    // 1. Create languages table
    console.log('1. Creating languages table...');
    await conn.query(`
      CREATE TABLE IF NOT EXISTS languages (
        id VARCHAR(10) PRIMARY KEY,
        code VARCHAR(10) NOT NULL UNIQUE,
        name VARCHAR(64) NOT NULL,
        native_name VARCHAR(64) NOT NULL,
        brand_title VARCHAR(64) NOT NULL DEFAULT 'அகரம்',
        flag_emoji VARCHAR(32) NOT NULL DEFAULT '🇮🇳',
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        display_order INT NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // Seed languages
    await conn.query(`
      INSERT INTO languages (id, code, name, native_name, brand_title, flag_emoji, is_active, display_order)
      VALUES 
        ('ta', 'ta', 'Tamil', 'தமிழ்', 'அகரம்', '🇮🇳', TRUE, 1),
        ('te', 'te', 'Telugu', 'తెలుగు', 'అక్షరం', '🇮🇳', TRUE, 2),
        ('en', 'en', 'English', 'English', 'AGARAM', '🇬🇧', TRUE, 3)
      ON DUPLICATE KEY UPDATE 
        name=VALUES(name), native_name=VALUES(native_name), brand_title=VALUES(brand_title), flag_emoji=VALUES(flag_emoji);
    `);

    // 2. Create tenants table (Multi-Tenant foundation)
    console.log('2. Creating tenants table...');
    await conn.query(`
      CREATE TABLE IF NOT EXISTS tenants (
        id VARCHAR(64) PRIMARY KEY,
        name VARCHAR(128) NOT NULL,
        subdomain VARCHAR(64) UNIQUE,
        default_language VARCHAR(10) NOT NULL DEFAULT 'ta',
        logo_url VARCHAR(255) NULL,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_tenant_subdomain (subdomain)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // Seed default tenant
    await conn.query(`
      INSERT INTO tenants (id, name, subdomain, default_language, is_active)
      VALUES ('default', 'AGARAM Global Academy', 'global', 'ta', TRUE)
      ON DUPLICATE KEY UPDATE name=VALUES(name);
    `);

    // Helper function to safely add columns if they don't exist
    async function addColumnIfNotExists(table, column, typeDef) {
      const [columns] = await conn.query(`SHOW COLUMNS FROM ${table} LIKE '${column}'`);
      if (columns.length === 0) {
        console.log(`Adding ${column} to ${table}...`);
        await conn.query(`ALTER TABLE ${table} ADD COLUMN ${column} ${typeDef}`);
      }
    }

    // 3. Add language_code and tenant_id to content tables
    console.log('3. Updating content tables with language_code and tenant_id...');
    const tables = ['letters', 'letter_groups', 'lessons', 'reading_stories', 'quizzes', 'games', 'videos', 'users'];
    
    for (const t of tables) {
      await addColumnIfNotExists(t, 'language_code', "VARCHAR(10) NOT NULL DEFAULT 'ta'");
      await addColumnIfNotExists(t, 'tenant_id', "VARCHAR(64) NULL DEFAULT 'default'");
    }

    // 4. Seed Telugu letter groups
    console.log('4. Seeding Telugu letter groups...');
    await conn.query(`
      INSERT INTO letter_groups (id, name, display_title, letter_type, description, display_order, language_code, tenant_id)
      VALUES 
        ('te_achulu', 'Achulu', 'అచ్చులు (Vowels)', 'uyir', 'తెలుగు అచ్చులు - 16 అక్షరాలు', 1, 'te', 'default'),
        ('te_hallulu', 'Hallulu', 'హల్లులు (Consonants)', 'mei', 'తెలుగు హల్లులు - 36 అక్షరాలు', 2, 'te', 'default')
      ON DUPLICATE KEY UPDATE 
        display_title=VALUES(display_title), language_code=VALUES(language_code);
    `);

    // 5. Seed Telugu core Achulu letters
    console.log('5. Seeding Telugu core Achulu letters...');
    const teluguLetters = [
      { id: 'te_a', letter: 'అ', type: 'uyir', groupId: 'te_achulu', word: 'అమ్మ', meaning: 'Mother', phonetic: 'Amma', emoji: '👩‍👧', order: 1 },
      { id: 'te_aa', letter: 'ఆ', type: 'uyir', groupId: 'te_achulu', word: 'ఆవు', meaning: 'Cow', phonetic: 'Aavu', emoji: '🐄', order: 2 },
      { id: 'te_i', letter: 'ఇ', type: 'uyir', groupId: 'te_achulu', word: 'ఇల్లు', meaning: 'House', phonetic: 'Illu', emoji: '🏠', order: 3 },
      { id: 'te_ee', letter: 'ఈ', type: 'uyir', groupId: 'te_achulu', word: 'ఈగ', meaning: 'Fly', phonetic: 'Eega', emoji: '🪰', order: 4 },
      { id: 'te_u', letter: 'ఉ', type: 'uyir', groupId: 'te_achulu', word: 'ఉడుత', meaning: 'Squirrel', phonetic: 'Udutha', emoji: '🐿️', order: 5 },
      { id: 'te_oo', letter: 'ఊ', type: 'uyir', groupId: 'te_achulu', word: 'ఊయల', meaning: 'Cradle', phonetic: 'Ooyala', emoji: '🎪', order: 6 },
      { id: 'te_ru', letter: 'ఋ', type: 'uyir', groupId: 'te_achulu', word: 'ఋషి', meaning: 'Sage', phonetic: 'Rishi', emoji: '🧘', order: 7 },
      { id: 'te_e', letter: 'ఎ', type: 'uyir', groupId: 'te_achulu', word: 'ఎలుక', meaning: 'Rat', phonetic: 'Eluka', emoji: '🐭', order: 8 },
      { id: 'te_ae', letter: 'ఏ', type: 'uyir', groupId: 'te_achulu', word: 'ఏనుగు', meaning: 'Elephant', phonetic: 'Enugu', emoji: '🐘', order: 9 },
      { id: 'te_ai', letter: 'ఐ', type: 'uyir', groupId: 'te_achulu', word: 'ఐదు', meaning: 'Five', phonetic: 'Aidu', emoji: '🖐️', order: 10 },
      { id: 'te_o', letter: 'ఒ', type: 'uyir', groupId: 'te_achulu', word: 'ఒంటె', meaning: 'Camel', phonetic: 'Onte', emoji: '🐪', order: 11 },
      { id: 'te_oa', letter: 'ఓ', type: 'uyir', groupId: 'te_achulu', word: 'ఓడ', meaning: 'Ship', phonetic: 'Oda', emoji: '🚢', order: 12 },
      { id: 'te_au', letter: 'ఔ', type: 'uyir', groupId: 'te_achulu', word: 'ఔషధం', meaning: 'Medicine', phonetic: 'Aushadham', emoji: '💊', order: 13 },
      { id: 'te_am', letter: 'అం', type: 'uyir', groupId: 'te_achulu', word: 'అందం', meaning: 'Beauty', phonetic: 'Andham', emoji: '🌸', order: 14 },
      { id: 'te_ah', letter: 'అః', type: 'uyir', groupId: 'te_achulu', word: 'నమః', meaning: 'Salutation', phonetic: 'Namaha', emoji: '🙏', order: 15 },
    ];

    for (const l of teluguLetters) {
      await conn.query(`
        INSERT INTO letters 
          (id, letter, type, group_id, word, meaning, phonetic, icon_emoji, language_code, tenant_id, display_order, is_active)
        VALUES 
          (?, ?, ?, ?, ?, ?, ?, ?, 'te', 'default', ?, TRUE)
        ON DUPLICATE KEY UPDATE 
          letter=VALUES(letter), word=VALUES(word), meaning=VALUES(meaning), 
          phonetic=VALUES(phonetic), icon_emoji=VALUES(icon_emoji), language_code=VALUES(language_code);
      `, [l.id, l.letter, l.type, l.groupId, l.word, l.meaning, l.phonetic, l.emoji, l.order]);
    }

    // 6. Seed Telugu Hallulu (Consonants sample)
    const teluguHallulu = [
      { id: 'te_ka', letter: 'క', type: 'mei', groupId: 'te_hallulu', word: 'కలం', meaning: 'Pen', phonetic: 'Kalam', emoji: '✒️', order: 16 },
      { id: 'te_kha', letter: 'ఖ', type: 'mei', groupId: 'te_hallulu', word: 'ఖడ్గం', meaning: 'Sword', phonetic: 'Khadgam', emoji: '⚔️', order: 17 },
      { id: 'te_ga', letter: 'గ', type: 'mei', groupId: 'te_hallulu', word: 'గడియారం', meaning: 'Clock', phonetic: 'Gadiyaram', emoji: '⏰', order: 18 },
      { id: 'te_gha', letter: 'ఘ', type: 'mei', groupId: 'te_hallulu', word: 'ఘటం', meaning: 'Pot', phonetic: 'Ghatam', emoji: '🏺', order: 19 },
      { id: 'te_cha', letter: 'చ', type: 'mei', groupId: 'te_hallulu', word: 'చక్రం', meaning: 'Wheel', phonetic: 'Chakram', emoji: '☸️', order: 20 },
    ];

    for (const l of teluguHallulu) {
      await conn.query(`
        INSERT INTO letters 
          (id, letter, type, group_id, word, meaning, phonetic, icon_emoji, language_code, tenant_id, display_order, is_active)
        VALUES 
          (?, ?, ?, ?, ?, ?, ?, ?, 'te', 'default', ?, TRUE)
        ON DUPLICATE KEY UPDATE 
          letter=VALUES(letter), word=VALUES(word), meaning=VALUES(meaning), 
          phonetic=VALUES(phonetic), icon_emoji=VALUES(icon_emoji), language_code=VALUES(language_code);
      `, [l.id, l.letter, l.type, l.groupId, l.word, l.meaning, l.phonetic, l.emoji, l.order]);
    }

    await conn.commit();
    console.log('✅ Multi-Language & Multi-Tenant Migration Completed Successfully!');
  } catch (error) {
    await conn.rollback();
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    conn.release();
    process.exit(0);
  }
}

migrate();
