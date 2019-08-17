-- Enable pgcrypto for passwords
CREATE EXTENSION pgcrypto;



CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = now();
        RETURN NEW;
    END;
$$ language 'plpgsql';


-- {USERS}
-- @table users
-- @description stores users for find system
CREATE TABLE IF NOT EXISTS users (
    username        VARCHAR(50) PRIMARY KEY,
    email           VARCHAR(50),
    apikey          VARCHAR(32) NOT NULL UNIQUE DEFAULT md5(random()::text),
    secret_token    VARCHAR(32) NOT NULL DEFAULT md5(random()::text),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted      BOOLEAN DEFAULT false,
    salt            VARCHAR DEFAULT gen_salt('bf', 8),
    password        VARCHAR
);

COMMENT ON TABLE users IS 'username and password info';

-- @trigger users_update
DROP TRIGGER IF EXISTS users_update ON users;
CREATE TRIGGER users_update
    BEFORE UPDATE ON users
        FOR EACH ROW
            EXECUTE PROCEDURE update_modified_column();

 -- @method hash_password
 -- @description hashes password before storing in row
CREATE OR REPLACE FUNCTION hash_password()
RETURNS TRIGGER AS $$
    BEGIN
        NEW.password = crypt(NEW.password, NEW.salt);
        RETURN NEW;
    END;
$$ language 'plpgsql';

-- @trigger users_password_insert
-- @description trigger hash password
DROP TRIGGER IF EXISTS users_password_insert ON users;
CREATE TRIGGER users_password_insert
    BEFORE INSERT ON users
        FOR EACH ROW
            EXECUTE PROCEDURE hash_password();

-- @trigger users_password_update
-- @description trigger hash password if password has changed
DROP TRIGGER IF EXISTS users_password_update ON users;
CREATE TRIGGER users_password_update
    BEFORE UPDATE ON users
        FOR EACH ROW
        WHEN (OLD.password IS DISTINCT FROM NEW.password)
            EXECUTE PROCEDURE hash_password();

-- END {USERS}






CREATE TABLE IF NOT EXISTS decks (
    name            VARCHAR,
    -- username        VARCHAR,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    -- FOREIGN KEY (username) REFERENCES users(username) ON DELETE CASCADE,
    -- UNIQUE(username, name)
);


CREATE TABLE IF NOT EXISTS cards (
    deck_name       VARCHAR,
    name            VARCHAR,
    num             VARCHAR,
    data            JSONB,
    tags            JSONB,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (deck_name) REFERENCES decks(name) ON DELETE CASCADE,
    UNIQUE(deck_name, name)
);
