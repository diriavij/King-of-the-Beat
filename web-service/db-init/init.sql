-- Таблица пользователей
CREATE TABLE IF NOT EXISTS "user" (
    user_id SERIAL PRIMARY KEY,
    balance INT,
    name VARCHAR,
    profile_pic VARCHAR,
    history_id SERIAL
);

-- Таблица комнат
CREATE TABLE IF NOT EXISTS "room" (
    room_id SERIAL PRIMARY KEY,
    owner_id INTEGER,
    name VARCHAR,
    topic VARCHAR
);

-- Таблица участия
CREATE TABLE IF NOT EXISTS "participation" (
    user_id INTEGER NOT NULL,
    room_id INTEGER NOT NULL,
    PRIMARY KEY (user_id, room_id),
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES "room"(room_id) ON DELETE CASCADE
);

ALTER TABLE "participation" ADD COLUMN is_submitted BOOLEAN DEFAULT FALSE;
ALTER TABLE "participation" ADD COLUMN bets_submitted BOOLEAN DEFAULT FALSE;

-- Таблица песен
CREATE TABLE IF NOT EXISTS "song" (
  song_id SERIAL PRIMARY KEY,
  room_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  track_name VARCHAR NOT NULL,
  artist_name VARCHAR,
  album_url VARCHAR,
  FOREIGN KEY (room_id) REFERENCES "room"(room_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE
);

-- Таблица ставок
CREATE TABLE IF NOT EXISTS "bets" (
    bet_id SERIAL PRIMARY KEY,
    room_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    bet_amount INTEGER,
    FOREIGN KEY (room_id) REFERENCES "room"(room_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES "song"(song_id) ON DELETE CASCADE
);

-- Таблица голосования (голосования за песни)
CREATE TABLE IF NOT EXISTS "votes" (
    vote_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES "song"(song_id) ON DELETE CASCADE
);