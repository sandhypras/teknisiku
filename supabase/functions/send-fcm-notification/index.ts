import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";
import { importPKCS8, SignJWT } from "npm:jose@5.9.6";

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

type NotificationRow = {
  id: string;
  user_id: string;
  type: string;
  title: string;
  message: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-push-secret",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const expectedSecret = Deno.env.get("PUSH_FUNCTION_SECRET") ?? "";
  const receivedSecret = request.headers.get("x-push-secret") ?? "";
  if (!expectedSecret || receivedSecret !== expectedSecret) {
    return json({ error: "Unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ?? "";
  if (!supabaseUrl || !serviceRoleKey || !serviceAccountJson) {
    return json({ error: "Missing server configuration" }, 500);
  }

  let body: { notification_id?: string };
  try {
    body = await request.json();
  } catch (_) {
    return json({ error: "Invalid JSON body" }, 400);
  }

  if (!body.notification_id) {
    return json({ error: "notification_id is required" }, 400);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { data: notification, error: notificationError } = await supabase
    .from("notifications")
    .select("id, user_id, type, title, message")
    .eq("id", body.notification_id)
    .maybeSingle<NotificationRow>();

  if (notificationError) return json({ error: notificationError.message }, 500);
  if (!notification) return json({ error: "Notification not found" }, 404);

  const { data: tokenRows, error: tokenError } = await supabase
    .from("user_device_tokens")
    .select("id, fcm_token")
    .eq("user_id", notification.user_id)
    .eq("is_active", true);

  if (tokenError) return json({ error: tokenError.message }, 500);
  const tokens = tokenRows ?? [];
  if (tokens.length === 0) {
    return json({ sent: 0, skipped: "No active device tokens" });
  }

  const serviceAccount = parseServiceAccount(serviceAccountJson);
  const accessToken = await createFirebaseAccessToken(serviceAccount);
  const projectId = Deno.env.get("FIREBASE_PROJECT_ID") || serviceAccount.project_id;
  const endpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const results = await Promise.all(
    tokens.map(async (row) => {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: row.fcm_token,
            notification: {
              title: notification.title,
              body: notification.message,
            },
            data: {
              notification_id: notification.id,
              type: notification.type,
            },
            android: {
              priority: "HIGH",
              notification: {
                channel_id: "siteknisi_orders",
                sound: "default",
              },
            },
          },
        }),
      });

      if (response.ok) return { id: row.id, ok: true };

      const errorBody = await response.json().catch(() => ({}));
      const errorStatus = errorBody?.error?.status as string | undefined;
      if (errorStatus === "NOT_FOUND" || errorStatus === "INVALID_ARGUMENT") {
        await supabase
          .from("user_device_tokens")
          .update({ is_active: false })
          .eq("id", row.id);
      }
      return { id: row.id, ok: false, status: response.status, error: errorBody };
    }),
  );

  return json({
    sent: results.filter((item) => item.ok).length,
    failed: results.filter((item) => !item.ok).length,
  });
});

function parseServiceAccount(raw: string): ServiceAccount {
  const parsed = JSON.parse(raw) as ServiceAccount;
  return {
    ...parsed,
    private_key: parsed.private_key.replaceAll("\\n", "\n"),
  };
}

async function createFirebaseAccessToken(serviceAccount: ServiceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const privateKey = await importPKCS8(serviceAccount.private_key, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!response.ok) {
    throw new Error(`Firebase OAuth failed: ${await response.text()}`);
  }

  const data = await response.json() as { access_token?: string };
  if (!data.access_token) throw new Error("Firebase OAuth returned no token");
  return data.access_token;
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
