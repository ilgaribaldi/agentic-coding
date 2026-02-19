# Mobile & Desktop Patterns

## Expo & React Native (Mobile)

### Stack

| Technology | Version | Purpose |
|-----------|---------|---------|
| Expo SDK | 55 | Managed native workflow |
| React Native | 0.83 | Core mobile framework |
| Expo Router | Latest | File-based routing |
| React | 19.2 | UI library |
| Reanimated | 4.x | Worklet-based animations |
| Gesture Handler | 2.x | Composable gesture API |
| Bottom Sheet | 5.x | Modal sheets (gorhom) |
| NativeWind | Latest | Tailwind for RN |

### App Structure

```
apps/mobile/
├── app/                    # Expo Router (file-based routing)
│   ├── _layout.tsx         # Root layout (Stack/Tabs)
│   ├── (tabs)/             # Tab group
│   │   ├── _layout.tsx     # Tab navigator
│   │   ├── index.tsx       # Home tab
│   │   └── settings.tsx    # Settings tab
│   ├── (auth)/             # Auth group
│   │   ├── sign-in.tsx
│   │   └── sign-up.tsx
│   ├── [id].tsx            # Dynamic route
│   └── +not-found.tsx      # 404
├── src/
│   ├── components/
│   ├── hooks/
│   └── utils/
├── app.json                # Expo config
├── eas.json                # EAS Build profiles
└── metro.config.js         # Metro bundler config
```

### Expo Router Conventions

```typescript
// app/_layout.tsx — Root layout
import { Stack } from "expo-router"

export default function RootLayout() {
  return (
    <Stack>
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen name="(auth)" options={{ headerShown: false }} />
    </Stack>
  )
}

// app/(tabs)/_layout.tsx — Tab navigator
import { Tabs } from "expo-router"

export default function TabLayout() {
  return (
    <Tabs>
      <Tabs.Screen name="index" options={{ title: "Home", tabBarIcon: HomeIcon }} />
      <Tabs.Screen name="settings" options={{ title: "Settings" }} />
    </Tabs>
  )
}
```

- Every file in `app/` with a default export becomes a route
- `_layout.tsx` defines navigation layouts (Stack, Tabs, Drawer)
- `(group)` directories group routes without affecting the URL
- `[param].tsx` for dynamic segments; `[...rest].tsx` for catch-all

### Metro in Monorepos

```javascript
// metro.config.js
const { getDefaultConfig } = require("expo/metro-config")
const path = require("path")

const projectRoot = __dirname
const monorepoRoot = path.resolve(projectRoot, "../..")

const config = getDefaultConfig(projectRoot)

// Watch all workspace packages
config.watchFolders = [monorepoRoot]

// Resolve from monorepo root node_modules
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, "node_modules"),
  path.resolve(monorepoRoot, "node_modules"),
]

module.exports = config
```

### React Native Component Patterns

```typescript
import { View, Text, StyleSheet, Pressable } from "react-native"

type ItemCardProps = {
  title: string
  onPress?: () => void
}

const ItemCard: React.FC<ItemCardProps> = ({ title, onPress }) => {
  return (
    <Pressable style={styles.card} onPress={onPress}>
      <Text style={styles.title}>{title}</Text>
    </Pressable>
  )
}

const styles = StyleSheet.create({
  card: {
    padding: 16,
    borderRadius: 8,
    backgroundColor: "#fff",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  title: {
    fontSize: 16,
    fontWeight: "600",
  },
})
```

### Animation Patterns (Reanimated)

```typescript
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from "react-native-reanimated"

const AnimatedCard: React.FC = () => {
  const scale = useSharedValue(1)

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }))

  const onPressIn = () => { scale.value = withSpring(0.95) }
  const onPressOut = () => { scale.value = withSpring(1) }

  return (
    <Animated.View style={animatedStyle}>
      <Pressable onPressIn={onPressIn} onPressOut={onPressOut}>
        {/* content */}
      </Pressable>
    </Animated.View>
  )
}
```

- `useSharedValue` for values shared between JS and UI threads
- `useAnimatedStyle` for worklet-based styles (up to 120fps)
- `runOnJS` to call JS from worklets; `runOnUI` for the reverse
- Always clean up animations in `useEffect` return

### Gesture Handler v2

```typescript
import { Gesture, GestureDetector, GestureHandlerRootView } from "react-native-gesture-handler"

// Wrap app root
<GestureHandlerRootView style={{ flex: 1 }}>
  <App />
</GestureHandlerRootView>

// Composable gestures
const pan = Gesture.Pan()
  .onUpdate((e) => { translateX.value = e.translationX })
  .onEnd(() => { translateX.value = withSpring(0) })

const pinch = Gesture.Pinch()
  .onUpdate((e) => { scale.value = e.scale })

const composed = Gesture.Simultaneous(pan, pinch)

<GestureDetector gesture={composed}>
  <Animated.View style={animatedStyle} />
</GestureDetector>
```

### Bottom Sheet (gorhom v5)

```typescript
import BottomSheet, { BottomSheetModal, BottomSheetScrollView } from "@gorhom/bottom-sheet"

const snapPoints = useMemo(() => ["25%", "50%", "90%"], [])

<BottomSheet snapPoints={snapPoints} index={0}>
  <BottomSheetScrollView>
    {/* scrollable content */}
  </BottomSheetScrollView>
</BottomSheet>

// Modal variant
<BottomSheetModal ref={bottomSheetModalRef} snapPoints={snapPoints}>
  {/* content */}
</BottomSheetModal>
```

### EAS Build Configuration

```json
// eas.json
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal",
      "ios": { "simulator": true }
    },
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {
      "ios": { "appleId": "...", "ascAppId": "..." },
      "android": { "serviceAccountKeyPath": "./google-services.json" }
    }
  }
}
```

### SDK 55 Key Notes

- New Architecture is mandatory (Legacy Architecture removed)
- `newArchEnabled` flag no longer needed in app.json
- Hermes is the default JS engine
- Apple Zoom transitions enabled by default in Expo Router
- Import from `expo/metro-config` (not `@expo/metro-config`)

---

## Electron (Desktop)

### Stack

| Technology | Version | Purpose |
|-----------|---------|---------|
| Electron | 35 | Desktop framework |
| Vite | Latest | Build tooling |
| React | 19 | UI library |
| electron-vite | 5.x | Electron + Vite integration |

### App Structure

```
apps/desktop/
├── electron/
│   ├── main.ts              # Main process
│   ├── preload.ts           # Preload script (bridge)
│   └── updater.ts           # Auto-update logic
├── src/                     # Renderer (React app)
│   ├── App.tsx
│   ├── components/
│   └── hooks/
├── electron.vite.config.ts  # Separate configs for main/preload/renderer
├── electron-builder.yml     # Build/package config
└── vite.config.ts
```

### Process Architecture

- **Main process**: Node.js runtime, manages windows, system APIs. One per app.
- **Renderer process**: Chromium web page. One per BrowserWindow. Sandboxed.
- **Preload scripts**: Bridge between main and renderer via `contextBridge`.

### IPC Patterns

```typescript
// preload.ts — Expose safe API to renderer
import { contextBridge, ipcRenderer } from "electron"

contextBridge.exposeInMainWorld("electronAPI", {
  // Renderer → Main (request/reply) — PREFERRED
  invoke: (channel: string, data: unknown) => ipcRenderer.invoke(channel, data),

  // Main → Renderer (one-way)
  onUpdate: (callback: (data: unknown) => void) =>
    ipcRenderer.on("update-available", (_, data) => callback(data)),
})

// main.ts — Handle IPC
import { ipcMain } from "electron"

ipcMain.handle("get-app-version", async () => {
  return app.getVersion()
})

// renderer — Use exposed API
const version = await window.electronAPI.invoke("get-app-version")
```

**IPC patterns ranked by preference:**
1. `ipcRenderer.invoke()` → `ipcMain.handle()` — request/reply with Promise (preferred)
2. `ipcRenderer.send()` → `ipcMain.on()` — one-way, fire-and-forget
3. `mainWindow.webContents.send()` → `ipcRenderer.on()` — main to renderer
4. MessagePorts — renderer to renderer

### Security

```typescript
// BrowserWindow creation
const mainWindow = new BrowserWindow({
  webPreferences: {
    contextIsolation: true,    // Always true (default since Electron 12)
    nodeIntegration: false,    // Never enable in renderer
    sandbox: true,             // Restrict renderer capabilities
    preload: path.join(__dirname, "preload.js"),
  },
})
```

- Never set `nodeIntegration: true` in renderer
- Never expose the entire `ipcRenderer` — only specific methods
- Validate all IPC inputs in the main process
- Set Content Security Policy headers

### React Deduplication (Monorepo)

```typescript
// vite.config.ts
import path from "path"

const rootNodeModules = path.resolve(__dirname, "../../node_modules")

export default defineConfig({
  resolve: {
    alias: {
      react: path.resolve(rootNodeModules, "react"),
      "react-dom": path.resolve(rootNodeModules, "react-dom"),
    },
    dedupe: ["react", "react-dom"],
  },
})
```

### Auto-Update

```typescript
import { autoUpdater } from "electron-updater"

autoUpdater.autoDownload = false

autoUpdater.on("update-available", (info) => {
  mainWindow.webContents.send("update-available", info)
})

autoUpdater.on("update-downloaded", () => {
  autoUpdater.quitAndInstall()
})

// Check on startup
autoUpdater.checkForUpdatesAndNotify()
```

### electron-vite Configuration

```typescript
// electron.vite.config.ts
import { defineConfig } from "electron-vite"

export default defineConfig({
  main: {
    // Main process config
  },
  preload: {
    // Preload script config
  },
  renderer: {
    // Renderer (React) config — full Vite HMR
  },
})
```

- Hot restart for main process changes
- Hot reload for preload script changes
- Full HMR for renderer (React) changes

### Deep Links

```typescript
// main.ts
if (process.defaultApp) {
  if (process.argv.length >= 2) {
    app.setAsDefaultProtocolClient("myapp", process.execPath, [path.resolve(process.argv[1])])
  }
} else {
  app.setAsDefaultProtocolClient("myapp")
}

app.on("open-url", (event, url) => {
  // Handle myapp://path/to/resource
  const parsed = new URL(url)
  // Route to appropriate window/view
})
```

### Electron 35 Notes

- Chromium 134, Node.js 22.14, V8 13.5
- `session.setPreloads()` deprecated → use `registerPreloadScript()`
- Windows rounded corners supported on BrowserWindow
- ServiceWorker preload scripts now available

## Docs

- [Expo Docs](https://docs.expo.dev/)
- [Expo Router](https://docs.expo.dev/router/introduction/)
- [Expo Monorepo Guide](https://docs.expo.dev/guides/monorepos/)
- [EAS Build](https://docs.expo.dev/build/introduction/)
- [React Native](https://reactnative.dev/)
- [Reanimated](https://docs.swmansion.com/react-native-reanimated/)
- [Gesture Handler](https://docs.swmansion.com/react-native-gesture-handler/docs/)
- [Bottom Sheet](https://gorhom.dev/react-native-bottom-sheet/)
- [Electron Docs](https://www.electronjs.org/docs/latest/)
- [Electron IPC](https://www.electronjs.org/docs/latest/tutorial/ipc)
- [Electron Security](https://www.electronjs.org/docs/latest/tutorial/security)
- [electron-vite](https://electron-vite.org/)
- [electron-builder](https://www.electron.build/)
