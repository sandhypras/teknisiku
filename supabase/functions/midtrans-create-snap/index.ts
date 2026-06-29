import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type OrderRow = {
  id: string;
  order_number: string;
  customer_id: string;
  status: string;
  estimated_total: number | string | null;
  final_total: number | string | null;
  customer?: {
    full_name?: string | null;
    email?: string | null;
    phone?: string | null;
  } | null;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const anonKey = requiredEnv("SUPABASE_ANON_KEY");
    const serviceKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const serverKey = requiredEnv("MIDTRANS_SERVER_KEY");
    const appUrl = Deno.env.get("APP_PUBLIC_URL") ?? "https://example.com";
    const notificationUrl =
      Deno.env.get("MIDTRANS_NOTIFICATION_URL") ??
      `${supabaseUrl}/functions/v1/midtrans-webhook`;

    const authHeader = req.headers.get("Authorization") ?? "";
    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userError,
    } = await authClient.auth.getUser();
    if (userError || !user) {
      return json({ error: "User belum login" }, 401);
    }

    const { order_id } = await req.json().catch(() => ({ order_id: null }));
    if (!order_id || typeof order_id !== "string") {
      return json({ error: "order_id wajib diisi" }, 400);
    }

    const admin = createClient(supabaseUrl, serviceKey);
    const { data: order, error: orderError } = await admin
      .from("orders")
      .select(
        "id, order_number, customer_id, status, estimated_total, final_total, customer:profiles!customer_id(full_name, email, phone)",
      )
      .eq("id", order_id)
      .single<OrderRow>();
    if (orderError || !order) return json({ error: "Order tidak ditemukan" }, 404);
    if (order.customer_id !== user.id) {
      return json({ error: "Order bukan milik user ini" }, 403);
    }
    if (!["waiting_payment", "completed"].includes(order.status)) {
      return json(
        { error: "Pembayaran hanya tersedia untuk order yang menunggu pembayaran" },
        409,
      );
    }

    const amount = Math.round(
      Number(order.final_total ?? 0) > 0
        ? Number(order.final_total)
        : Number(order.estimated_total ?? 0),
    );
    if (!Number.isFinite(amount) || amount <= 0) {
      return json({ error: "Nominal pembayaran tidak valid" }, 422);
    }

    const midtransOrderId = `ST-${order.id}`;
    const { data: existing } = await admin
      .from("payments")
      .select(
        "id, payment_status, snap_token, snap_redirect_url, midtrans_order_id",
      )
      .eq("order_id", order.id)
      .maybeSingle();

    if (
      existing?.snap_redirect_url &&
      ["unpaid", "waiting_verification"].includes(existing.payment_status)
    ) {
      return json({
        payment_id: existing.id,
        midtrans_order_id: existing.midtrans_order_id,
        token: existing.snap_token,
        redirect_url: existing.snap_redirect_url,
        reused: true,
      });
    }
    if (existing?.payment_status === "paid") {
      return json({ error: "Pembayaran order ini sudah lunas" }, 409);
    }

    const payload = {
      transaction_details: {
        order_id: midtransOrderId,
        gross_amount: amount,
      },
      customer_details: {
        first_name: order.customer?.full_name ?? "Customer Si Teknisi",
        email: order.customer?.email ?? user.email,
        phone: order.customer?.phone ?? "",
      },
      item_details: [
        {
          id: order.order_number,
          price: amount,
          quantity: 1,
          name: `Pembayaran ${order.order_number}`,
        },
      ],
      callbacks: {
        finish: `${appUrl}/payment/finish`,
        error: `${appUrl}/payment/error`,
        pending: `${appUrl}/payment/pending`,
      },
      enabled_payments: [
        "bank_transfer",
        "gopay",
        "shopeepay",
        "credit_card",
      ],
    };

    const snapResponse = await fetch(
      "https://app.sandbox.midtrans.com/snap/v1/transactions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          Authorization: `Basic ${btoa(`${serverKey}:`)}`,
          "X-Override-Notification": notificationUrl,
        },
        body: JSON.stringify(payload),
      },
    );
    const snapBody = await snapResponse.json().catch(() => ({}));
    if (!snapResponse.ok) {
      return json(
        {
          error: "Gagal membuat transaksi Midtrans",
          details: snapBody,
        },
        snapResponse.status,
      );
    }

    const paymentPayload = {
      order_id: order.id,
      payment_method: "bank_transfer",
      amount,
      payment_status: "waiting_verification",
      midtrans_order_id: midtransOrderId,
      snap_token: snapBody.token,
      snap_redirect_url: snapBody.redirect_url,
      raw_response: snapBody,
    };
    const { data: payment, error: paymentError } = existing
      ? await admin
          .from("payments")
          .update(paymentPayload)
          .eq("id", existing.id)
          .select("id")
          .single()
      : await admin
          .from("payments")
          .insert(paymentPayload)
          .select("id")
          .single();
    if (paymentError) throw paymentError;

    return json({
      payment_id: payment.id,
      midtrans_order_id: midtransOrderId,
      token: snapBody.token,
      redirect_url: snapBody.redirect_url,
      reused: false,
    });
  } catch (error) {
    return json({ error: String(error?.message ?? error) }, 500);
  }
});

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} belum diset`);
  return value;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
