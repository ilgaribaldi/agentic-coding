# MCP Server Patterns (Model Context Protocol)

## Stack Choices

| Technology | Version | Purpose |
|-----------|---------|---------|
| @modelcontextprotocol/sdk | 1.x+ | MCP server/client SDK |
| Zod | 3.x | Tool parameter validation |
| TypeScript | 5.x | Type safety |

## Overview

MCP (Model Context Protocol) is a standard for AI agents to interact with external tools and data sources. An MCP server exposes tools that AI clients (Claude, ChatGPT, custom agents) can discover and call.

## Project Structure

```
src/
├── index.ts                  # Server entry point (stdio transport)
├── tools/
│   ├── <domain-a>.ts         # <Domain A> tools
│   ├── <domain-b>.ts         # <Domain B> tools
│   ├── <domain-c>.ts         # <Domain C> tools
│   └── index.ts              # Tool registration barrel
├── schemas/                  # Shared Zod schemas
│   └── common.ts
└── utils/
    └── errors.ts
```

## Core Patterns

### Server Entry Point

```typescript
import { McpServer, ResourceTemplate } from "@modelcontextprotocol/sdk/server/mcp.js"
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js"
import { register<DomainA>Tools } from "./tools/<domain-a>"
import { register<DomainB>Tools } from "./tools/<domain-b>"

const server = new McpServer({
  name: "<server-name>",
  version: "1.0.0",
})

// Register tool groups
register<DomainA>Tools(server)
register<DomainB>Tools(server)

// Start server with stdio transport
const transport = new StdioServerTransport()
await server.connect(transport)
```

### Tool Registration (Modular)

Group tools by domain. Each module exports a registration function:

```typescript
// tools/<domain>.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js"
import { z } from "zod"

export function register<Domain>Tools(server: McpServer) {
  server.tool(
    "<action>_<resource>",
    "<What this tool does — one sentence for model context>",
    {
      <param-a>: z.string().describe("<param description>"),
      <param-b>: z.enum(["<option-a>", "<option-b>"]).optional().default("<option-a>"),
    },
    async ({ <param-a>, <param-b> }) => {
      const result = await <service>(<param-a>, <param-b>)
      return {
        content: [{ type: "text", text: result }],
      }
    }
  )

  server.tool(
    "<action>_<resource>",
    "<Tool description>",
    {
      <param-a>: z.string().describe("<param description>"),
      <param-b>: z.string().describe("<param description>"),
    },
    async ({ <param-a>, <param-b> }) => {
      await <service>(<param-a>, <param-b>)
      return {
        content: [{ type: "text", text: `<Success message>` }],
      }
    }
  )

  server.tool(
    "<action>_<resource>",
    "<Tool description>",
    {
      <param-a>: z.string().optional().default("<default>").describe("<param description>"),
      <param-b>: z.string().optional().describe("<param description>"),
    },
    async ({ <param-a>, <param-b> }) => {
      const results = await <service>(<param-a>, <param-b>)
      return {
        content: [{ type: "text", text: JSON.stringify(results, null, 2) }],
      }
    }
  )
}
```

### Structured JSON Responses

Return structured JSON for programmatic consumption by AI clients:

```typescript
server.tool(
  "<action>_<resource>",
  "<Tool description>",
  {
    query: z.string().describe("<param description>"),
    maxResults: z.number().optional().default(10),
  },
  async ({ query, maxResults }) => {
    const results = await <service>(query, maxResults)

    // Return structured data — AI can parse and reason over it
    return {
      content: [{
        type: "text",
        text: JSON.stringify({
          query,
          totalResults: results.length,
          results: results.map(r => ({
            <field-a>: r.<field-a>,
            <field-b>: r.<field-b>,
            <field-c>: r.<field-c>,
            score: r.score,
          })),
        }, null, 2),
      }],
    }
  }
)
```

### Scope-Based Authorization

Protect tools behind permission scopes when using API key auth:

```typescript
interface ToolContext {
  scopes: string[]
}

function hasScope(context: ToolContext, required: string): boolean {
  return context.scopes.includes(required)
}

export function register<Domain>Tools(server: McpServer, context: ToolContext) {
  server.tool("<action>_<resource>", "<Tool description>", { <param>: z.string() }, async ({ <param> }) => {
    if (!hasScope(context, "<resource>:read")) {
      return {
        content: [{ type: "text", text: JSON.stringify({
          error: { code: "INSUFFICIENT_SCOPE", message: "Requires <resource>:read scope" }
        })}],
        isError: true,
      }
    }
    const result = await <service>(<param>)
    return { content: [{ type: "text", text: result }] }
  })
}
```

### Shared Zod Schemas

Reuse schemas across tools:

```typescript
// schemas/common.ts
import { z } from "zod"

export const <resource>Schema = z.string()
  .describe("<Resource identifier>")

export const paginationSchema = z.object({
  limit: z.number().optional().default(20).describe("Max results"),
  offset: z.number().optional().default(0).describe("Skip N results"),
})

export const searchSchema = z.object({
  query: z.string().min(1).describe("Search query"),
  ...paginationSchema.shape,
})

// Usage in tool:
server.tool("<action>_<resource>", "<Tool description>", searchSchema.shape, async (params) => {
  // params is typed from the schema
})
```

### Error Handling

Return errors as structured JSON with `isError: true`:

```typescript
server.tool("<action>_<resource>", "<Tool description>", { <param>: z.string() }, async ({ <param> }) => {
  try {
    await <service>(<param>)
    return {
      content: [{ type: "text", text: `<Success message>` }],
    }
  } catch (error) {
    const code = error instanceof <CustomError> ? "<DOMAIN_ERROR>" : "INTERNAL_ERROR"
    return {
      content: [{
        type: "text",
        text: JSON.stringify({
          error: { code, message: String(error) },
        }),
      }],
      isError: true,
    }
  }
})
```

### HTTP Transport (Next.js Integration)

Serve MCP over HTTP instead of stdio for web apps:

```typescript
// app/api/mcp/route.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js"
import { createMcpHandler } from "./handler"

const server = new McpServer({ name: "<server-name>", version: "1.0.0" })
registerAllTools(server)

export const POST = createMcpHandler(server)
```

## Conventions

- One registration function per domain (`register<DomainA>Tools`, `register<DomainB>Tools`, etc.)
- Tool names use `snake_case` — this is the MCP convention
- Tool descriptions are clear, single-sentence explanations of what the tool does
- Parameters use Zod with `.describe()` on every field — this is what AI sees
- Return `{ content: [{ type: "text", text: ... }] }` — always text content blocks
- Use `isError: true` for error responses so AI clients know the tool failed
- Return structured JSON (not prose) — AI clients parse this programmatically
- Shared schemas live in `schemas/` — reuse across tools

## Anti-Patterns

- Don't use regex for text editing tools — use exact string match for AI reliability
- Don't return HTML or rich formatting — plain text or JSON only
- Don't create tools with ambiguous names — be specific (`<action>_<resource>` not `get`)
- Don't omit `.describe()` on Zod params — without it, AI has no context for the field
- Don't mix authorization logic into tool implementations — use middleware/context
- Don't create one massive tool with many optional params — split into focused tools

## Docs

- [MCP Specification](https://modelcontextprotocol.io/)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [MCP Tools](https://modelcontextprotocol.io/docs/concepts/tools)
- [MCP Resources](https://modelcontextprotocol.io/docs/concepts/resources)
- [MCP Transports](https://modelcontextprotocol.io/docs/concepts/transports)
