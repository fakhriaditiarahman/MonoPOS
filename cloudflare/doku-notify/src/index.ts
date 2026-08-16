/**
 * Doku SNAP QRIS payment notification webhook (Cloudflare Worker).
 *
 * Flow: Doku POSTs Payment Notification -> verify X-SIGNATURE -> update the
 * matching Supabase `transactions` row by paymentExternalId.
 *
 * Secrets (wrangler secret put, never commit):
 *   DOKU_CLIENT_ID, DOKU_CLIENT_SECRET, DOKU_PRIVATE_KEY,
 *   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
 */

import type { DokuEnv } from './doku';
import { verifyNotificationSignature } from './doku';
import { updatePaymentStatus } from './supabase';

type Env = DokuEnv;

const KV_EXTERNAL_ID_PREFIX = 'notif:';

interface NotifyPayload {
  originalPartnerReferenceNo?: string;
  originalReferenceNo?: string;
  originalExternalId?: string;
  latestTransactionStatus?: string;
  transactionStatusDesc?: string;
  amount?: { value?: string; currency?: string };
}

const STATUS_MAP: Record<string, string> = {
  '00': 'paid',
  '03': 'pending',
  '04': 'refunded',
  '05': 'canceled',
  '06': 'failed',
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

    const rawBody = await request.text();
    let payload: NotifyPayload;
    try {
      payload = JSON.parse(rawBody) as NotifyPayload;
    } catch {
      return json({ message: 'Invalid JSON body' }, 400);
    }

    const externalId = request.headers.get('x-external-id') ?? payload.originalExternalId ?? '';

    // Idempotency: skip notifications already processed (Doku may retry).
    if (env.DOKU_NOTIFY_KV && externalId) {
      const seen = await env.DOKU_NOTIFY_KV.get(`${KV_EXTERNAL_ID_PREFIX}${externalId}`);
      if (seen) {
        return json({ responseCode: '2002700', responseMessage: 'success' });
      }
    }

    const signatureValid = await verifyNotificationSignature(env, request.headers, rawBody);
    if (!signatureValid) {
      return json({ message: 'Invalid signature' }, 401);
    }

    const statusCode = payload.latestTransactionStatus ?? '';
    const paymentStatus = STATUS_MAP[statusCode];

    if (!paymentStatus) {
      console.warn('Unknown transaction status', { statusCode, payload });
      return json({ responseCode: '2002700', responseMessage: 'success' });
    }

    const partnerReferenceNo = payload.originalPartnerReferenceNo ?? '';
    if (!partnerReferenceNo) {
      console.warn('Missing originalPartnerReferenceNo', { payload });
      return json({ message: 'Missing originalPartnerReferenceNo' }, 400);
    }

    const result = await updatePaymentStatus(env, partnerReferenceNo, paymentStatus);

    if (!result.ok) {
      console.error('Supabase update failed', { status: result.status, body: result.body });
      return json({ message: 'Upstream update failed' }, 502);
    }

    // Mark processed only after a successful update (so retries actually update).
    if (env.DOKU_NOTIFY_KV && externalId) {
      await env.DOKU_NOTIFY_KV.put(`${KV_EXTERNAL_ID_PREFIX}${externalId}`, '1', { expirationTtl: 60 * 60 * 24 });
    }

    console.log('Payment notification processed', {
      originalPartnerReferenceNo: partnerReferenceNo,
      originalReferenceNo: payload.originalReferenceNo,
      latestTransactionStatus: statusCode,
      paymentStatus,
    });

    return json({ responseCode: '2002700', responseMessage: 'success' });
  },
} satisfies ExportedHandler<Env>;