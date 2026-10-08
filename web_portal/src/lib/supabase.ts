import { createClient } from '@supabase/supabase-js';

export const SUPABASE_URL = 'https://cghgslyikjqghrzhrqxz.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnaGdzbHlpa2pxZ2hyemhycXh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1MTkwODUsImV4cCI6MjEwMjA5NTA4NX0.1o3QkCjopUh0HqUiQmeM_fopQLg9BxTYQcV-_4oeCNs';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
