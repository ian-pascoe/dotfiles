import { calculateCost } from "@earendil-works/pi-ai";
import type {
  ClassifierAnswer,
  ClassifierApi,
  ClassifierContext,
  ClassifierModel,
  ClassifierOptions,
  ClassifierResult,
  ProviderHeaders,
  Usage,
} from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// SubQ's Decisions API speaks the System One protocol. Pi's built-in
// `typesafe-system-one` classifier rejects images and is not importable from
// extensions, so this implements the request directly.
// Docs: https://docs.subq.ai/endpoints/decisions-api/
export const SUBQ_API = "subq-decisions";
export const SUBQ_BASE_URL = "https://api.subq.ai/v1";

const LABEL = "SubQ Decisions API";
const IMAGE_TYPES = new Set(["image/png", "image/jpeg", "image/webp"]);
const MAX_IMAGES = 4;

type JsonRecord = Record<string, unknown>;

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function num(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new Error(`${LABEL} returned an invalid ${field}`);
  }
  return value;
}

function probabilities(value: unknown, id: string): Record<string, number> {
  if (!isRecord(value)) throw new Error(`${LABEL} returned invalid probabilities for ${id}`);
  return Object.fromEntries(
    Object.entries(value).map(([key, p]) => [key, num(p, `probability for ${id}.${key}`)]),
  );
}

export function wireRequest(model: ClassifierModel<ClassifierApi>, context: ClassifierContext) {
  const images = context.images ?? [];
  if (images.length > MAX_IMAGES) throw new Error(`${LABEL} accepts at most ${MAX_IMAGES} images`);
  for (const image of images) {
    if (!IMAGE_TYPES.has(image.mimeType)) {
      throw new Error(`${LABEL} does not accept ${image.mimeType} images; use PNG, JPEG, or WebP`);
    }
  }
  return {
    model: model.id,
    state: context.state,
    questions: Object.fromEntries(
      Object.entries(context.questions).map(([id, q]) => [
        id,
        q.type === "bool" ? { ...q, type: "noul" } : q,
      ]),
    ),
    ...(images.length > 0 && {
      images: images.map((image) => ({ mediaType: image.mimeType, base64: image.data })),
    }),
  };
}

export function parseAnswers(
  value: unknown,
  context: ClassifierContext,
): Record<string, ClassifierAnswer> {
  if (!isRecord(value)) throw new Error(`${LABEL} returned an unexpected response`);
  const answers: Record<string, ClassifierAnswer> = {};
  for (const [id, question] of Object.entries(context.questions)) {
    const answer = value[id];
    if (!isRecord(answer)) throw new Error(`${LABEL} did not return an answer for ${id}`);
    if (question.type === "choice") {
      if (answer.type !== "choice" || typeof answer.choice !== "string") {
        throw new Error(`${LABEL} did not return a choice answer for ${id}`);
      }
      answers[id] = {
        type: "choice",
        choice: answer.choice,
        probabilities: probabilities(answer.probabilities, id),
        confidence: num(answer.confidence, `confidence for ${id}`),
      };
    } else if (question.type === "score") {
      if (answer.type !== "score")
        throw new Error(`${LABEL} did not return a score answer for ${id}`);
      answers[id] = {
        type: "score",
        score: num(answer.score, `score for ${id}`),
        confidence: num(answer.confidence, `confidence for ${id}`),
      };
    } else {
      if (answer.type !== "noul")
        throw new Error(`${LABEL} did not return a bool answer for ${id}`);
      answers[id] = { type: "bool", probability: num(answer.noul, `probability for ${id}`) };
    }
  }
  return answers;
}

function tokens(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) && value > 0 ? value : 0;
}

export function parseUsage(
  value: unknown,
  model: ClassifierModel<ClassifierApi>,
): Usage | undefined {
  if (!isRecord(value) || (value.input_tokens === undefined && value.output_tokens === undefined)) {
    return undefined;
  }
  const input = tokens(value.input_tokens);
  const output = tokens(value.output_tokens);
  const usage: Usage = {
    input,
    output,
    cacheRead: 0,
    cacheWrite: 0,
    totalTokens: input + output,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
  };
  usage.cost = calculateCost(model, usage);
  return usage;
}

function headers(apiKey: string, ...sources: (ProviderHeaders | undefined)[]) {
  const result: Record<string, string> = {
    authorization: `Bearer ${apiKey}`,
    "content-type": "application/json",
  };
  for (const source of sources) {
    for (const [key, value] of Object.entries(source ?? {})) {
      if (value === null) delete result[key.toLowerCase()];
      else result[key.toLowerCase()] = value;
    }
  }
  return result;
}

function errorDetail(body: string): string {
  try {
    const parsed: unknown = JSON.parse(body);
    if (isRecord(parsed) && isRecord(parsed.detail) && typeof parsed.detail.message === "string") {
      return parsed.detail.message;
    }
  } catch {
    // Not JSON; fall through to the raw body.
  }
  return body.slice(0, 500);
}

export async function classify(
  model: ClassifierModel<ClassifierApi>,
  context: ClassifierContext,
  options?: ClassifierOptions,
): Promise<ClassifierResult> {
  const result: ClassifierResult = {
    api: model.api,
    provider: model.provider,
    model: model.id,
    answers: {},
    stopReason: "stop",
    timestamp: Date.now(),
  };
  try {
    if (!options?.apiKey) {
      throw new Error(`No API key for provider ${model.provider}; run /login ${model.provider}`);
    }
    let payload: unknown = wireRequest(model, context);
    const transformed = await options.onPayload?.(payload, model);
    if (transformed !== undefined) payload = transformed;

    const timeout =
      options.timeoutMs === undefined ? undefined : AbortSignal.timeout(options.timeoutMs);
    const signal =
      options.signal && timeout
        ? AbortSignal.any([options.signal, timeout])
        : (options.signal ?? timeout);
    const response = await (options.fetch ?? globalThis.fetch)(
      new URL("systemone", `${model.baseUrl.replace(/\/+$/u, "")}/`),
      {
        method: "POST",
        headers: headers(options.apiKey, model.headers, options.headers),
        body: JSON.stringify(payload),
        signal,
      },
    );
    await options.onResponse?.(
      { status: response.status, headers: Object.fromEntries(response.headers.entries()) },
      model,
    );
    if (!response.ok) {
      throw new Error(
        `${LABEL} returned ${response.status}: ${errorDetail(await response.text())}`,
      );
    }
    const body: unknown = await response.json();
    if (!isRecord(body)) throw new Error(`${LABEL} returned an unexpected response`);
    const usage = parseUsage(body.usage, model);
    if (usage) result.usage = usage;
    result.answers = parseAnswers(body.answers, context);
  } catch (error) {
    result.stopReason = options?.signal?.aborted ? "aborted" : "error";
    result.errorMessage = error instanceof Error ? error.message : String(error);
  }
  return result;
}

export default function (pi: ExtensionAPI) {
  pi.registerProvider("subq", {
    name: "SubQ",
    // `/login subq` stores a key in ~/.pi/agent/auth.json, which takes
    // precedence; the environment variable is the fallback.
    apiKey: "$SUBQ_API_KEY",
    baseUrl: SUBQ_BASE_URL,
    models: [
      {
        type: "classifier",
        id: "subq-snap-preview",
        name: "SubQ Snap Preview",
        api: SUBQ_API,
        input: ["text", "image"],
        contextWindow: 393_216,
        // USD per 1M tokens; SubQ bills input only.
        cost: { input: 0.05, output: 0, cacheRead: 0, cacheWrite: 0 },
      },
    ],
    classifiers: { [SUBQ_API]: { classify } },
  });
}
