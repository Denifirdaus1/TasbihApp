# Tasbih Collection UI/UX Improvements & Reminder Feature

## Overview
This document outlines the improvements made to the Tasbih Collection feature, including enhanced UI/UX and a new reminder scheduling system.

## Features Implemented

### 1. Improved UI/UX for Tasbih Collections Screen

**Changes:**
- **Two-Section Layout**: Collections are now organized into two clear sections:
  - **Dzikir 5 Waktu** (Prayer Times): For collections tied to the 5 daily prayers
  - **Koleksi Kustom** (Custom Collections): For personal collections that can be read anytime
  
- **Visual Hierarchy**: 
  - Each section has a dedicated icon and title
  - Descriptive subtitles explain the purpose of each section
  - Color-coded icons for prayer times (dawn, noon, afternoon, evening, night)

- **Empty States**: 
  - Informative empty state cards for each section
  - Quick action buttons to create default collections or custom ones
  - Clear messaging about what each collection type is for

- **Default Collections Button**: 
  - One-click creation of default prayer time collections
  - Automatically creates 5 collections (Subuh, Dhuhur, Ashar, Maghrib, Isya)
  - Each comes pre-populated with 3 standard dhikr items (Subhanallah, Alhamdulillah, Allahu Akbar)

### 2. Default Prayer Time Collections

**Included Collections:**
1. **Dzikir Subuh** (Fajr) - Dawn prayer dhikr
   - Icon: sunrise/twilight
   - Color: Red (#FF6B6B)
   
2. **Dzikir Dhuhur** (Dhuhr) - Noon prayer dhikr
   - Icon: sun
   - Color: Orange (#FFA726)
   
3. **Dzikir Ashar** (Asr) - Afternoon prayer dhikr
   - Icon: cloudy sun
   - Color: Light Orange (#FFB74D)
   
4. **Dzikir Maghrib** (Maghrib) - Evening prayer dhikr
   - Icon: crescent moon
   - Color: Purple (#9575CD)
   
5. **Dzikir Isya** (Isha) - Night prayer dhikr
   - Icon: night moon
   - Color: Dark Purple (#5C6BC0)

**Default Dhikr Items** (automatically added to each collection):
- سُبْحَانَ اللهِ (Subhanallah) - 33x
- اَلْحَمْدُ لِلّٰهِ (Alhamdulillah) - 33x  
- اللّٰهُ أَكْبَرُ (Allahu Akbar) - 33x

### 3. Reminder/Notification Scheduling Feature

**New Reminder Settings Screen:**
- Accessible from each collection detail screen via notification icon
- Toggle to enable/disable reminders
- Time picker for scheduling notifications
- Day selector (Monday-Sunday) for recurring reminders
- Custom message editor (up to 200 characters)
- Preview of collection details

**Notification Features:**
- Daily recurring notifications at specified time
- Collection-specific reminders (each collection can have its own reminder)
- Custom notification messages
- Persistent notifications (survives app restarts)
- Uses Android's exact alarm scheduling for reliability

## Database Schema

### New Table: `tasbih_reminders`

Run the following SQL in your Supabase SQL Editor:

```sql
-- Tasbih Reminder Settings Table
CREATE TABLE IF NOT EXISTS public.tasbih_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  collection_id UUID NOT NULL REFERENCES public.tasbih_collections(id) ON DELETE CASCADE,
  is_enabled BOOLEAN DEFAULT true,
  scheduled_time TIME, -- Format HH:MM (24-hour)
  prayer_time TEXT, -- 'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'
  custom_message TEXT,
  days_of_week INTEGER[] DEFAULT ARRAY[1,2,3,4,5,6,7], -- 1=Monday, 7=Sunday
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, collection_id)
);

-- Enable RLS
ALTER TABLE public.tasbih_reminders ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own reminders"
  ON public.tasbih_reminders
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own reminders"
  ON public.tasbih_reminders
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reminders"
  ON public.tasbih_reminders
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reminders"
  ON public.tasbih_reminders
  FOR DELETE
  USING (auth.uid() = user_id);

-- Add prayer_time column to tasbih_collections if not exists
ALTER TABLE public.tasbih_collections 
ADD COLUMN IF NOT EXISTS prayer_time TEXT;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_tasbih_reminders_user_id 
  ON public.tasbih_reminders(user_id);

CREATE INDEX IF NOT EXISTS idx_tasbih_reminders_collection_id 
  ON public.tasbih_reminders(collection_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_tasbih_reminder_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_tasbih_reminder_timestamp
  BEFORE UPDATE ON public.tasbih_reminders
  FOR EACH ROW
  EXECUTE FUNCTION update_tasbih_reminder_updated_at();
```

## How to Use

### Creating Default Prayer Time Collections

1. Open the app and navigate to the **Tasbih** tab
2. If you have no collections, you'll see two options:
   - **"Buat Koleksi 5 Waktu"** (Create Prayer Time Collections) - Recommended
   - **"Buat Koleksi Kustom"** (Create Custom Collection)
3. Click **"Buat Koleksi 5 Waktu"**
4. Wait a moment while all 5 collections are created
5. You'll see all 5 prayer time collections appear in the "Dzikir 5 Waktu" section

### Setting Up Reminders

1. Navigate to any collection detail screen
2. Tap the **notification bell icon** in the app bar
3. Toggle **"Aktifkan Pengingat"** (Enable Reminder) to ON
4. **Set Time**: Tap "Atur Waktu" to choose when you want to be reminded
5. **Select Days**: Choose which days of the week the reminder should repeat
6. **Customize Message** (optional): Edit the notification message
7. Tap **"Simpan Pengingat"** (Save Reminder)

### Managing Collections

**Prayer Time Collections:**
- Automatically organized in the "Dzikir 5 Waktu" section
- Cannot change the type after creation
- Includes special prayer time indicators

**Custom Collections:**
- Organized in "Koleksi Kustom" section
- Create via the "+" icon or "Baru" button
- Can be for any purpose (morning dhikr, evening dhikr, special occasions, etc.)

## Technical Details

### New Files Created

1. **`lib/features/tasbih/domain/prayer_time.dart`**
   - Enum for 5 prayer times
   - Default prayer collection data
   - Default dhikr items

2. **`lib/features/tasbih/domain/reminder_settings.dart`**
   - Data model for reminder settings
   - Serialization/deserialization methods

3. **`lib/features/tasbih/presentation/reminder_settings_screen.dart`**
   - Full-featured reminder configuration screen
   - Time picker, day selector, message editor

4. **`App_Knowledge/reminder_schema.sql`**
   - Complete database schema for reminders
   - RLS policies and triggers

### Modified Files

1. **`lib/features/tasbih/domain/tasbih_collection.dart`**
   - Added `prayerTime` field
   - Updated serialization methods

2. **`lib/features/tasbih/data/tasbih_repository.dart`**
   - Added `createDefaultPrayerCollections()` method
   - Added reminder CRUD methods
   - Updated `createCollection()` to support prayer time

3. **`lib/features/tasbih/presentation/tasbih_collections_screen.dart`**
   - Complete UI overhaul with two-section layout
   - Added default collection creation button
   - Improved empty states
   - Better visual hierarchy

4. **`lib/features/tasbih/presentation/tasbih_collection_detail_screen.dart`**
   - Added notification icon to access reminder settings

5. **`lib/features/tasbih/presentation/tasbih_providers.dart`**
   - Added `createDefaultCollectionsAction()` function
   - Updated `createCollectionAction()` to support prayer time

6. **`lib/core/notifications/notification_service.dart`**
   - Added `scheduleCollectionReminder()` method
   - Added `cancelCollectionReminder()` method
   - Added `cancelAllReminders()` method

## Testing Checklist

- [ ] Run database migrations in Supabase
- [ ] Create default prayer time collections
- [ ] Verify all 5 collections appear in correct section
- [ ] Verify each collection has 3 default dhikr items
- [ ] Create a custom collection
- [ ] Verify it appears in "Koleksi Kustom" section
- [ ] Set up a reminder for a collection
- [ ] Verify notification appears at scheduled time
- [ ] Disable a reminder and verify notification stops
- [ ] Test time picker functionality
- [ ] Test day selector functionality
- [ ] Test custom message editing

## Android Permissions

Make sure your `AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

## Future Enhancements

Potential improvements for future iterations:

1. **Smart Prayer Time Integration**
   - Auto-schedule reminders based on actual prayer times
   - Integrate with prayer time APIs
   - Automatic time adjustment based on location

2. **Reminder Statistics**
   - Track how often reminders lead to completions
   - Show streak of consecutive days

3. **Multiple Reminders Per Collection**
   - Allow multiple reminders at different times
   - Pre and post-prayer reminders

4. **Notification Customization**
   - Different notification sounds per collection
   - Vibration patterns
   - LED color customization

5. **Export/Import**
   - Share collection configurations
   - Backup and restore reminder settings

## Troubleshooting

**Problem:** Collections not appearing after creation
**Solution:** Pull down to refresh the screen

**Problem:** Notifications not appearing
**Solution:** 
- Check notification permissions in device settings
- Verify notification channels are enabled
- Check battery optimization settings

**Problem:** Default collections already exist error
**Solution:** The system prevents duplicate default collections. Delete existing prayer time collections first if you want to recreate them.

**Problem:** Database error when saving reminder
**Solution:** Ensure the reminder schema SQL has been executed in Supabase

## Support

For issues or questions, check:
1. Flutter logs: `flutter logs`
2. Supabase logs in dashboard
3. Device notification settings
4. App permissions

---

**Version:** 1.0.0  
**Last Updated:** 2025-11-14  
**Author:** Factory Droid
