interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  schema: string;
  record: Record<string, unknown> | null;
  old_record: Record<string, unknown> | null;
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const encoder = new TextEncoder();

function base64Url(input: Uint8Array): string {
  let binary = '';
  for (const byte of input) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function getSupabaseAdminKey(): { key: string; usesNewSecretKey: boolean } | null {
  const secretKeysRaw = Deno.env.get('SUPABASE_SECRET_KEYS');
  if (secretKeysRaw) {
    try {
      const secretKeys = JSON.parse(secretKeysRaw) as Record<string, unknown>;
      const defaultKey = secretKeys.default;
      if (typeof defaultKey === 'string' && defaultKey.trim()) return { key: defaultKey.trim(), usesNewSecretKey: true };
    } catch (error) {
      console.error('SUPABASE_SECRET_KEYS is not valid JSON:', error instanceof Error ? error.message : String(error));
    }
  }

  const legacyKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  return legacyKey?.trim() ? { key: legacyKey.trim(), usesNewSecretKey: false } : null;
}

function parseServiceAccount(raw: string): ServiceAccount {
  let account: unknown;
  try {
    account = JSON.parse(raw);
  } catch (error) {
    throw new Error(`FCM_SERVICE_ACCOUNT_JSON is not valid JSON: ${error instanceof Error ? error.message : String(error)}`);
  }

  if (!account || typeof account !== 'object') {
    throw new Error('FCM_SERVICE_ACCOUNT_JSON must contain a JSON object.');
  }

  const value = account as Record<string, unknown>;
  const projectId = typeof value.project_id === 'string' ? value.project_id.trim() : '';
  const clientEmail = typeof value.client_email === 'string' ? value.client_email.trim() : '';
  const privateKey = typeof value.private_key === 'string' ? value.private_key : '';

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error('FCM service account is missing project_id, client_email, or private_key.');
  }
  if (!privateKey.includes('-----BEGIN PRIVATE KEY-----') || !privateKey.includes('-----END PRIVATE KEY-----')) {
    throw new Error('FCM service account private_key has an invalid PEM format.');
  }

  return { project_id: projectId, client_email: clientEmail, private_key: privateKey };
}

async function createAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(encoder.encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const claim = base64Url(encoder.encode(JSON.stringify({
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })));
  const unsigned = `${header}.${claim}`;

  const pem = account.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  let der: Uint8Array;
  try {
    der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  } catch (error) {
    throw new Error(`FCM private_key is not valid base64: ${error instanceof Error ? error.message : String(error)}`);
  }

  let key: CryptoKey;
  try {
    key = await crypto.subtle.importKey(
      'pkcs8',
      der,
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['sign'],
    );
  } catch (error) {
    throw new Error(`FCM private_key could not be imported as PKCS#8: ${error instanceof Error ? error.message : String(error)}`);
  }

  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, encoder.encode(unsigned));
  const jwt = `${unsigned}.${base64Url(new Uint8Array(signature))}`;

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!response.ok) throw new Error(`FCM OAuth failed (${response.status}): ${await response.text()}`);
  const json = await response.json();
  if (typeof json.access_token !== 'string' || !json.access_token) {
    throw new Error('FCM OAuth response did not contain an access token.');
  }
  return json.access_token;
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });

  const expectedSecret = Deno.env.get('PUSH_WEBHOOK_SECRET');
  if (expectedSecret) {
    const provided = request.headers.get('x-push-webhook-secret');
    if (provided !== expectedSecret) return new Response('Unauthorized', { status: 401 });
  }

  try {
    const payload = await request.json() as WebhookPayload;
    if (payload.type !== 'INSERT' || payload.table !== 'app_notifications' || !payload.record) {
      return Response.json({ skipped: true });
    }

    const notification = payload.record;
    const userId = String(notification.user_id ?? '').trim();
    if (!userId) return Response.json({ skipped: true });

    const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim();
    const supabaseAdmin = getSupabaseAdminKey();
    const supabaseAdminKey = supabaseAdmin?.key ?? null;
    const serviceAccountJson = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')?.trim();

    if (!supabaseUrl) {
      return Response.json({ error: 'Push server configuration is incomplete: SUPABASE_URL is missing.' }, { status: 500 });
    }
    if (!supabaseAdminKey) {
      return Response.json({ error: 'Push server configuration is incomplete: SUPABASE_SECRET_KEYS/SUPABASE_SERVICE_ROLE_KEY is missing.' }, { status: 500 });
    }
    if (!serviceAccountJson) {
      return Response.json({ error: 'Push server configuration is incomplete: FCM_SERVICE_ACCOUNT_JSON is missing.' }, { status: 500 });
    }

    const account = parseServiceAccount(serviceAccountJson);
    const accessToken = await createAccessToken(account);

    const adminHeaders: Record<string, string> = { apikey: supabaseAdminKey };
    if (!supabaseAdmin!.usesNewSecretKey) adminHeaders.Authorization = `Bearer ${supabaseAdminKey}`;

    const deviceResponse = await fetch(
      `${supabaseUrl}/rest/v1/push_devices?select=id,device_token&user_id=eq.${encodeURIComponent(userId)}`,
      { headers: adminHeaders },
    );
    if (!deviceResponse.ok) {
      return Response.json({ error: `Could not load push devices: ${await deviceResponse.text()}` }, { status: 502 });
    }

    const devices = await deviceResponse.json() as Array<{ id: string; device_token: string }>;
    const results: unknown[] = [];
    for (const device of devices) {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(account.project_id)}/messages:send`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: device.device_token,
              notification: {
                title: String(notification.title ?? 'Schmackofatz'),
                body: String(notification.body ?? ''),
              },
              data: {
                notification_id: String(notification.id ?? ''),
                type: String(notification.type ?? 'general'),
                decision_share_id: String(notification.decision_share_id ?? ''),
                decision_request_id: String(notification.decision_request_id ?? ''),
                recipe_suggestion_id: String(notification.recipe_suggestion_id ?? ''),
                recipe_id: String(notification.recipe_id ?? ''),
              },
              android: {
                priority: 'high',
                notification: {
                  channel_id: 'schmackofatz_notifications',
                  sound: 'default',
                },
              },
            },
          }),
        },
      );

      const responseText = await response.text();
      results.push({ deviceId: device.id, status: response.status, response: response.ok ? 'ok' : responseText.slice(0, 500) });

      if (response.status === 404 || response.status === 410 || responseText.includes('UNREGISTERED')) {
        await fetch(`${supabaseUrl}/rest/v1/push_devices?id=eq.${encodeURIComponent(device.id)}`, {
          method: 'DELETE',
          headers: adminHeaders,
        });
      }
    }

    return Response.json({ sent: results.length, results });
  } catch (error) {
    console.error('Push notification failed:', error);
    return Response.json({
      error: error instanceof Error ? error.message : String(error),
    }, { status: 500 });
  }
});
