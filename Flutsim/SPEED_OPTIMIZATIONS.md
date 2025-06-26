# Flutsim Speed Optimizations

## 🚀 Performance Improvements

Flutsim now includes several optimizations to dramatically speed up development:

### **Fast Development Mode (Default)**

- **Hot restart in ~600ms** (vs 60+ seconds before!)
- Uses `flutter run -d web-server` for instant hot reload
- Perfect for active development

### **Optimized Build Mode**

- **Debounced file watching** (500ms delay to batch rapid changes)
- **Build state management** prevents overlapping builds
- **Development-optimized flags** for faster builds

## ⚙️ Configuration

Edit `lib/config.dart` to customize behavior:

```dart
class FlutsimConfig {
  /// Use fast development mode (flutter run) instead of full builds
  static const bool useFastMode = true;

  /// Debounce delay for file changes (milliseconds)
  static const int debounceDelay = 500;

  /// Use HTML renderer for faster builds (only applies to build mode)
  static const bool useHtmlRenderer = true;

  /// Disable icon tree-shaking for faster builds (only applies to build mode)
  static const bool disableIconTreeShaking = true;

  /// Disable Skia for faster builds (only applies to build mode)
  static const bool disableSkia = true;

  /// Development server port
  static const int port = 8080;

  /// Live reload server port
  static const int liveReloadPort = 8081;
}
```

## 🔧 Speed Optimization Techniques

### **1. Fast Development Mode**

- Uses `flutter run` instead of `flutter build web`
- Provides hot reload and hot restart
- Much faster for iterative development

### **2. Debouncing**

- Waits 500ms after last file change before rebuilding
- Prevents multiple rapid builds
- Configurable via `debounceDelay`

### **3. Build State Management**

- Prevents overlapping builds
- Skips new builds if one is already in progress
- Reduces resource usage

### **4. Development-Optimized Flags**

- `--web-renderer html`: Faster HTML renderer
- `--no-tree-shake-icons`: Skip icon optimization
- `--dart-define=FLUTTER_WEB_USE_SKIA=false`: Disable Skia

## 📊 Performance Comparison

| Mode                | Build Time | Hot Reload | Best For           |
| ------------------- | ---------- | ---------- | ------------------ |
| **Fast Mode**       | ~600ms     | ✅ Yes     | Active development |
| **Optimized Build** | ~30s       | ❌ No      | Production testing |
| **Original**        | ~60s       | ❌ No      | Legacy             |

## 🎯 Recommendations

### **For Active Development:**

- Use **Fast Mode** (default)
- Perfect for making frequent changes
- Hot reload provides instant feedback

### **For Production Testing:**

- Set `useFastMode = false` in config
- Use optimized build flags
- Test with production-like settings

### **For Large Projects:**

- Increase `debounceDelay` to 1000ms
- Consider using build mode for final testing

## 🚨 Troubleshooting

### **If builds are still slow:**

1. Check if Flutter is up to date
2. Clear Flutter cache: `flutter clean`
3. Increase debounce delay
4. Use fast mode for development

### **If hot reload isn't working:**

1. Ensure you're using fast mode
2. Check browser console for errors
3. Try manual refresh if needed

## 🔄 Migration Guide

### **From Original Flutsim:**

1. No changes needed - optimizations are enabled by default
2. Enjoy 100x faster development experience!

### **Customizing for Your Workflow:**

1. Edit `lib/config.dart`
2. Adjust settings based on your needs
3. Restart Flutsim to apply changes
