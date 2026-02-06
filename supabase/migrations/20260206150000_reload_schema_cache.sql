-- Reload PostgREST schema cache to expose waitlist table
NOTIFY pgrst, 'reload schema';
