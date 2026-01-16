# Setup Guide - Pantry App

## Step-by-Step Setup Instructions

### Phase 1: Supabase Setup (10 minutes)

#### 1.1 Create Supabase Project

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Fill in project details:
   - Name: `pantry-app` (or your choice)
   - Database Password: Create a strong password (seAm1FqQHVLihpuL)
   - Region: Choose closest to you
4. Wait for project initialization (2-3 minutes)

#### 1.2 Get API Keys

1. Go to Project Settings > API
2. Copy these values:
   - **Project URL** → `supabaseUrl` in code
   - **anon public** → `supabaseAnonKey` in code
3. Keep these safe (don't commit to version control)

#### 1.3 Set Up Database

1. Go to SQL Editor
2. Create new query
3. Copy entire content from `DATABASE_SCHEMA.sql` file
4. Paste and run the query
5. Verify all tables are created:
   - users
   - pantry_items
   - planner
   - usage_logs

#### 1.4 Create Storage Bucket

1. Go to Storage in left sidebar
2. Click "Create bucket"
3. Name: `user-avatars`
4. Check "Public bucket"
5. Click "Create"
6. Set bucket policy (if needed):
   - Allow public read
   - Allow authenticated upload/delete

#### 1.5 Enable Email Authentication

1. Go to Authentication > Providers
2. Find "Email" provider
3. Make sure it's enabled (usually default)
4. (Optional) Configure email templates for better UX

---

### Phase 2: Flutter Setup (15 minutes)

#### 2.2 Set Up Environment Variables

1. Open the `.env` file in the project root
2. Add your Supabase credentials from Step 1.2:

```env
SUPABASE_URL=https://your-supabase-url.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
```

3. Replace the values with your actual Supabase credentials
4. Save the file

#### 2.3 Install Dependencies

```bash
flutter pub get
```

#### 2.4 Generate JSON Serialization Code

```bash
flutter pub run build_runner build
```

This generates files like `*.g.dart` for JSON serialization

#### 2.5 Verify Project Structure

```bash
flutter pub get  # Install all packages
flutter analyze  # Check for issues
```

---

### Phase 3: Run Application (5 minutes)

#### 3.1 Run App

```bash
flutter run
```

## Next Steps After Setup

1. **Customize Categories**

   - Modify `AppConstants.categoryItems` as needed

2. **Deploy**

   - Build Android APK: `flutter build apk --release`
