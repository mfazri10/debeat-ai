-- Script inisialisasi database
-- Dijalankan otomatis oleh Docker saat postgres container pertama kali dibuat

-- ============================================================
-- Extensions
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================
-- Verifikasi pgvector terinstall
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
    RAISE EXCEPTION 'pgvector extension not installed!';
  END IF;
  RAISE NOTICE 'pgvector OK — dimension support: up to 2000';
END$$;
