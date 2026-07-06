import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await req.json();
    const serverKey = requiredEnv("MIDTRANS_SERVER_KEY");
    const orderId = `${body.order_id ?? ""}`;
    const statusCode = `${body.status_code ?? ""}`;
    const grossAmount = `${body.gross_amount ?? ""}`;
    const signatureKey = `${body.signature_key ?? ""}`;
    const expected = await sha512(`${orderId}${statusCode}${grossAmount}${serverKey}`);
    if (signatureKey !== expected) {
      return json({ error: "Invalid signature" }, 403);
    }

    const transactionStatus = `${body.transaction_status ?? ""}`;
    const fraudStatus = `${body.fraud_status ?? ""}`;
    const paymentStatus = mapPaymentStatus(transactionStatus, fraudStatus);
    const paidAt = paymentStatus === "paid"
      ? body.settlement_time ?? new Date().toISOString()
      : null;

    const admin = createClient(
      requiredEnv("SUPABASE_URL"),
      requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
    );
    const { data: payment, error: paymentError } = await admin
      .from("payments")
      .update({
        payment_status: paymentStatus,
        transaction_id: body.transaction_id ?? null,
        fraud_status: fraudStatus || null,
        paid_at: paidAt,
        raw_response: body,
      })
      .eq("midtrans_order_id", orderId)
      .select("id, order_id")
      .single();
    if (paymentError) throw paymentError;

    if (paymentStatus === "paid") {
      const { error: completeError } = await admin.rpc(
        "complete_order_with_documents",
        {
          p_order_id: payment.order_id,
          p_payment_id: payment.id,
        },
      );
      if (completeError) throw completeError;
    }

    return json({ ok: true, payment_status: paymentStatus });
  } catch (error) {
    return json({ error: String(error?.message ?? error) }, 500);
  }
});

function mapPaymentStatus(transactionStatus: string, fraudStatus: string): string {
  if (transactionStatus === "capture") {
    return fraudStatus === "accept" ? "paid" : "waiting_verification";
  }
  if (transactionStatus === "settlement") return "paid";
  if (transactionStatus === "pending") return "waiting_verification";
  if (
    transactionStatus === "deny" ||
    transactionStatus === "cancel" ||
    transactionStatus === "expire" ||
    transactionStatus === "failure"
  ) {
    return "rejected";
  }
  return "unpaid";
}

async function sha512(value: string): Promise<string> {
  const buffer = await crypto.subtle.digest(
    "SHA-512",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(buffer)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} belum diset`);
  return value;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

