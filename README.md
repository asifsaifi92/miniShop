# MiniShop 🛍️

A mini e-commerce Android app built with Flutter demonstrating a complete end-to-end shopping flow: catalog → detail → cart → checkout.

---

## Screenshots

| Home / Catalog | Product Detail | Cart | Checkout | Order Success |
|---|---|---|---|---|
| Category chips, deals strip, grid | Image gallery, rating, add-to-cart | Qty controls, totals, persist | Form validation, summary | Order ID, delivery info |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3.10+) |
| State Management | Provider (`ChangeNotifier`) |
| Networking | `http` package (background isolate) |
| Image Caching | `cached_network_image` |
| Local Persistence | `shared_preferences` (cart + wishlist) |
| Skeleton Loading | `shimmer` |
| Ratings UI | `flutter_rating_bar` |
| Connectivity | `connectivity_plus` |
| Data Source | [DummyJSON](https://dummyjson.com) public API |

---

## Architecture

```
lib/
├── main.dart                  # App entry, MultiProvider setup
├── models/
│   ├── product.dart           # Product data class + fromJson
│   ├── cart_item.dart         # CartItem (product + quantity)
│   └── order.dart             # Placed order model
├── services/
│   └── api_service.dart       # HTTP client (DummyJSON), error handling
├── providers/
│   ├── products_provider.dart # Catalog, search, categories, sort, pagination
│   ├── cart_provider.dart     # Cart CRUD + SharedPreferences persistence
│   ├── wishlist_provider.dart # Wishlist toggle + SharedPreferences persistence
│   └── orders_provider.dart  # In-memory order history
├── screens/
│   ├── home_screen.dart       # Product grid, search, category chips, deals strip
│   ├── product_detail_screen.dart # Image gallery, rating, add-to-cart
│   ├── cart_screen.dart       # Cart list, qty controls, checkout CTA
│   ├── checkout_screen.dart   # Order form, validation, place order
│   ├── order_success_screen.dart # Confirmation with order details
│   ├── wishlist_screen.dart   # Saved products grid
│   └── orders_screen.dart     # Order history with expandable cards
├── widgets/
│   ├── product_card.dart      # Grid card with discount badge, wishlist toggle
│   ├── skeleton_loader.dart   # Shimmer skeleton for loading state
│   ├── error_view.dart        # Error + retry UI / empty state UI
│   ├── connectivity_banner.dart # Animated offline banner
│   ├── deals_section.dart     # Horizontal hot-deals strip (≥15% off)
│   └── sort_bottom_sheet.dart # Sort options bottom sheet
└── theme/
    └── app_theme.dart         # Material 3 theme (colors, shapes)
```

**State flow:** All screens read from `Provider` — no setState for business logic. Cart and wishlist are persisted to `SharedPreferences` on every mutation and rehydrated on app start, so they survive restarts.

---

## API Used

**DummyJSON** — `https://dummyjson.com`

| Endpoint | Used for |
|---|---|
| `GET /products?limit=30&skip=N` | Paginated product catalog |
| `GET /products/categories` | Category chip list |
| `GET /products/category/:slug` | Filter by category |
| `GET /products/search?q=:query` | Full-text product search |
| `GET /products/:id` | Single product (if needed) |

Returns 194 products across 30+ categories. The app fetches 30 at a time and loads more as the user scrolls (infinite scroll).

---

## Features

### MVP (Must-Have)
- [x] Product catalog — grid of 30+ products loaded from API
- [x] Product detail — image gallery, rating, discounted price, stock level
- [x] Add to Cart / quantity controls on detail and in cart
- [x] Cart screen — per-item totals, cart total, quantity +/−, remove
- [x] Cart persisted across app restarts (SharedPreferences)
- [x] Checkout — name/address/phone form with validation, order summary
- [x] Order placed confirmation screen
- [x] Loading skeleton UI and error state with retry button
- [x] Empty state views
- [x] Graceful offline error handling

### Bonus / Nice-to-Have
- [x] Category filter chips (30+ categories from API)
- [x] Full-text search with 500ms debounce (live-as-you-type)
- [x] Sort by: Default / Price Low→High / Price High→Low / Top Rated
- [x] Hot Deals strip (products with ≥15% discount, sorted by discount %)
- [x] Wishlist — heart toggle on every card, persisted offline
- [x] Order history — expandable cards with all order details
- [x] Ratings UI (star bar + numeric score)
- [x] Connectivity banner — animated "No internet" bar appears/disappears live
- [x] Infinite scroll pagination

---

## Setup & Running

### Prerequisites
- Flutter SDK ≥ 3.10 — [Install Flutter](https://docs.flutter.dev/get-started/install)
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device (Android 5.0+ / minSdk 21)

### Steps

```bash
# 1. Clone the repository
git clone <repo-url>
cd minishop

# 2. Install dependencies
flutter pub get

# 3. Run on connected device / emulator
flutter run

# 4. Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

The app will work immediately — no API keys, no environment variables needed.

---

## Limitations

- **Order history is in-memory only** — orders do not survive app restarts (no backend). A real app would persist to SQLite or sync to a server.
- **No real payment** — checkout is a demo form; no payment gateway is integrated.
- **No user authentication** — the delivery form is filled fresh each time.
- **Image quality** — images are served by DummyJSON; some are low-resolution stock photos.
- **Search is server-side** — the DummyJSON `/search` endpoint is used, so search results depend on their index. Offline search is not available.

---

## Trade-offs & Future Scope

| Decision | Rationale |
|---|---|
| Provider over Bloc/Riverpod | Simpler setup for a demo; easy to swap — providers are already isolated behind interfaces |
| DummyJSON over own backend | Zero setup time; 194 real products with images, ratings, discounts |
| SharedPreferences for cart | Sufficient for key-value persistence; for larger carts, SQLite/Isar would be better |
| HTTP package over Dio | No interceptors or complex retry logic needed; keeps dependencies minimal |

**Future scope:** authentication + saved addresses, SQLite order history, push notifications for order status, product reviews, deep links, dark mode.

---

## Permissions

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

No location, contacts, storage, or camera permissions are requested.
