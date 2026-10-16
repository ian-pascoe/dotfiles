import assert from "node:assert/strict";
import type { ClassifierApi, ClassifierContext, ClassifierModel } from "@earendil-works/pi-ai";
import { test } from "vitest";
import { classify, SUBQ_API, SUBQ_BASE_URL } from "./subq.js";

const model: ClassifierModel<ClassifierApi> = {
  type: "classifier",
  id: "subq-snap-preview",
  name: "SubQ Snap Preview",
  api: SUBQ_API,
  provider: "subq",
  baseUrl: SUBQ_BASE_URL,
  input: ["text", "image"],
  contextWindow: 393_216,
  cost: { input: 0.05, output: 0, cacheRead: 0, cacheWrite: 0 },
};

const context: ClassifierContext = {
  state: { message: "Help! My payouts have been failing for 3 days." },
  images: [{ type: "image", data: "iVBORw0KGgo=", mimeType: "image/png" }],
  questions: {
    escalate: {
      type: "bool",
      instructions: "Should this be escalated?",
      criteria: { true: "Escalate", false: "Routine" },
    },
    queue: {
      type: "choice",
      instructions: "Which queue?",
      criteria: { billing: "Payments", other: "Anything else" },
    },
    urgency: { type: "score", instructions: "How urgent?", criteria: ["low", "high"] },
  },
};

function recordingFetch(status: number, body: unknown) {
  const calls: { url: string; init: RequestInit }[] = [];
  const fetch = async (url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: url instanceof Request ? url.url : url.toString(), init: init ?? {} });
    return new Response(JSON.stringify(body), { status });
  };
  return { calls, fetch: fetch as typeof globalThis.fetch };
}

test("sends a System One request with images and maps answers back to pi's types", async () => {
  const { calls, fetch } = recordingFetch(200, {
    model: "subq-snap-preview",
    answers: {
      escalate: { type: "noul", noul: 0.92 },
      queue: {
        type: "choice",
        choice: "billing",
        probabilities: { billing: 0.9, other: 0.1 },
        confidence: 0.8,
      },
      urgency: { type: "score", score: 0.7, confidence: 0.4, legend: {}, probabilities: {} },
    },
    usage: { input_tokens: 2_000_000, output_tokens: 0 },
  });

  const result = await classify(model, context, { apiKey: "sk-test", fetch });

  assert.equal(result.errorMessage, undefined);
  assert.equal(result.stopReason, "stop");
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, "https://api.subq.ai/v1/systemone");
  assert.equal((calls[0].init.headers as Record<string, string>).authorization, "Bearer sk-test");
  const body = calls[0].init.body;
  assert.equal(typeof body, "string");
  const sent = JSON.parse(body as string);
  assert.equal(sent.model, "subq-snap-preview");
  assert.equal(sent.questions.escalate.type, "noul");
  assert.deepEqual(sent.images, [{ mediaType: "image/png", base64: "iVBORw0KGgo=" }]);

  assert.deepEqual(result.answers, {
    escalate: { type: "bool", probability: 0.92 },
    queue: {
      type: "choice",
      choice: "billing",
      probabilities: { billing: 0.9, other: 0.1 },
      confidence: 0.8,
    },
    urgency: { type: "score", score: 0.7, confidence: 0.4 },
  });
  assert.equal(result.usage?.input, 2_000_000);
  assert.equal(result.usage?.cost.total, 0.1);
});

test("reports SubQ's error detail instead of throwing", async () => {
  const { fetch } = recordingFetch(402, {
    detail: { error_type: "insufficient_credits", message: "Insufficient credits." },
  });

  const result = await classify(model, context, { apiKey: "sk-test", fetch });

  assert.equal(result.stopReason, "error");
  assert.equal(result.errorMessage, "SubQ Decisions API returned 402: Insufficient credits.");
});

test("asks for a login when no API key resolved", async () => {
  const result = await classify(model, context, {});

  assert.equal(result.stopReason, "error");
  assert.match(result.errorMessage ?? "", /\/login subq/u);
});
