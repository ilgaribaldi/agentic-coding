# Shadcn/UI Patterns

## Component Organization

Components live in `packages/ui/src/components/` and are imported via subpath:

```typescript
import { Button } from "@scope/ui/button"
import { cn } from "@scope/ui/lib/utils"
```

## Component Pattern (CVA Variants)

```typescript
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "../lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-lg text-sm font-medium transition-colors",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground shadow-sm",
        destructive: "bg-destructive text-destructive-foreground",
        outline: "border border-input bg-background",
        secondary: "bg-secondary text-secondary-foreground",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-lg px-3 text-xs",
        lg: "h-10 rounded-lg px-8",
        icon: "h-9 w-9",
      },
    },
    defaultVariants: { variant: "default", size: "default" },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return <Comp className={cn(buttonVariants({ variant, size, className }))} ref={ref} {...props} />
  }
)
```

## Theming (CSS Variables)

Dark mode via `next-themes` with `.dark` class on `<html>`.

```css
:root {
  --background: 0 0% 100%;
  --foreground: 240 10% 3.9%;
  --primary: 240 5.9% 10%;
  --primary-foreground: 0 0% 98%;
  --muted: 240 4.8% 95.9%;
  --border: 240 5.9% 90%;
}

.dark {
  --background: 240 10% 3.9%;
  --foreground: 0 0% 98%;
  --primary: 0 0% 98%;
  --primary-foreground: 240 5.9% 10%;
}
```

Components use semantic tokens: `bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`.

## Tailwind Preset

Shared preset in `packages/config/tailwind/preset.js`:

```javascript
module.exports = {
  darkMode: ["class"],
  theme: {
    extend: {
      fontFamily: { sans: ["Roboto"], heading: ["Poppins"], mono: ["Outfit"] },
      keyframes: { "accordion-down": {}, "aurora": {}, "grid": {} },
      animation: { "accordion-down": "accordion-down 0.2s ease-out" },
    },
  },
  plugins: [require("tailwindcss-animate"), require("@tailwindcss/typography")],
}
```

Apps extend: `presets: [require("@scope/config/tailwind")]`

Content paths include packages: `"../../packages/ui/src/**/*.{ts,tsx}"`

## Chart Component (Recharts Wrapper)

```typescript
// ChartContainer wraps Recharts with theme integration
<ChartContainer config={chartConfig}>
  <ComposedChart data={data}>
    <ChartTooltip content={<ChartTooltipContent />} />
    <Area dataKey="range" />
    <Line dataKey="value" />
  </ComposedChart>
</ChartContainer>

// Chart config maps data keys to labels/colors
const chartConfig: ChartConfig = {
  temperature: { label: "Temperature", color: "hsl(var(--chart-1))" },
  precipitation: { label: "Precipitation", color: "hsl(var(--chart-2))" },
}
```

## Form Components

Shadcn Form wraps react-hook-form:

```typescript
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@scope/ui/form"

<Form {...form}>
  <FormField control={form.control} name="email"
    render={({ field }) => (
      <FormItem>
        <FormLabel>Email</FormLabel>
        <FormControl><Input {...field} /></FormControl>
        <FormMessage />
      </FormItem>
    )}
  />
</Form>
```

## CLI Commands

```bash
npx shadcn@latest init           # Initialize
npx shadcn@latest add button     # Add component
npx shadcn@latest add --all      # Add all
```

## Docs

- [Shadcn/UI](https://ui.shadcn.com/docs)
- [Theming](https://ui.shadcn.com/docs/theming)
- [Dark Mode](https://ui.shadcn.com/docs/dark-mode/next)
- [Data Table](https://ui.shadcn.com/docs/components/radix/data-table)
- [Forms](https://ui.shadcn.com/docs/forms/react-hook-form)
- [Chart](https://ui.shadcn.com/docs/components/radix/chart)
- [Monorepo Setup](https://ui.shadcn.com/docs/monorepo)
