# Testing Patterns

## Stack Choices

| Technology | Version | Purpose |
|-----------|---------|---------|
| Vitest | 3.x+ | Unit & integration tests (Vite-native) |
| Playwright | 1.50+ | E2E browser testing |
| @testing-library/react | 16.x | Component testing |
| @testing-library/jest-dom | 6.x | Custom DOM matchers |
| jsdom | Latest | DOM environment for unit tests |

## Project Structure

```
src/
├── __tests__/                    # Unit & integration tests
│   ├── setup.ts                  # Global mocks & test setup
│   ├── api/                      # API route handler tests
│   │   └── <resource>.test.ts
│   ├── components/               # React component tests
│   │   └── <component>.test.tsx
│   ├── hooks/                    # Custom hook tests
│   │   └── <hook>.test.ts
│   └── lib/                      # Utility function tests
│       └── <util>.test.ts
├── e2e/                          # Playwright E2E tests
│   ├── <feature>.spec.ts                  # Unauthenticated flows
│   └── <feature>.authenticated.spec.ts    # Auth-required flows
└── ...
```

## Core Patterns

### Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config"
import react from "@vitejs/plugin-react"
import path from "path"

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    setupFiles: ["./src/__tests__/setup.ts"],
    globals: true,
    css: false,                   // Skip CSS processing
    include: ["src/**/*.test.{ts,tsx}"],
    exclude: ["node_modules", "e2e"],
    coverage: {
      provider: "v8",
      include: ["src/**/*.{ts,tsx}"],
      exclude: ["src/**/*.test.*", "src/__tests__/**"],
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
```

### Global Test Setup (Mocks)

Mock external services once in setup file — all tests inherit:

```typescript
// __tests__/setup.ts
import "@testing-library/jest-dom/vitest"
import { vi } from "vitest"

// Mock auth provider (e.g., Clerk, NextAuth, etc.)
vi.mock("<auth-provider-server-import>", () => ({
  getAuth: vi.fn(() => ({ userId: "test-user-id", orgId: "test-org-id" })),
  <authMiddleware>: vi.fn(() => async (_c: unknown, next: () => Promise<void>) => next()),
}))

vi.mock("<auth-provider-api-import>", () => ({
  <authMiddleware>: vi.fn(() => async (_c: unknown, next: () => Promise<void>) => next()),
  getAuth: vi.fn(() => ({ userId: "test-user-id", orgId: "test-org-id" })),
}))

// Mock Next.js router
vi.mock("next/navigation", () => ({
  useRouter: vi.fn(() => ({
    push: vi.fn(),
    replace: vi.fn(),
    back: vi.fn(),
    refresh: vi.fn(),
  })),
  usePathname: vi.fn(() => "/"),
  useSearchParams: vi.fn(() => new URLSearchParams()),
}))

// Mock fetch globally
global.fetch = vi.fn()
```

### API Route Testing (Hono)

Test route handlers directly via `app.request()`:

```typescript
import { describe, it, expect, vi, beforeEach } from "vitest"
import { Hono } from "hono"
import <resource>Routes from "@/app/api/<resource>/<resource>"

// Mock database
vi.mock("@/db/drizzle", () => ({
  db: {
    select: vi.fn().mockReturnThis(),
    from: vi.fn().mockReturnThis(),
    where: vi.fn().mockReturnThis(),
    insert: vi.fn().mockReturnThis(),
    values: vi.fn().mockReturnThis(),
    returning: vi.fn(),
  },
}))

describe("<Resource> API", () => {
  let app: Hono

  beforeEach(() => {
    app = new Hono()
    app.route("/<resource>", <resource>Routes)
    vi.clearAllMocks()
  })

  it("GET /<resource> returns 200 with data", async () => {
    const { db } = await import("@/db/drizzle")
    vi.mocked(db.select().from().where).mockResolvedValue([
      { id: "1", name: "<value>" },
    ])

    const res = await app.request("/<resource>")
    expect(res.status).toBe(200)

    const body = await res.json()
    expect(body.data).toHaveLength(1)
  })

  it("POST /<resource> validates request body", async () => {
    const res = await app.request("/<resource>", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "" }), // Invalid: empty
    })
    expect(res.status).toBe(400)
  })
})
```

### React Component Testing

```typescript
import { describe, it, expect } from "vitest"
import { render, screen, fireEvent } from "@testing-library/react"
import { <Component> } from "@/components/<component>"

describe("<Component>", () => {
  const defaultProps = {
    id: "1",
    name: "<value>",
    onAction: vi.fn(),
  }

  it("renders content", () => {
    render(<<Component> {...defaultProps} />)
    expect(screen.getByText("<value>")).toBeInTheDocument()
  })

  it("calls handler on interaction", () => {
    render(<<Component> {...defaultProps} />)
    fireEvent.click(screen.getByRole("button", { name: /<action>/i }))
    expect(defaultProps.onAction).toHaveBeenCalledWith("1")
  })
})
```

### Custom Hook Testing

```typescript
import { describe, it, expect } from "vitest"
import { renderHook, act } from "@testing-library/react"
import { <useHook> } from "@/hooks/<use-hook>"

describe("<useHook>", () => {
  it("returns expected state", () => {
    const { result } = renderHook(() => <useHook>(<initial-value>))
    expect(result.current[0]).toBe(<initial-value>)

    act(() => result.current[1]())
    expect(result.current[0]).toBe(<updated-value>)
  })
})
```

### Playwright Configuration

```typescript
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test"

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [["html", { open: "never" }]],
  use: {
    baseURL: "http://localhost:<port>",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
  webServer: {
    command: "<dev-command>",
    port: <port>,
    reuseExistingServer: !process.env.CI,
  },
})
```

### E2E Test (Unauthenticated)

```typescript
import { test, expect } from "@playwright/test"

test.describe("<Feature>", () => {
  test("shows <element> on <page>", async ({ page }) => {
    await page.goto("/<path>")
    await expect(page.getByRole("link", { name: /<text>/i })).toBeVisible()
  })

  test("redirects unauthenticated users from <protected-route>", async ({ page }) => {
    await page.goto("/<protected-route>")
    await expect(page).toHaveURL(/<auth-route>/)
  })
})
```

### E2E Test (Authenticated)

Use `storageState` to persist auth across tests:

```typescript
import { test as setup, expect } from "@playwright/test"

// Auth setup fixture — runs once, saves session
setup("authenticate", async ({ page }) => {
  await page.goto("/<sign-in-path>")
  await page.getByLabel("Email").fill(process.env.E2E_TEST_USER_EMAIL!)
  await page.getByRole("button", { name: /<submit>/i }).click()
  await page.getByLabel("Password").fill(process.env.E2E_TEST_USER_PASSWORD!)
  await page.getByRole("button", { name: /<submit>/i }).click()

  await page.waitForURL("/<authenticated-route>")
  await page.context().storageState({ path: ".auth/user.json" })
})

// Authenticated tests reuse session
import { test, expect } from "@playwright/test"
test.use({ storageState: ".auth/user.json" })

test("can <action>", async ({ page }) => {
  await page.goto("/<authenticated-route>")
  await page.getByRole("button", { name: /<action>/i }).click()
  await page.getByLabel("<field>").fill("<value>")
  await page.getByRole("button", { name: /<submit>/i }).click()
  await expect(page.getByText("<expected-result>")).toBeVisible()
})
```

## Conventions

- Test files mirror source structure: `src/lib/<util>.ts` → `src/__tests__/lib/<util>.test.ts`
- E2E files use `.spec.ts` extension; unit tests use `.test.ts`
- Authenticated E2E tests use `.authenticated.spec.ts` suffix
- One `setup.ts` for all global mocks — avoid scattered mock files
- Use `vi.mock()` at module level, `vi.fn()` for individual spies
- Clear mocks in `beforeEach` to prevent test pollution

## Anti-Patterns

- Don't import the real database in unit tests — always mock `db`
- Don't test implementation details — test behavior and outputs
- Don't share mutable state between tests without cleanup
- Don't use `setTimeout`/delays in E2E tests — use Playwright's built-in waiting (`waitForURL`, `expect().toBeVisible()`)
- Don't run E2E tests against production — always use a local or staging server
- Don't skip `vi.clearAllMocks()` in `beforeEach` — stale mock state causes flaky tests

## Docs

- [Vitest](https://vitest.dev/)
- [Vitest Configuration](https://vitest.dev/config/)
- [Vitest Mocking](https://vitest.dev/guide/mocking)
- [Playwright](https://playwright.dev/docs/intro)
- [Playwright Test Generator](https://playwright.dev/docs/codegen)
- [Playwright Authentication](https://playwright.dev/docs/auth)
- [Testing Library](https://testing-library.com/docs/react-testing-library/intro/)
- [jest-dom Matchers](https://github.com/testing-library/jest-dom)
