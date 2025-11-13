-- 1. profiles (Dibuat otomatis oleh Trigger)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT,
  avatar_url TEXT,
  current_tree_level INT DEFAULT 1,
  total_points INT DEFAULT 0
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. zikir_master (Data zikir utama)
CREATE TABLE public.zikir_master (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  arabic_text TEXT,
  translation TEXT,
  fadilah_content TEXT -- Untuk "Deep Dive"
);

-- 3. user_zikir_collections (Koleksi zikir milik user)
CREATE TABLE public.user_zikir_collections (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  zikir_id INT REFERENCES public.zikir_master(id),
  target_count INT DEFAULT 100,
  custom_name TEXT -- Jika user ingin menamai ulang
);
ALTER TABLE public.user_zikir_collections ENABLE ROW LEVEL SECURITY;

-- 4. user_zikir_history (Log histori, diisi oleh RPC)
CREATE TABLE public.user_zikir_history (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id),
  zikir_id INT REFERENCES public.zikir_master(id),
  count INT,
  created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.user_zikir_history ENABLE ROW LEVEL SECURITY;

-- 5. user_badges (Untuk gamifikasi)
CREATE TABLE public.user_badges (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id),
  badge_name TEXT NOT NULL, -- cth: "Pejuang Subuh"
  achieved_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, badge_name) -- User hanya bisa dapat 1 badge unik
);
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

-- 6. prayer_circles (Grup/Lingkaran Doa)
CREATE TABLE public.prayer_circles (
  id SERIAL PRIMARY KEY,
  circle_name TEXT NOT NULL,
  created_by UUID REFERENCES public.profiles(id),
  invite_code TEXT UNIQUE NOT NULL, -- Kode unik untuk bergabung
  created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.prayer_circles ENABLE ROW LEVEL SECURITY;

-- 7. circle_members (Tabel penghubung User dan Circle)
CREATE TABLE public.circle_members (
  circle_id INT REFERENCES public.prayer_circles(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (circle_id, user_id)
);
ALTER TABLE public.circle_members ENABLE ROW LEVEL SECURITY;

-- 8. circle_goals (Target zikir di dalam Circle)
CREATE TABLE public.circle_goals (
  id SERIAL PRIMARY KEY,
  circle_id INT REFERENCES public.prayer_circles(id) ON DELETE CASCADE,
  zikir_id INT REFERENCES public.zikir_master(id),
  target_count INT NOT NULL,
  current_count INT DEFAULT 0,
  created_by UUID REFERENCES public.profiles(id),
  is_active BOOLEAN DEFAULT true
);
ALTER TABLE public.circle_goals ENABLE ROW LEVEL SECURITY;