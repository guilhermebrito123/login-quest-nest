// Temporary custom Supabase client with user-provided credentials
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

const SUPABASE_URL = "https://rividlsiogvoqtgwbnpy.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpdmlkbHNpb2d2b3F0Z3dibnB5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4MDAwMTcsImV4cCI6MjA3ODM3NjAxN30.V82bONVNdc4q2K221t9lthzenMCmwkZNRXGZOEFMeeM";

export const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    storage: localStorage,
    persistSession: true,
    autoRefreshToken: true,
  }
});
