# 📚 Project Knowledge Base - Zikir Progresif

Dokumen ini adalah "otak" dari proyek, berisi keputusan arsitektural dan solusi teknis untuk masalah-masalah krusial. Ini ditujukan untuk developer atau AI agent yang akan melakukan setup.

## 1. Visi Teknis

Membangun aplikasi Flutter yang *stateful*, reaktif, dan efisien dengan Supabase sebagai *backend* tunggal, memprioritaskan pengalaman pengguna *realtime* dengan tetap menjaga efisiensi *database* secara agresif.

## 2. Arsitektur Inti

* **Frontend:** Flutter
* **Backend:** Supabase (SaaS)
* **Database:** Supabase DB (PostgreSQL)
* **Authentication:** Supabase Auth (Google Provider)
* **Realtime:** Supabase Realtime (untuk Prayer Circles)
* **Functions:** Supabase Edge Functions (untuk logika Badges) / PostgreSQL Functions (RPC) (untuk *atomic counter*)

---

## 3. Solusi Kritis 1: Alur Autentikasi (Auth Flow)

**Masalah:** Saat pengguna *signup* via Google, Supabase hanya membuat data di tabel `auth.users`. Tabel `public.profiles` (yang berisi data aplikasi kita seperti `current_tree_level`) tetap kosong.

**Solusi:** Menggunakan **PostgreSQL Trigger** untuk meng-otomatisasi pembuatan profil.

**Eksekusi (Jalankan 1x di SQL Editor Supabase):**
Ini akan membuat "jembatan" otomatis. Setiap ada user baru di `auth.users`, data pentingnya (ID, nama, avatar) akan disalin ke `public.profiles`.

```sql
-- 1. Fungsi yang akan dipanggil
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Masukkan baris baru ke tabel 'profiles' kita
  INSERT INTO public.profiles (id, username, avatar_url, current_tree_level)
  VALUES (
    NEW.id, -- 'id' dari tabel auth.users
    NEW.raw_user_meta_data->>'full_name', -- 'full_name' dari data Google
    NEW.raw_user_meta_data->>'avatar_url', -- 'avatar_url' dari data Google
    1 -- Nilai default untuk Pohon Zikir Level 1
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Trigger yang "mendengarkan" event signup
CREATE OR REPLACE TRIGGER on_auth_user_created
  -- Panggil fungsi 'handle_new_user' SETELAH user baru dibuat
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();