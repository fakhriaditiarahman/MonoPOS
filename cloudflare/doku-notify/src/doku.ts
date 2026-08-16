/**
 * Doku SNAP signature verification + B2B access token.
 *
 * Notification signature (Symmetric Signature with Get Token):
 *   stringToSign = HTTPMethod:EndpointUrl:AccessToken:Lowercase(HexEncode(SHA256(minify(body)))):Timestamp
 *   X-SIGNATURE  = HMAC_SHA512(clientSecret, stringToSign) -> base64
 *
 * Reference: https://developers.doku.com/get-started-with-doku-api/signature-component/snap/symmetric-signature
 */

export interface DokuEnv {
  DOKU_CLIENT_ID: string;
  DOKU_CLIENT_SECRET: string;
  DOKU_PRIVATE_KEY: string;
  DOKU_IS_SANDBOX?: string;
  DOKU_NOTIFY_PATH?: string;
  DOKU_VERIFY_SIGNATURE?: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  DOKU_NOTIFY_KV?: KVNamespace;
}

const SANDBOX_BASE = 'https://api-sandbox.doku.com';
const PROD_BASE = 'https://api.doku.com';

function getBaseUrl(env: DokuEnv): string {
  return env.DOKU_IS_SANDBOX === 'true' ? SANDBOX_BASE : PROD_BASE;
}

function b64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

function bytesToHex(bytes: Uint8Array): string {
  return [...bytes].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function pemToDer(pem: string): ArrayBuffer {
  const body = pem
    .replace(/-----BEGIN [^-]+-----/g, '')
    .replace(/-----END [^-]+-----/g, '')
    .replace(/\s+/g, '');
  const bin = atob(body);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

/** ISO8601 timestamp with local offset (matches Doku X-TIMESTAMP format). */
export function generateTimestamp(): string {
  const now = new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  const offset = -now.getTimezoneOffset();
  const sign = offset >= 0 ? '+' : '-';
  const abs = Math.abs(offset);
  const hh = pad(Math.floor(abs / 60));
  const mm = pad(abs % 60);
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}T${pad(
    now.getHours(),
  )}:${pad(now.getMinutes())}:${pad(now.getSeconds())}${sign}${hh}:${mm}`;
}

async function rsaSignSha256(privateKeyPem: string, data: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(privateKeyPem),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(data));
  return bytesToHex(new Uint8Array(sig));
}

/** Fetch a B2B access token. Not cached here — caller caches in KV. */
export async function getAccessToken(env: DokuEnv): Promise<string> {
  const timestamp = generateTimestamp();
  const stringToSign = `${env.DOKU_CLIENT_ID}|${timestamp}`;
  const signature = await rsaSignSha256(env.DOKU_PRIVATE_KEY, stringToSign);

  const res = await fetch(`${getBaseUrl(env)}/authorization/v1/access-token/b2b`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CLIENT-KEY': env.DOKU_CLIENT_ID,
      'X-TIMESTAMP': timestamp,
      'X-SIGNATURE': signature,
    },
    body: JSON.stringify({ grantType: 'client_credentials' }),
  });

  if (res.status !== 200) {
    throw new Error(`Doku token error (${res.status}): ${await res.text()}`);
  }

  const json = (await res.json()) as { responseCode?: string; accessToken?: string };
  if (json.responseCode !== '2007300' || !json.accessToken) {
    throw new Error(`Doku token failed: ${json.responseCode}`);
  }

  return json.accessToken;
}

const TOKEN_CACHE_KEY = 'doku_b2b_token';

async function getCachedToken(env: DokuEnv): Promise<string> {
  if (!env.DOKU_NOTIFY_KV) return getAccessToken(env);

  const cached = await env.DOKU_NOTIFY_KV.get(TOKEN_CACHE_KEY);
  if (cached) return cached;

  const token = await getAccessToken(env);
  // Token TTL is 900s; cache slightly below to avoid expiry races.
  await env.DOKU_NOTIFY_KV.put(TOKEN_CACHE_KEY, token, { expirationTtl: 840 });
  return token;
}

async function invalidateToken(env: DokuEnv): Promise<void> {
  if (env.DOKU_NOTIFY_KV) await env.DOKU_NOTIFY_KV.delete(TOKEN_CACHE_KEY);
}

function minifyJson(raw: string): string {
  return JSON.stringify(JSON.parse(raw));
}

async function hmacSha512Base64(secret: string, data: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-512' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(data));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

async function computeSignature(
  env: DokuEnv,
  accessToken: string,
  rawBody: string,
  timestamp: string,
): Promise<string> {
  const method = 'POST';
  const endpointUrl = env.DOKU_NOTIFY_PATH ?? '/';
  const hexHash = bytesToHex(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(minifyJson(rawBody))))).toLowerCase();
  const stringToSign = `${method}:${endpointUrl}:${accessToken}:${hexHash}:${timestamp}`;
  return hmacSha512Base64(env.DOKU_CLIENT_SECRET, stringToSign);
}

/** Verify the X-SIGNATURE header of an incoming notification. */
export async function verifyNotificationSignature(
  env: DokuEnv,
  headers: Headers,
  rawBody: string,
): Promise<boolean> {
  if (env.DOKU_VERIFY_SIGNATURE === 'false') return true;

  const received = headers.get('x-signature');
  const timestamp = headers.get('x-timestamp');
  if (!received || !timestamp) return false;

  const accessToken = await getCachedToken(env);
  const expected = await computeSignature(env, accessToken, rawBody, timestamp);

  if (received === expected) return true;

  // Token may have rotated between signing and verification — refresh once.
  // If refresh or retry fails, treat as invalid signature (never throw).
  try {
    await invalidateToken(env);
    const freshToken = await getCachedToken(env);
    const retry = await computeSignature(env, freshToken, rawBody, timestamp);
    return received === retry;
  } catch {
    return false;
  }
}