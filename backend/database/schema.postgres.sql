-- =====================================================================
-- AGARAM Tamil Children's Educational Platform
-- PostgreSQL Relational Schema with Foreign Keys, Indexes & Seed Data
-- =====================================================================

DROP TABLE IF EXISTS user_stars CASCADE;
DROP TABLE IF EXISTS quiz_results CASCADE;
DROP TABLE IF EXISTS user_progress CASCADE;
DROP TABLE IF EXISTS quiz_options CASCADE;
DROP TABLE IF EXISTS quiz_questions CASCADE;
DROP TABLE IF EXISTS quizzes CASCADE;
DROP TABLE IF EXISTS games CASCADE;
DROP TABLE IF EXISTS reading_story_pages CASCADE;
DROP TABLE IF EXISTS reading_stories CASCADE;
DROP TABLE IF EXISTS videos CASCADE;
DROP TABLE IF EXISTS letters CASCADE;
DROP TABLE IF EXISTS letter_groups CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS admins CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;
DROP TABLE IF EXISTS languages CASCADE;

-- 0. Table: languages
-- ---------------------------------------------------------------------
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
);
-- ---------------------------------------------------------------------
-- 0.1 Table: tenants (Multi-Tenant Organization Support)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tenants (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  subdomain VARCHAR(64) UNIQUE,
  default_language VARCHAR(10) NOT NULL DEFAULT 'ta',
  logo_url VARCHAR(255) NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tenant_subdomain ON tenants (subdomain);
-- ---------------------------------------------------------------------
-- 1. Table: admins
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admins (
  id SERIAL PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  email VARCHAR(128) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(32) NOT NULL DEFAULT 'content_admin',
  full_name VARCHAR(128) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_admin_username ON admins (username);
CREATE INDEX IF NOT EXISTS idx_admin_email ON admins (email);
CREATE INDEX IF NOT EXISTS idx_admin_role ON admins (role);
-- ---------------------------------------------------------------------
-- 2. Table: users (Child Learners)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(64) PRIMARY KEY,
  child_name VARCHAR(128) NOT NULL DEFAULT 'குழந்தை',
  email VARCHAR(128) UNIQUE NULL,
  password_hash VARCHAR(255) NULL,
  age INT NOT NULL DEFAULT 5,
  avatar_asset VARCHAR(255) NOT NULL DEFAULT 'assets/images/welcome.png',
  total_stars INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_user_active ON users (is_active);
-- ---------------------------------------------------------------------
-- 3. Table: lessons (Educational Modules / Categories)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lessons (
  id VARCHAR(64) PRIMARY KEY,
  category_key VARCHAR(64) NOT NULL UNIQUE,
  title VARCHAR(128) NOT NULL,
  subtitle VARCHAR(255) DEFAULT '',
  count_text VARCHAR(64) DEFAULT '',
  button_text VARCHAR(64) DEFAULT 'கற்கலாம்',
  icon_emoji VARCHAR(32) DEFAULT '⭐',
  gradient_colors JSON,
  route_name VARCHAR(64) DEFAULT '',
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_lesson_order ON lessons (display_order);
CREATE INDEX IF NOT EXISTS idx_lesson_active ON lessons (is_active);
-- ---------------------------------------------------------------------
-- 4. Table: letter_groups (Classification for Uyir, Mei, Uyirmei, Aytham)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS letter_groups (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  display_title VARCHAR(128) NOT NULL,
  letter_type VARCHAR(32) NOT NULL,
  description TEXT,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_group_type ON letter_groups (letter_type);
CREATE INDEX IF NOT EXISTS idx_group_order ON letter_groups (display_order);
-- ---------------------------------------------------------------------
-- 5. Table: letters
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS letters (
  id VARCHAR(64) PRIMARY KEY,
  letter VARCHAR(32) NOT NULL,
  type VARCHAR(32) NOT NULL,
  group_id VARCHAR(64) NULL,
  word VARCHAR(128) NOT NULL,
  meaning VARCHAR(128) NOT NULL,
  phonetic VARCHAR(128) NOT NULL,
  icon_emoji VARCHAR(32) DEFAULT '⭐',
  image_path VARCHAR(500) NULL,
  audio_path VARCHAR(500) NULL,
  video_url VARCHAR(500) NULL,
  explanation TEXT NULL,
  mei_base VARCHAR(32) NULL,
  uyir_base VARCHAR(32) NULL,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES letter_groups(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_letter_type ON letters (type);
CREATE INDEX IF NOT EXISTS idx_letter_order ON letters (display_order);
CREATE INDEX IF NOT EXISTS idx_letter_active ON letters (is_active);
-- ---------------------------------------------------------------------
-- 6. Table: reading_stories
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reading_stories (
  id VARCHAR(64) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  subtitle VARCHAR(255) DEFAULT '',
  cover_emoji VARCHAR(32) DEFAULT '📖',
  cover_image VARCHAR(255) NULL,
  moral VARCHAR(255) DEFAULT '',
  display_order INT NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_story_published ON reading_stories (is_published);
CREATE INDEX IF NOT EXISTS idx_story_order ON reading_stories (display_order);
-- ---------------------------------------------------------------------
-- 7. Table: reading_story_pages
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reading_story_pages (
  id SERIAL PRIMARY KEY,
  story_id VARCHAR(64) NOT NULL,
  page_number INT NOT NULL,
  text TEXT NOT NULL,
  emoji_illustration VARCHAR(32) DEFAULT '🐰',
  character_name VARCHAR(128) DEFAULT '',
  narrator_audio VARCHAR(255) NULL,
  image_path VARCHAR(255) NULL,
  interactive_words JSON NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (story_id) REFERENCES reading_stories(id) ON DELETE CASCADE,
  CONSTRAINT uk_story_page UNIQUE (story_id, page_number)
);

CREATE INDEX IF NOT EXISTS idx_page_story ON reading_story_pages (story_id);
-- ---------------------------------------------------------------------
-- 8. Table: videos
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS videos (
  id VARCHAR(64) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  category VARCHAR(64) NOT NULL DEFAULT 'பாடல்',
  duration VARCHAR(32) DEFAULT '03:00',
  thumbnail_emoji VARCHAR(32) DEFAULT '🎬',
  thumbnail_image VARCHAR(255) NULL,
  video_url VARCHAR(500) NOT NULL,
  local_video_path VARCHAR(255) NULL,
  display_order INT NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_video_category ON videos (category);
CREATE INDEX IF NOT EXISTS idx_video_published ON videos (is_published);
-- ---------------------------------------------------------------------
-- 9. Table: quizzes
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quizzes (
  id VARCHAR(64) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  subtitle VARCHAR(255) DEFAULT '',
  icon_emoji VARCHAR(32) DEFAULT '❓',
  category VARCHAR(64) NOT NULL DEFAULT 'uyir',
  question_count INT NOT NULL DEFAULT 5,
  pass_marks INT NOT NULL DEFAULT 3,
  stars_reward INT NOT NULL DEFAULT 5,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_quiz_category ON quizzes (category);
CREATE INDEX IF NOT EXISTS idx_quiz_active ON quizzes (is_active);
-- ---------------------------------------------------------------------
-- 10. Table: quiz_questions
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quiz_questions (
  id VARCHAR(64) PRIMARY KEY,
  quiz_id VARCHAR(64) NOT NULL,
  question_text TEXT NOT NULL,
  visual_hint VARCHAR(64) NULL,
  visual_image VARCHAR(255) NULL,
  explanation TEXT NULL,
  marks INT NOT NULL DEFAULT 1,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_question_quiz ON quiz_questions (quiz_id);
CREATE INDEX IF NOT EXISTS idx_question_order ON quiz_questions (display_order);
-- ---------------------------------------------------------------------
-- 11. Table: quiz_options
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quiz_options (
  id SERIAL PRIMARY KEY,
  question_id VARCHAR(64) NOT NULL,
  option_text VARCHAR(255) NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (question_id) REFERENCES quiz_questions(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_option_question ON quiz_options (question_id);
-- ---------------------------------------------------------------------
-- 12. Table: games
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS games (
  id VARCHAR(64) PRIMARY KEY,
  game_type VARCHAR(64) NOT NULL,
  title VARCHAR(255) NOT NULL,
  prompt TEXT NOT NULL,
  clue TEXT NULL,
  clue_image VARCHAR(255) NULL,
  correct_index INT NOT NULL DEFAULT 0,
  options_json JSON NOT NULL,
  success_praise VARCHAR(255) DEFAULT 'சூப்பர்! ⭐',
  stars_reward INT NOT NULL DEFAULT 3,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_game_type ON games (game_type);
CREATE INDEX IF NOT EXISTS idx_game_active ON games (is_active);
-- ---------------------------------------------------------------------
-- 13. Table: user_progress
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_progress (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  content_type VARCHAR(32) NOT NULL,
  content_id VARCHAR(64) NOT NULL,
  completion_status VARCHAR(32) NOT NULL DEFAULT 'completed',
  completion_percentage INT NOT NULL DEFAULT 100,
  stars_earned INT NOT NULL DEFAULT 1,
  last_accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT uk_user_content UNIQUE (user_id, content_type, content_id)
);

CREATE INDEX IF NOT EXISTS idx_progress_user ON user_progress (user_id);
CREATE INDEX IF NOT EXISTS idx_progress_content ON user_progress (content_type, content_id);
-- ---------------------------------------------------------------------
-- 14. Table: quiz_results
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quiz_results (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  quiz_id VARCHAR(64) NOT NULL,
  score INT NOT NULL DEFAULT 0,
  total_questions INT NOT NULL DEFAULT 0,
  correct_answers INT NOT NULL DEFAULT 0,
  stars_earned INT NOT NULL DEFAULT 0,
  attempt_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_result_user ON quiz_results (user_id);
CREATE INDEX IF NOT EXISTS idx_result_quiz ON quiz_results (quiz_id);
-- ---------------------------------------------------------------------
-- 15. Table: user_stars (Streak and aggregate star ledger)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_stars (
  user_id VARCHAR(64) PRIMARY KEY,
  total_stars INT NOT NULL DEFAULT 0,
  current_streak INT NOT NULL DEFAULT 1,
  highest_streak INT NOT NULL DEFAULT 1,
  last_earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
-- =====================================================================
-- INITIAL SEED DATA
-- =====================================================================

-- Default Super Admin (username: superadmin, password: Admin@123)
INSERT INTO admins (username, email, password_hash, role, full_name, is_active)
VALUES (
  'superadmin',
  'admin@gmail.com',
  '$2a$10$3Gmn4mOc6xZ1rhY4H60qLOFsdSPDb.9XDlorRu6SWzBDC/7T08pS.',
  'super_admin',
  'AGARAM Super Admin',
  TRUE
) ON CONFLICT (username) DO UPDATE SET email = EXCLUDED.email, password_hash = EXCLUDED.password_hash;

-- Default Child User
INSERT INTO users (id, child_name, age, avatar_asset, total_stars, is_active)
VALUES ('default_child', 'Kid Learner', 5, 'assets/images/welcome.png', 25, TRUE)
;

INSERT INTO user_stars (user_id, total_stars, current_streak, highest_streak)
VALUES ('default_child', 25, 3, 5)
;

-- Lesson Categories
INSERT INTO lessons (id, category_key, title, subtitle, count_text, button_text, icon_emoji, gradient_colors, route_name, display_order, is_active)
VALUES
('lesson_alphabets', 'alphabets', 'English Alphabets', 'Learn 26 Letters from A to Z with Fun', '26 Letters', 'Start Learning', '🔤', '["#4E65FF", "#92EFFD"]', '/alphabets', 1, TRUE),
('lesson_vowels', 'vowels', 'Vowels', 'A, E, I, O, U - The Foundation of English Words', '5 Vowels', 'Learn Vowels', '🍎', '["#FF6B8B", "#FF8E53"]', '/vowels', 2, TRUE),
('lesson_consonants', 'consonants', 'Consonants', '21 Consonant Letters with Examples & Sounds', '21 Consonants', 'Learn Consonants', '🎡', '["#11998E", "#38EF7D"]', '/consonants', 3, TRUE),
('lesson_reading', 'reading', 'Reading Stories', 'Fun illustrated short stories for beginners', 'Story Books', 'Read Now', '📚', '["#FF8008", "#FFC837"]', '/reading', 4, TRUE)
;

-- Letter Groups
INSERT INTO letter_groups (id, name, display_title, letter_type, description, display_order)
VALUES
('group_english_all', 'All Alphabets', 'English Alphabets (A - Z)', 'english', 'Complete 26 English Alphabets', 1),
('group_english_vowels', 'English Vowels', 'Vowels (A, E, I, O, U)', 'vowel', '5 English Vowel Letters', 2),
('group_english_consonants', 'English Consonants', 'Consonants (21 Letters)', 'consonant', '21 English Consonants', 3)
;

-- 26 English Alphabet Letters (A to Z)
INSERT INTO letters (id, letter, type, group_id, word, meaning, phonetic, icon_emoji, image_path, explanation, display_order, is_active)
VALUES
('eng_a', 'A', 'vowel', 'group_english_vowels', 'Apple', 'Sweet red fruit', '/ˈæp.əl/', '🍎', 'assets/images/alphabets/apple.png', 'A is for Apple. Sweet and crunchy!', 1, TRUE),
('eng_b', 'B', 'consonant', 'group_english_consonants', 'Ball', 'Round toy for games', '/bɔːl/', '⚽', 'assets/images/alphabets/ball.png', 'B is for Ball. Bounce and play!', 2, TRUE),
('eng_c', 'C', 'consonant', 'group_english_consonants', 'Camel', 'Desert animal', '/ˈkæm.əl/', '🐪', 'assets/images/alphabets/camel.png', 'C is for Camel. Walking through the desert sand.', 3, TRUE),
('eng_d', 'D', 'consonant', 'group_english_consonants', 'Dog', 'Loyal and friendly pet', '/dɒɡ/', '🐶', 'assets/images/alphabets/dog.png', 'D is for Dog. Wagging its happy tail!', 4, TRUE),
('eng_e', 'E', 'vowel', 'group_english_vowels', 'Eye', 'Organ of sight', '/aɪ/', '👁️', 'assets/images/alphabets/eye.png', 'E is for Eye. We see the world with our eyes.', 5, TRUE),
('eng_f', 'F', 'consonant', 'group_english_consonants', 'Fish', 'Water creature', '/fɪʃ/', '🐟', 'assets/images/alphabets/fish.png', 'F is for Fish. Swimming smoothly in the sea.', 6, TRUE),
('eng_g', 'G', 'consonant', 'group_english_consonants', 'Grapes', 'Juicy green or purple fruit', '/ɡreɪps/', '🍇', 'assets/images/alphabets/grapes.png', 'G is for Grapes. Growing in tasty bunches.', 7, TRUE),
('eng_h', 'H', 'consonant', 'group_english_consonants', 'Hen', 'Bird that lays eggs', '/hɛn/', '🐔', 'assets/images/alphabets/hen.png', 'H is for Hen. Cluck, cluck, cluck!', 8, TRUE),
('eng_i', 'I', 'vowel', 'group_english_vowels', 'Ice Cream', 'Sweet frozen dessert', '/ˈaɪs ˌkriːm/', '🍦', 'assets/images/alphabets/ice_cream.png', 'I is for Ice Cream. Cool and delicious on a warm day!', 9, TRUE),
('eng_j', 'J', 'consonant', 'group_english_consonants', 'Jug', 'Container for liquids', '/dʒʌɡ/', '🏺', 'assets/images/alphabets/jug.png', 'J is for Jug. Pouring cool fresh water.', 10, TRUE),
('eng_k', 'K', 'consonant', 'group_english_consonants', 'Kite', 'Toy flying high in the sky', '/kaɪt/', '🪁', 'assets/images/alphabets/kite.png', 'K is for Kite. Soaring high in the windy sky!', 11, TRUE),
('eng_l', 'L', 'consonant', 'group_english_consonants', 'Leaf', 'Green part of a plant', '/liːf/', '🍃', 'assets/images/alphabets/leaf.png', 'L is for Leaf. Fluttering gently from the tall tree.', 12, TRUE),
('eng_m', 'M', 'consonant', 'group_english_consonants', 'Mat', 'Floor rug', '/mæt/', '🧘', 'assets/images/alphabets/mat.png', 'M is for Mat. Let us sit together on the mat.', 13, TRUE),
('eng_n', 'N', 'consonant', 'group_english_consonants', 'Number', 'Counting digits', '/ˈnʌm.bər/', '🔢', 'assets/images/alphabets/number.png', 'N is for Number. 1, 2, 3, let us count!', 14, TRUE),
('eng_o', 'O', 'vowel', 'group_english_vowels', 'Orange', 'Round citrus fruit', '/ˈɒr.ɪndʒ/', '🍊', 'assets/images/alphabets/orange.png', 'O is for Orange. Bright, round, and rich in Vitamin C.', 15, TRUE),
('eng_p', 'P', 'consonant', 'group_english_consonants', 'Parrot', 'Colorful talking bird', '/ˈpær.ət/', '🦜', 'assets/images/alphabets/parrot.png', 'P is for Parrot. Chirping with bright green feathers.', 16, TRUE),
('eng_q', 'Q', 'consonant', 'group_english_consonants', 'Queen', 'Royal kingdom ruler', '/kwiːn/', '👑', 'assets/images/alphabets/queen.png', 'Q is for Queen. Wearing a sparkling crown.', 17, TRUE),
('eng_r', 'R', 'consonant', 'group_english_consonants', 'Rabbit', 'Cute hopping animal', '/ˈræb.ɪt/', '🐰', 'assets/images/alphabets/rabbit.png', 'R is for Rabbit. Hop, hop, hop across the meadow!', 18, TRUE),
('eng_s', 'S', 'consonant', 'group_english_consonants', 'Ship', 'Large boat on sea', '/ʃɪp/', '🚢', 'assets/images/alphabets/ship.png', 'S is for Ship. Sailing across the vast blue ocean.', 19, TRUE),
('eng_t', 'T', 'consonant', 'group_english_consonants', 'Tree', 'Tall woody plant with leaves', '/triː/', '🌳', 'assets/images/alphabets/tree.png', 'T is for Tree. Giving us fresh air and cooling shade.', 20, TRUE),
('eng_u', 'U', 'vowel', 'group_english_vowels', 'Umbrella', 'Protection from rain', '/ʌmˈbrel.ə/', '☂️', 'assets/images/alphabets/umbrella.png', 'U is for Umbrella. Opening up when the rain pours down.', 21, TRUE),
('eng_v', 'V', 'consonant', 'group_english_consonants', 'Van', 'Vehicle for transport', '/væn/', '🚐', 'assets/images/alphabets/van.png', 'V is for Van. Beep beep, let us ride together!', 22, TRUE),
('eng_w', 'W', 'consonant', 'group_english_consonants', 'Wheel', 'Round rolling ring', '/wiːl/', '🛞', 'assets/images/alphabets/wheel.png', 'W is for Wheel. The wheels on the bus go round and round.', 23, TRUE),
('eng_x', 'X', 'consonant', 'group_english_consonants', 'Xylophone', 'Colorful musical instrument', '/ˈzaɪ.lə.fəʊn/', '🎼', 'assets/images/alphabets/xylophone.png', 'X is for Xylophone. Tap the colorful bars for music!', 24, TRUE),
('eng_y', 'Y', 'consonant', 'group_english_consonants', 'Yo-yo', 'Spinning string toy', '/ˈjəʊ.jəʊ/', '🪀', 'assets/images/alphabets/yoyo.png', 'Y is for Yo-yo. Roll it down and bring it right back up!', 25, TRUE),
('eng_z', 'Z', 'consonant', 'group_english_consonants', 'Zebra', 'Striped wild animal', '/ˈzeb.rə/', '🦓', 'assets/images/alphabets/zebra.png', 'Z is for Zebra. Running free with black and white stripes.', 26, TRUE)
;

-- Reading Stories
INSERT INTO reading_stories (id, title, subtitle, cover_emoji, cover_image, moral, display_order, is_published)
VALUES
('story_hare_tortoise', 'The Hare and the Tortoise', 'A classic fable of speed and patience', '🐰🐢', 'assets/images/story_friends.jpg', 'Slow and steady wins the race!', 1, TRUE),
('story_lion_mouse', 'The Lion and the Mouse', 'A tiny act of kindness can save a life', '🦁🐭', 'assets/images/story_victory.jpg', 'Even the smallest friend can be of great help!', 2, TRUE)
;

INSERT INTO reading_story_pages (story_id, page_number, text, emoji_illustration, character_name, image_path, interactive_words)
VALUES
('story_hare_tortoise', 1, 'Once upon a time in a sunny forest, a Hare and a Tortoise lived as neighbors.', '🌲🐰 🐢🌿', 'Forest Friends', 'assets/images/story_forest.jpg', '[{"word":"forest","displayLabel":"Forest","emoji":"🌲","meaning":"A place with many green trees"},{"word":"Hare","displayLabel":"Hare","emoji":"🐰","meaning":"A swift rabbit"},{"word":"Tortoise","displayLabel":"Tortoise","emoji":"🐢","meaning":"A gentle friend who moves steadily"}]'),
('story_hare_tortoise', 2, 'The Hare loved to boast: "I am the fastest animal in the whole forest!" The Tortoise just smiled.', '🐰💨 🐢🐾', 'The Boastful Hare', 'assets/images/story_friends.jpg', NULL),
('story_hare_tortoise', 3, 'They decided to hold a great running race to the tall oak tree!', '🏁🐰💨 ... 🐢', 'The Great Race', 'assets/images/story_race.jpg', NULL),
('story_hare_tortoise', 4, 'The Hare ran super fast, looked back, and thought: "I have plenty of time. Let me take a quick nap!"', '🌳😴🐰💤  🐢🐾', 'Sleeping Hare', 'assets/images/story_sleeping_rabbit.jpg', NULL),
('story_hare_tortoise', 5, 'The Tortoise never stopped. Step by step, walking forward with determination.', '🎉🏆🐢✨ 😲🐰', 'Steady Walking', 'assets/images/story_victory.jpg', NULL),
('story_hare_tortoise', 6, 'The Tortoise crossed the finish line first! Slow and steady wins the race!', '🌟🤝🐰🐢💖', 'Victory & Moral', 'assets/images/story_friends.jpg', NULL)
;

-- Videos
INSERT INTO videos (id, title, description, category, duration, thumbnail_emoji, video_url, display_order, is_published)
VALUES
('vid_abc_song', 'ABC Phonics Song (A to Z)', 'Sing along with the 26 English letters and phonics sounds', 'Alphabet Song', '03:15', '🎵', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', 1, TRUE),
('vid_vowels_song', 'The Five Vowels (A, E, I, O, U)', 'Learn all about English vowels with upbeat melodies', 'Phonics & Rhymes', '02:45', '🍎', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4', 2, TRUE),
('vid_phonics_fun', 'Letter Sounds and Words for Kids', 'Phonics practice for children with cartoon animations', 'Stories & Phonics', '04:10', '🎬', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', 3, TRUE)
;

-- Quizzes
INSERT INTO quizzes (id, title, subtitle, icon_emoji, category, question_count, pass_marks, stars_reward, is_active, display_order)
VALUES
('quiz_alphabet_basics', 'Alphabet Basics Quiz', 'Test your knowledge on letters A through Z', '🔤', 'alphabets', 5, 3, 5, TRUE, 1),
('quiz_vowels_fun', 'Vowels Challenge', 'Identify the 5 Vowels: A, E, I, O, U', '🍎', 'vowels', 3, 2, 5, TRUE, 2)
;

-- Quiz Questions
INSERT INTO quiz_questions (id, quiz_id, question_text, visual_hint, explanation, marks, display_order, is_active)
VALUES
('q_alpha_1', 'quiz_alphabet_basics', 'Which letter comes immediately after letter "A"?', '🔤', 'B comes right after A.', 1, 1, TRUE),
('q_alpha_2', 'quiz_alphabet_basics', 'What is the starting letter of the word "Apple"?', '🍎', 'Apple starts with the letter A.', 1, 2, TRUE),
('q_alpha_3', 'quiz_alphabet_basics', 'Which of the following letters is a VOWEL?', '⭐', 'E is one of the five vowels (A, E, I, O, U).', 1, 3, TRUE),
('q_alpha_4', 'quiz_alphabet_basics', 'What is the last letter of the English Alphabet?', '🏁', 'Z is the 26th and final letter of the alphabet.', 1, 4, TRUE),
('q_alpha_5', 'quiz_alphabet_basics', 'How many letters are in the English Alphabet?', '🔢', 'There are exactly 26 letters in the English Alphabet.', 1, 5, TRUE),
('q_vowel_1', 'quiz_vowels_fun', 'Which letter is NOT a vowel?', '❓', 'B is a consonant, not a vowel.', 1, 1, TRUE),
('q_vowel_2', 'quiz_vowels_fun', 'Which word starts with the vowel letter "O"?', '🍊', 'Orange starts with the vowel O.', 1, 2, TRUE),
('q_vowel_3', 'quiz_vowels_fun', 'How many vowels are in the English language?', '🖐️', 'There are 5 vowels: A, E, I, O, and U.', 1, 3, TRUE)
;

-- Quiz Options
INSERT INTO quiz_options (question_id, option_text, is_correct, display_order)
VALUES
('q_alpha_1', 'B', TRUE, 1),
('q_alpha_1', 'C', FALSE, 2),
('q_alpha_1', 'D', FALSE, 3),
('q_alpha_1', 'Z', FALSE, 4),

('q_alpha_2', 'A', TRUE, 1),
('q_alpha_2', 'P', FALSE, 2),
('q_alpha_2', 'L', FALSE, 3),
('q_alpha_2', 'E', FALSE, 4),

('q_alpha_3', 'E', TRUE, 1),
('q_alpha_3', 'B', FALSE, 2),
('q_alpha_3', 'K', FALSE, 3),
('q_alpha_3', 'M', FALSE, 4),

('q_alpha_4', 'Z', TRUE, 1),
('q_alpha_4', 'X', FALSE, 2),
('q_alpha_4', 'Y', FALSE, 3),
('q_alpha_4', 'W', FALSE, 4),

('q_alpha_5', '26', TRUE, 1),
('q_alpha_5', '20', FALSE, 2),
('q_alpha_5', '24', FALSE, 3),
('q_alpha_5', '30', FALSE, 4),

('q_vowel_1', 'B', TRUE, 1),
('q_vowel_1', 'A', FALSE, 2),
('q_vowel_1', 'E', FALSE, 3),
('q_vowel_1', 'I', FALSE, 4),

('q_vowel_2', 'Orange', TRUE, 1),
('q_vowel_2', 'Banana', FALSE, 2),
('q_vowel_2', 'Mango', FALSE, 3),
('q_vowel_2', 'Grape', FALSE, 4),

('q_vowel_3', '5', TRUE, 1),
('q_vowel_3', '3', FALSE, 2),
('q_vowel_3', '7', FALSE, 3),
('q_vowel_3', '10', FALSE, 4);

-- Educational Games
INSERT INTO games (id, game_type, title, prompt, clue, clue_image, correct_index, options_json, success_praise, stars_reward, is_active, display_order)
VALUES
('game_runner_1', 'runner', 'Alphabet Runner (2D Runner)', 'Run and jump to collect the correct letters!', 'Collect letter A', 'assets/images/welcome.png', 0, '["A", "B", "C", "D"]', 'Awesome! Goal reached! 🏃⭐', 3, TRUE, 1),
('game_candy_1', 'candy', 'Alphabet Candy Match (Match-3)', 'Match 3 colorful letter candies together!', 'Match 3 Letter Candies', 'assets/images/welcome.png', 0, '["A", "B", "C", "D"]', 'Candy burst! Super! 🍬✨', 3, TRUE, 2),
('game_racing_1', 'racing', 'Alphabet Car Racing', 'Steer your car and drive through the correct letter!', 'Car Racing - Letter A', 'assets/images/welcome.png', 0, '["A", "B", "C", "D"]', 'Speed champion! Great driving! 🚗🏁', 3, TRUE, 3),
('game_fishing_1', 'fishing', 'Letter Fishing', 'Catch the swimming fish with the letter B!', 'Letter Fishing', 'assets/images/welcome.png', 1, '["A", "B", "C", "D"]', 'You caught the fish! Splendid! 🎣🐟', 3, TRUE, 4),
('game_basket_1', 'basket', 'Letter Basket', 'Catch the falling letter C into your basket!', 'Basket Game', 'assets/images/welcome.png', 2, '["A", "B", "C", "D"]', 'Caught right in the basket! 🧺🍎', 3, TRUE, 5),
('game_puzzle_1', 'puzzle', 'Word Puzzle', 'Touch the starting letter of the word Apple!', 'A - pple', 'assets/images/welcome.png', 0, '["A", "B", "C", "D"]', 'Brilliant! A is for Apple! ⭐', 3, TRUE, 6),
('game_balloon_1', 'balloon', 'Balloon Pop', 'Pop the balloon that has the letter D!', 'Dog', 'assets/images/welcome.png', 3, '["A", "B", "C", "D"]', 'POP! Wonderful job! 🎈', 3, TRUE, 7)
;
