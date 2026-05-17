# MiniShop — Flutter E-Commerce App

> A fully functional Android e-commerce app built with Flutter, following **MVP architecture**, **Material Design 3**, and production-level engineering practices.

---

## Table of Contents

- [Overview](#overview)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Unit Tests](#unit-tests)
- [Setup & Running](#setup--running)
- [API Reference](#api-reference)
- [Design Decisions & Trade-offs](#design-decisions--trade-offs)

---

## Overview

MiniShop is a complete end-to-end shopping app that covers every screen a real e-commerce product would need:

**Catalog → Search / Filter → Product Detail → Cart → Checkout → Order Confirmation → Order History → Wishlist**

Built as a Maruti Suzuki interview assignment. The goal was to demonstrate clean architecture, thoughtful UI/UX, robust state management, and solid engineering practices — not just make something that works.

### Key Engineering Highlights

- **Strict MVP separation** — Views contain zero business logic; all state lives in Presenters behind abstract interfaces
- **Interface-driven design** — Every presenter implements a contract (`IXxxPresenter`), making the codebase fully testable and presenter-swappable without touching any screen
- **Persistent state** — Cart, wishlist, and orders all survive app restarts via JSON serialisation to `SharedPreferences`
- **61 passing unit tests** — Presenters, models, and service layer fully covered using a `FakeRepository` (no real HTTP calls)
- **Performance-conscious UI** — `RepaintBoundary`, `Selector<T,S>` for scoped rebuilds, `cacheExtent`, `ValueKey`, and staggered entrance animations

---

## Screenshots

### Home Screen
Browse 194 products in a two-column grid with infinite scroll. The **Hot Deals** strip highlights the biggest discounts. **Category chips** and a live **search bar** (500 ms debounce) filter the catalog without leaving the screen.

<p>
  <img src="screenshots/home_screen.jpg" width="260" alt="Home Screen" />
  &nbsp;&nbsp;
  <img src="screenshots/home_sort.jpg" width="260" alt="Sort Bottom Sheet" />
</p>

---

### Product Detail
Hero transition from the grid card. Full **image gallery** with a tappable thumbnail strip, **star rating**, discount badge, stock level, brand info, and a lazy-loaded **"You May Also Like"** carousel (shimmer skeleton while loading).

<p>
  <img src="screenshots/product_detail.jpg" width="260" alt="Product Detail" />
</p>

---

### Cart
Per-item **quantity stepper**, line totals, cart grand total, and a single-tap checkout CTA. The bottom bar adapts on the detail screen — quantity controls appear once a product is added. Cart is **persisted** and rehydrated on every launch.

<p>
  <img src="screenshots/cart_screen.jpg" width="260" alt="Cart Screen" />
</p>

---

### Checkout
Itemised **order summary** at the top. Delivery form with full validation (required fields + phone number regex). An 800 ms loading indicator simulates server processing. On success the cart is cleared and the user is taken to the confirmation screen.

<p>
  <img src="screenshots/checkout_screen.jpg" width="260" alt="Checkout Screen" />
</p>

---

### Order Confirmation
Unique order ID (`ORD-<timestamp>`), personalised greeting, item count, total, and delivery address. The "Continue Shopping" button pops all the way back to the home screen.

<p>
  <img src="screenshots/order_success.jpg" width="260" alt="Order Placed" />
</p>

---

### Order History
Every past order in a scrollable list, **newest first**. Each card expands to reveal item lines, quantities, line totals, and full delivery details. Persisted across sessions.

<p>
  <img src="screenshots/orders_screen.jpg" width="260" alt="My Orders" />
</p>

---

### Wishlist
Heart icon on every product card (home, detail, wishlist grid) toggles the wishlist. The grid is **rehydrated from disk** on the next launch so saved items are never lost.

<p>
  <img src="screenshots/wishlist_screen.jpg" width="260" alt="Wishlist" />
</p>

---

## Architecture

### Pattern: MVP (Model – View – Presenter)

```
┌──────────────────────────────────────────────────────────┐
│                         VIEW                             │
│  (Screens & Widgets — zero business logic, only UI)      │
│  Reads state via Provider.watch / Selector               │
│  Calls actions via Provider.read → presenter method      │
└──────────────────┬───────────────────────────────────────┘
                   │  implements
┌──────────────────▼───────────────────────────────────────┐
│               CONTRACTS  (interfaces)                    │
│  IProductsPresenter  ICartPresenter                      │
│  IWishlistPresenter  IOrdersPresenter                    │
└──────────────────┬───────────────────────────────────────┘
                   │  concrete implementation
┌──────────────────▼───────────────────────────────────────┐
│                    PRESENTER                             │
│  Extends ChangeNotifier — owns all state & business logic│
│  Calls repository for data, mutates state, notifies UI   │
└──────────────────┬───────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────┐
│                  REPOSITORY                              │
│  ProductRepository — thin adapter over ApiService        │
│  Injected via constructor → swapped with FakeRepository  │
│  in tests without touching any presenter or screen code  │
└──────────────────┬───────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────┐
│               SERVICE / DATA SOURCES                     │
│  ApiService — HTTP client, typed ApiException            │
│  SharedPreferences — JSON persistence (cart/wish/orders) │
└──────────────────────────────────────────────────────────┘
```

### Why MVP over BLoC or Riverpod?

- **Simplicity for a demo scope** — `ChangeNotifier` is part of Flutter's core; no extra mental model needed
- **Fully testable** — every presenter is tested against its interface via a `FakeRepository`; no HTTP, no disk I/O
- **Swap-friendly** — the View only knows the `IXxxPresenter` contract; swapping to BLoC means touching only the presenter files

### State Flow

```
User action (e.g. "Add to Cart")
  → View calls  context.read<CartPresenter>().addProduct(p)
  → Presenter   updates _items map, calls _persist(), notifyListeners()
  → Provider    rebuilds only the Selector<CartPresenter, bool> widgets
                that subscribed to this product's cart state
  → SharedPrefs updated asynchronously in the background
```

---

## Features

### Core (Required)
- [x] Product catalog — paginated grid (30 items/page, infinite scroll)
- [x] Product detail — image gallery, star rating, discount price, stock indicator
- [x] Add to Cart with quantity controls on both detail and cart screens
- [x] Cart — quantity +/−, remove item, clear all, grand total
- [x] Cart persisted to SharedPreferences — survives app restarts
- [x] Checkout — name / address / phone form with full validation
- [x] Order placed confirmation with unique order ID
- [x] Loading skeleton (shimmer) and error state with retry button
- [x] Empty state views on all list screens

### Bonus
- [x] Category filter chips — 30+ categories fetched from the API
- [x] Full-text search with 500 ms debounce (live as you type)
- [x] Sort by: Default / Price Low→High / Price High→Low / Top Rated
- [x] Hot Deals strip — products with ≥ 15% discount, sorted by discount %
- [x] Wishlist — heart toggle on every card, persisted offline
- [x] Order history — expandable cards with full item breakdown
- [x] Similar products carousel (lazy-loaded, shimmer while pending)
- [x] Connectivity banner — animated slide-in "No internet" bar
- [x] Hero shared-element transition: grid card → product detail image
- [x] Staggered entrance animation for product cards on first load
- [x] Animated cart badge counter with scale transition

---

## Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Framework | Flutter 3.x / Dart 3.10+ | Cross-platform, fast, Material 3 support |
| Architecture | MVP + Repository pattern | Clean separation, testable, interface-driven |
| State Management | Provider (`ChangeNotifier`) | Built-in, simple, sufficient for this scope |
| Networking | `http` | Lightweight; no interceptors needed |
| Image Caching | `cached_network_image` | Disk + memory cache, shimmer placeholder |
| Persistence | `shared_preferences` | Key-value JSON; suitable for cart/wishlist size |
| Skeleton Loading | `shimmer` | Smooth perceived-performance during loads |
| Ratings UI | `flutter_rating_bar` | Pixel-perfect star display |
| Connectivity | `connectivity_plus` | Real-time network state stream |
| Data Source | DummyJSON REST API | 194 products, no auth, no cost |

---

## Project Structure

```
lib/
├── main.dart                        # App entry — MultiProvider with all 4 presenters
│
├── models/                          # Pure data classes, zero Flutter dependencies
│   ├── product.dart                 # fromJson / toJson (round-trips via SharedPrefs)
│   ├── cart_item.dart               # copyWith pattern for immutable mutation
│   └── order.dart                   # ISO-8601 date serialisation
│
├── contracts/                       # Abstract interfaces — View depends on these, not concretes
│   ├── products_contract.dart       # IProductsPresenter + LoadState + SortOption enums
│   ├── cart_contract.dart           # ICartPresenter
│   ├── wishlist_contract.dart       # IWishlistPresenter
│   └── orders_contract.dart         # IOrdersPresenter
│
├── repositories/                    # Data-access adapters (injectable in tests)
│   └── product_repository.dart      # Wraps ApiService — swap with FakeRepository in tests
│
├── services/
│   └── api_service.dart             # HTTP client — all errors normalised to ApiException
│
├── presenters/                      # Business logic — implement contracts, extend ChangeNotifier
│   ├── products_presenter.dart      # Catalog, pagination, search, category, sort, deals cache
│   ├── cart_presenter.dart          # Cart CRUD + O(1) map lookup + SharedPrefs persistence
│   ├── wishlist_presenter.dart      # Toggle logic + persistence
│   └── orders_presenter.dart        # Order creation + reverse-chronological list + persistence
│
├── screens/                         # Views — read presenters, no business logic
│   ├── splash_screen.dart           # Animated logo → HomeScreen after 2.6 s
│   ├── home_screen.dart             # CustomScrollView with SliverAppBar + SliverGrid
│   ├── product_detail_screen.dart   # Hero image, gallery, similar products FutureBuilder
│   ├── cart_screen.dart             # ListView with ValueKey + bottom summary bar
│   ├── checkout_screen.dart         # Form validation + simulated processing delay
│   ├── order_success_screen.dart    # Confirmation card + popUntil(isFirst)
│   ├── wishlist_screen.dart         # GridView reusing ProductCard
│   └── orders_screen.dart           # ExpansionTile order cards
│
├── widgets/                         # Reusable, stateless/stateful UI components
│   ├── product_card.dart            # RepaintBoundary + Selector for scoped rebuilds
│   ├── deals_section.dart           # Horizontal scroll strip
│   ├── skeleton_loader.dart         # Shimmer card matching ProductCard layout
│   ├── error_view.dart              # ErrorView + EmptyView
│   ├── connectivity_banner.dart     # SizeTransition animated offline banner
│   └── sort_bottom_sheet.dart       # ChangeNotifierProvider.value re-injection
│
└── theme/
    └── app_theme.dart               # Centralised Material 3 theme — colours, shapes, transitions
```

---

## Unit Tests

**61 tests — all passing.** No real network calls or disk I/O in any test.

```bash
flutter test
```

```
test/
├── models/
│   ├── product_test.dart          # fromJson, discountedPrice, hasDiscount
│   └── cart_item_test.dart        # total computation, copyWith immutability
├── presenters/
│   ├── products_presenter_test.dart  # init, error state, deals caching, sort, search, category
│   ├── cart_presenter_test.dart      # add/remove/increment/decrement/total/clear/notify
│   ├── wishlist_presenter_test.dart  # toggle/contains/notify
│   └── orders_presenter_test.dart   # placeOrder, ordering, persistence round-trip
├── services/
│   └── api_exception_test.dart    # message, catchability
└── widget_test.dart               # Smoke test — app boots without errors
```

**Test strategy:** `ProductsPresenter` is injected with a `_FakeRepository` that returns canned data or throws on demand — no mocking framework needed. `CartPresenter` and `WishlistPresenter` use `SharedPreferences.setMockInitialValues({})` to isolate disk I/O.

---

## Setup & Running

### Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | ≥ 3.10 |
| Dart | ≥ 3.0 |
| Android Studio / VS Code | Latest |
| Android device / emulator | API 21+ (Android 5.0) |

### Steps

```bash
# 1. Clone
git clone https://github.com/asifsaifi92/miniShop.git
cd miniShop

# 2. Install dependencies
flutter pub get

# 3. Run on connected device or emulator
flutter run

# 4. Run all unit tests
flutter test

# 5. Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> No API keys, `.env` files, or backend setup required. The app works out of the box.

---

## API Reference

**Base URL:** `https://dummyjson.com`

| Method | Endpoint | Used For |
|---|---|---|
| GET | `/products?limit=30&skip=N` | Paginated catalog (infinite scroll) |
| GET | `/products/categories` | Category chip list |
| GET | `/products/category/:slug` | Category filter |
| GET | `/products/search?q=:query` | Full-text product search |

All responses are normalised through `ApiService._fetchProducts()`. Every error path (socket, timeout, HTTP 4xx/5xx) throws a typed `ApiException` so presenters handle one error type instead of multiple exception classes.

---

## Design Decisions & Trade-offs

| Decision | What was chosen | Why | What I'd change at scale |
|---|---|---|---|
| State management | Provider + `ChangeNotifier` | Simplest setup; presenters behind interfaces are already swap-ready | Riverpod for auto-disposal and compile-safe reading |
| Persistence | `SharedPreferences` (JSON) | Zero boilerplate for key-value data | SQLite / Isar for relational order history and offline catalog |
| Networking | `http` package | No interceptors or retry logic needed for a demo | Dio for interceptors, auth token refresh, and retry strategies |
| Pagination | Offset-based (`skip`) | DummyJSON only supports offset; simple to implement | Cursor-based for stable results when items are inserted/deleted |
| Search | Server-side (DummyJSON `/search`) | Avoids downloading the entire catalog upfront | Algolia or local Fts5 SQLite index for instant offline search |
| Image caching | `cached_network_image` | Handles disk+memory cache automatically | Pre-warm cache on home screen using `precacheImage` |
| Deals list | Cached in `_deals` field | Avoids O(n) filter+sort on every widget rebuild | No change needed at this scale |

### Performance choices worth noting

- **`RepaintBoundary`** wraps every `ProductCard` — Flutter can skip repainting the card raster when unrelated state above it changes
- **`Selector<T,S>`** replaces `Consumer` wherever possible — only the specific field (e.g. `cart.contains(id)`) triggers a rebuild, not the entire cart state
- **`ValueKey(product.id)`** on grid items — Flutter matches existing elements by key on refresh, preventing unnecessary widget disposal and recreation
- **`Future.microtask()`** in presenter constructors — defers async disk reads to after the first frame, avoiding "setState during build" errors
- **`cacheExtent: 600`** on the wishlist grid — pre-renders cards 600 px outside the viewport for smoother scrolling

---

## Limitations

- **No real payment** — checkout is a UI demo; no payment gateway is integrated
- **No authentication** — delivery details are entered fresh each time
- **Order history is local only** — no backend sync; orders are lost if app data is cleared
- **Offline search** — search requires a network connection (uses DummyJSON's search endpoint)
- **Image quality** — images are served by DummyJSON; some are low-resolution stock photos

---

## Permissions

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

No location, contacts, camera, or storage permissions requested.

---

## Author

**Asif Saifi** — [asifsaifi92@gmail.com](mailto:asifsaifi92@gmail.com)
