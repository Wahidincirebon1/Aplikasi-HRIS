BEGIN;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';

ALTER TABLE users
    DROP CONSTRAINT IF EXISTS users_role_check;

ALTER TABLE users
    ADD CONSTRAINT users_role_check
    CHECK (role IN ('superadmin', 'admin', 'employee'));

ALTER TABLE users
    DROP CONSTRAINT IF EXISTS users_status_check;

ALTER TABLE users
    ADD CONSTRAINT users_status_check
    CHECK (status IN ('pending', 'active', 'inactive'));

CREATE INDEX IF NOT EXISTS idx_users_status_created_at
    ON users (status, created_at DESC);

COMMIT;
