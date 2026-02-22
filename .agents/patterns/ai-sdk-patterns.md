# AI SDK Patterns (Vercel AI SDK)

## Stack Choices

| Technology | Version | Purpose |
|-----------|---------|---------|
| AI SDK (`ai`) | 4.x / 5.x+ | Unified interface for LLM streaming, tool calling, multi-model |
| @ai-sdk/openai | Latest | OpenAI / OpenAI-compatible provider |
| @ai-sdk/anthropic | Latest | Anthropic Claude provider |
| @ai-sdk/google | Latest | Google Gemini provider |
| Zod | 3.x | Tool parameter schemas |

## Core Patterns

### Streaming Text Response (API Route)

```typescript
import { streamText } from "ai"
import { openai } from "@ai-sdk/openai"

app.post("/<endpoint>", async (c) => {
  const { messages } = await c.req.json()

  const result = streamText({
    model: openai("<model-id>"),
    system: "<system-prompt>",
    messages,
    maxSteps: 5, // Allow multi-step tool use
  })

  return result.toDataStreamResponse()
})
```

### Multi-Model Provider Routing

Abstract model selection behind a provider factory so callers pick `provider + model` without importing SDKs:

```typescript
import { openai } from "@ai-sdk/openai"
import { anthropic } from "@ai-sdk/anthropic"
import { google } from "@ai-sdk/google"

const providers = {
  openai: (model: string) => openai(model),
  anthropic: (model: string) => anthropic(model),
  google: (model: string) => google(model),
} as const

type Provider = keyof typeof providers

export function getModel(provider: Provider, model: string) {
  const factory = providers[provider]
  if (!factory) throw new Error(`Unknown provider: ${provider}`)
  return factory(model)
}

// Usage in route:
const result = streamText({
  model: getModel("<provider>", "<model-id>"),
  messages,
})
```

### Tool Definitions with Zod

Tools are functions the model can call. Define with Zod schemas for type-safe parameters:

```typescript
import { tool } from "ai"
import { z } from "zod"

const <tool-name>Tool = tool({
  description: "<What this tool does — one sentence for model context>",
  parameters: z.object({
    query: z.string().describe("<param description>"),
    limit: z.number().optional().default(5).describe("<param description>"),
  }),
  execute: async ({ query, limit }) => {
    const results = await <service>(query, limit)
    return { results }
  },
})

// Pass tools to streamText
const result = streamText({
  model: openai("<model-id>"),
  messages,
  tools: { <toolA>: <toolA>Tool, <toolB>: <toolB>Tool },
  maxSteps: 5,
})
```

### Streaming with UI Messages (React)

Server returns a stream, client consumes with `useChat`:

```typescript
"use client"
import { useChat } from "@ai-sdk/react"

export function <Component>() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat({
    api: "/api/<endpoint>",
  })

  return (
    <div>
      {messages.map((m) => (
        <div key={m.id} className={m.role === "user" ? "text-right" : ""}>
          {m.content}
        </div>
      ))}
      <form onSubmit={handleSubmit}>
        <input value={input} onChange={handleInputChange} />
        <button type="submit" disabled={isLoading}>Send</button>
      </form>
    </div>
  )
}
```

### Generate Object (Structured Output)

Extract structured data from text:

```typescript
import { generateObject } from "ai"
import { z } from "zod"

const { object } = await generateObject({
  model: openai("<model-id>"),
  schema: z.object({
    <field>: z.string(),
    <field>: z.string(),
    <field>: z.array(z.string()),
    <field>: z.enum(["<value-a>", "<value-b>", "<value-c>"]),
  }),
  prompt: `<instruction>: ${<input>}`,
})
// object is fully typed from the schema
```

### Generate Text (Non-streaming)

For simple request/response without streaming:

```typescript
import { generateText } from "ai"

const { text, usage } = await generateText({
  model: anthropic("<model-id>"),
  prompt: "<instruction>",
})
```

### System Prompts

```typescript
const SYSTEM_PROMPT = `<role description>

Rules:
- <rule-1>
- <rule-2>
- If asked to perform actions, use the available tools`

streamText({
  model: openai("<model-id>"),
  system: SYSTEM_PROMPT,
  messages,
  tools,
})
```

### Custom Headers & API Keys (BYOK)

Support user-provided API keys:

```typescript
import { createOpenAI } from "@ai-sdk/openai"

const customProvider = createOpenAI({
  apiKey: <user-provided-key>,
  baseURL: <custom-base-url>,  // Optional: proxy or gateway
})

streamText({
  model: customProvider("<model-id>"),
  messages,
})
```

### AI Gateway / Proxy Pattern

Route all AI traffic through a single gateway for rate limiting, logging, and model routing:

```typescript
import { createOpenAI } from "@ai-sdk/openai"

const gateway = createOpenAI({
  apiKey: process.env.AI_GATEWAY_API_KEY,
  baseURL: "https://<gateway-host>/v1",
})

streamText({
  model: gateway("<provider>/<model-id>"),
  messages,
})
```

## Project Structure

```
src/
├── app/api/
│   └── <endpoint>/
│       └── route.ts              # Streaming endpoint
├── lib/
│   ├── ai/
│   │   ├── providers.ts          # Model provider factory
│   │   ├── prompts.ts            # System prompts
│   │   └── tools/
│   │       ├── <tool-a>.ts       # Tool definition
│   │       ├── <tool-b>.ts       # Tool definition
│   │       └── index.ts          # Tool barrel export
│   └── ...
└── components/
    └── <chat-component>.tsx      # useChat client component
```

## Conventions

- One tool per file in `lib/ai/tools/`
- System prompts as exported constants in `lib/ai/prompts.ts`
- Provider factory centralizes model selection — routes never import SDK providers directly
- Use `maxSteps` to allow multi-step tool calling (model calls tool, reads result, calls another)
- Prefer `streamText` over `generateText` for user-facing features (better perceived latency)
- Use `generateObject` when you need structured data extraction

## Anti-Patterns

- Don't hardcode model names in route handlers — use a provider factory or config
- Don't create provider instances inside request handlers — create once at module level
- Don't skip `maxSteps` when using tools — without it the model gets one shot and can't react to tool results
- Don't use `generateText` for chat UIs — streaming provides much better UX
- Don't put API keys in client-side code — always call AI from server routes

## Docs

- [Vercel AI SDK](https://sdk.vercel.ai/docs)
- [AI SDK Providers](https://sdk.vercel.ai/providers)
- [streamText](https://sdk.vercel.ai/docs/reference/ai-sdk-core/stream-text)
- [generateObject](https://sdk.vercel.ai/docs/reference/ai-sdk-core/generate-object)
- [useChat](https://sdk.vercel.ai/docs/reference/ai-sdk-ui/use-chat)
- [Tool Calling](https://sdk.vercel.ai/docs/ai-sdk-core/tools-and-tool-calling)
- [AI Gateway](https://sdk.vercel.ai/docs/ai-sdk-core/settings#base-url)
