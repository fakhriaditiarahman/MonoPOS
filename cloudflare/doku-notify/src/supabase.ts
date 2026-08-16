/**
 * Supabase (PostgREST) helpers used by the worker.
 *
 * The local app stores the Doku partnerReferenceNo (= transaction id as string)
 * in the `transactions.paymentExternalId` column, so the worker matches the
 * incoming notification via that column.
 */

import type { DokuEnv } from './doku';

const TRANSACTIONS_TABLE = 'transactions';

interface SupabaseResult {
  ok: boolean;
  matched: boolean;
  status: number;
  body: string;
}

export async function updatePaymentStatus(
  env: DokuEnv,
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
      Prefer: 'return=minimal',
    },
    body: JSON.stringify(payload),
  });

  return {
    ok: res.status === 200 || res.status === 204,
    matched: res.status === 200 || res.status === 204,
    status: res.status,
    body: await res.text(),
  };
}