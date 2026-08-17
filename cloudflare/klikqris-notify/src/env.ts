export interface KlikQrisEnv {
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  KLIKQRIS_VERIFY_SIGNATURE?: string;
  KLIKQRIS_NOTIFY_KV?: KVNamespace;
}