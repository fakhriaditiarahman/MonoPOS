/**
 * Supabase (PostgREST) helpers used by the worker.
 *
 * The app stores the KlikQRIS order_id (= local transaction id as string) in the
 * `transactions.paymentExternalId` column, so the worker matches the incoming
 * webhook via that column.
 */

import type { KlikQrisEnv } from './env';

const TRANSACTIONS_TABLE = 'transactions';

interface SupabaseResult {
  ok: boolean;
  matched: boolean;
  status: number;
  body: string;
}

export async function updatePaymentStatus(
  env: KlikQrisEnv,
  paymentExternalId: string,
  status: string,
): Promise<SupabaseResult> {
  const url = new URL(`${env.SUPABASE_URL}/rest/v1/${TRANSACTIONS_TABLE}`);
  url.searchParams.set('paymentExternalId', `eq.${paymentExternalId}`);

  const payload: Record<string, string> = {
    paymentStatus: status,
    updatedAt: new Date().toISOString(),
  };

  const res = await fetch(url.toString(), {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
      Prefer: 'return=representation',
    },
    body: JSON.stringify(payload),
  });

  const body = await res.text();

  let matched = false;
  if (res.status === 200) {
    try {
      const rows = JSON.parse(body);
      matched = Array.isArray(rows) && rows.length > 0;
    } catch {
      matched = false;
    }
  }

  return {
    ok: res.status === 200 || res.status === 204,
    matched,
    status: res.status,
    body,
  };
}