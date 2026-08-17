/**
 * KlikQRIS QRIS payment notification webhook (Cloudflare Worker).
 *
 * Flow: KlikQRIS POSTs Payment Notification -> optional signature check ->
 * update the matching Supabase `transactions` row by paymentExternalId (= order_id).
 *
 * KlikQRIS signature is a per-transaction token returned by POST /qris/create and
 * echoed in the webhook. Validating it requires storing the signature at create
 * time, which the app does not do yet. Until then keep
 * `KLIKQRIS_VERIFY_SIGNATURE=false` (default) and rely on the KV idempotency
 * check. Flip it to `true` once signatures are persisted.
 */

import type { KlikQrisEnv } from './env';
import { updatePaymentStatus } from './supabase';

type Env = KlikQrisEnv;

const KV_ORDER_ID_PREFIX = 'notif:';

interface NotifyPayload {
  order_id?: string;
  status?: string;
  amount?: number;
  total_amount?: number;
  payment_date?: string;
  signature?: string;
}

const STATUS_MAP: Record<string, string> = {
  PAID: 'paid',
  EXPIRED: 'failed',
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'GET') {
      return json({ status: 'ok' });
    }

    if (request.method !== 'POST') {
      return json({ message: 'Method not allowed' }, 405);
    }

    let payload: NotifyPayload;
    try {
      payload = (await request.json()) as NotifyPayload;
    } catch {
      return json({ message: 'Invalid JSON body' }, 400);
    }

    const orderId = payload.order_id ?? '';
    if (!orderId) {
      console.warn('Missing order_id', { payload });
      return json({ message: 'Missing order_id' }, 400);
    }

    // Idempotency: skip notifications already processed (KlikQRIS may retry).
    if (env.KLIKQRIS_NOTIFY_KV) {
      const seen = await env.KLIKQRIS_NOTIFY_KV.get(`${KV_ORDER_ID_PREFIX}${orderId}`);
      if (seen) {
        return json({ status: true, message: 'Already processed' });
      }
    }

    if (env.KLIKQRIS_VERIFY_SIGNATURE === 'true') {
      if (!payload.signature) {
        return json({ message: 'Missing signature' }, 401);
      }
      // TODO(production): compare against the signature stored at create time.
    }

    const statusCode = payload.status ?? '';
    const paymentStatus = STATUS_MAP[statusCode];

    if (!paymentStatus) {
      console.warn('Unknown transaction status', { statusCode, payload });
      return json({ status: true, message: 'Unhandled status' });
    }

    const result = await updatePaymentStatus(env, orderId, paymentStatus);

    if (!result.ok) {
      console.error('Supabase update failed', { status: result.status, body: result.body });
      return json({ message: 'Upstream update failed' }, 502);
    }

    if (!result.matched) {
      // No matching transaction yet (e.g. the app syncs paymentExternalId later).
      // Do NOT mark KV processed so KlikQRIS retries once the row exists.
      console.warn('Transaction not found, deferring', { orderId, status: statusCode });
      return json({ status: false, message: 'Transaction not found, retry later' }, 202);
    }

    // Mark processed only after a successful update (so retries actually update).
    if (env.KLIKQRIS_NOTIFY_KV) {
      await env.KLIKQRIS_NOTIFY_KV.put(`${KV_ORDER_ID_PREFIX}${orderId}`, '1', {
        expirationTtl: 60 * 60 * 24,
      });
    }

    console.log('Payment notification processed', {
      orderId,
      status: statusCode,
      paymentStatus,
    });

    return json({ status: true, message: 'success' });
  },
} satisfies ExportedHandler<Env>;