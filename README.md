# College Canteen 🥗

A modern, responsive, 100% Pure Vegetarian college canteen food ordering Flutter application built with **Material 3** and **Provider** for state management. Runs seamlessly on **Android**, **iOS**, and **Web** from a single codebase.

---

## 🌟 Key Highlights

- **100% Pure Vegetarian**: Exclusively pure-veg menu items with official green FSSAI-style veg indicators and a signature "100% Pure Veg" green leaf badge. Absolutely no non-veg items, symbols, or toggles anywhere.
- **Single-Package Architecture**: State management powered strictly by `provider` (`ChangeNotifier`). No other third-party dependencies.
- **In-Memory State**: Fast, reactive, client-side in-memory state with zero backend requirement.
- **Material 3 Design**: Warm canteen orange palette (`#E65100`) on an off-white background (`#FAF7F2`) with 12–16 px rounded corners and smooth transitions.
- **Cross-Platform Responsive**: Responsive design with a centered max-width constraint (600px) on wide desktop/web screens and native full-width layout on mobile.
- **Zero Dart:HTML**: Clean, platform-agnostic Dart code avoiding deprecated or web-only libraries.

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point, MultiProvider & MaterialApp setup
├── previews.dart                      # Component & screen preview catalog
├── core/
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 theme, colors, typography & layout constants
│   └── constants/                     # Core constants (daily_messages in Prompt B)
└── features/
    ├── profile/
    │   ├── customer_profile.dart      # CustomerProfile model (fullName, mobileNumber)
    │   ├── profile_provider.dart      # ProfileProvider state management
    │   └── profile_screen.dart        # Full-screen profile form (mandatory PopScope & edit mode)
    ├── food/
    │   ├── data/
    │   │   ├── menu_data.dart         # 16-item pure-veg canteen menu dataset
    │   │   └── locations_data.dart    # 9 campus delivery locations (Zone 1 & Zone 2)
    │   ├── models/
    │   │   ├── food_item.dart         # FoodItem model and FoodCategory enum
    │   │   ├── cart_item.dart         # CartItem model combining FoodItem and quantity
    │   │   └── campus_location.dart   # CampusLocation model and DeliveryZone enum
    │   ├── providers/
    │   │   ├── cart_provider.dart     # Cart state management (ChangeNotifier)
    │   │   └── checkout_provider.dart # Delivery spot & billing calculation
    │   ├── widgets/
    │   │   ├── food_card.dart         # FoodCard & VegSymbol widget
    │   │   ├── category_filter_bar.dart # Horizontally scrollable ChoiceChip filter bar
    │   │   ├── quantity_selector.dart # Smooth "Add to Order" to (− qty +) switcher
    │   │   ├── bill_summary.dart      # Live order bill breakdown
    │   │   └── order_confirmation_dialog.dart # Simulated order dialog with order ID
    │   └── screens/
    │       ├── menu_screen.dart       # Main menu view with AppBar, filters, list & sticky bar
    │       ├── cart_screen.dart       # Cart screen with item details, line totals, empty state
    │       └── checkout_screen.dart   # Real checkout screen with spot dropdown & live bill breakdown
    └── home/
        ├── screens/                   # (HomeScreen coming in Prompt B)
        └── widgets/                   # Home feature widgets
```

---

## 🍽️ The 100% Pure Veg Menu

| Category | Item Name | Price | Prep Time |
| :--- | :--- | :--- | :--- |
| **Snacks** | Samosa (2 pcs) | ₹20 | 5 min |
| **Snacks** | Veg Puff | ₹25 | 5 min |
| **Snacks** | Vada Pav | ₹25 | 5 min |
| **Snacks** | French Fries | ₹50 | 8 min |
| **Snacks** | Veg Sandwich | ₹40 | 7 min |
| **Meals** | Veg Thali | ₹90 | 12 min |
| **Meals** | Paneer Roll | ₹60 | 10 min |
| **Meals** | Hakka Noodles (Veg) | ₹70 | 10 min |
| **Meals** | Veg Biryani | ₹90 | 12 min |
| **Meals** | Chole Bhature | ₹65 | 10 min |
| **Meals** | Masala Dosa | ₹60 | 10 min |
| **Beverages** | Masala Chai | ₹15 | 4 min |
| **Beverages** | Cold Coffee | ₹45 | 5 min |
| **Beverages** | Fresh Lime Soda | ₹30 | 4 min |
| **Desserts** | Chocolate Brownie | ₹50 | 3 min |
| **Desserts** | Gulab Jamun (2 pcs) | ₹30 | 3 min |

*All items include rich 2-3 line descriptions and high-resolution images with automatic loading states and network error fallbacks.*

---

## 🛒 Features & User Flow

1. **AppBar**:
   - Displays "College Canteen" alongside a distinctive green leaf **"100% Pure Veg"** badge.
   - Live cart icon with a badge showing `totalQuantity` updated in real time.
   - Profile icon for accessing and updating customer profile.
2. **Instant Category Filtering**:
   - Scrollable ChoiceChip bar directly beneath the AppBar: **All**, **Snacks**, **Meals**, **Beverages**, and **Desserts**.
   - Highlights the selected category and instantly updates the menu list via `AnimatedSwitcher`.
3. **Interactive Food Cards**:
   - Rounded corners (16px) with high-res food image inside a `ClipRRect`.
   - Built-in `loadingBuilder` with smooth progress indicator and `errorBuilder` fallback (canteen-themed warm box with icon).
   - FSSAI green veg symbol (green square with green dot).
   - Bold name, category badge, 3-line trimmed description, preparation time (`⏱ X min`), and price in ₹.
   - **Quantity Selector**: Starts as **"Add to Order"**, and turns into a **(− qty +)** counter on click. Decrementing to 0 smoothly returns to "Add to Order".
4. **Sticky Order Bar**:
   - Appears dynamically at the bottom of the screen whenever the cart contains items.
   - Displays live `X items | ₹Subtotal` where Subtotal = $\sum (\text{price} \times \text{quantity})$.
   - Tapping **"Proceed to Order"** checks `ProfileProvider.hasProfile`: opens mandatory Profile if empty, or skips to Checkout if saved.
5. **Dedicated Cart Screen**:
   - Lists all selected items with food photo, green FSSAI veg symbol, unit price, inline `(− qty +)` counter, and line total (`price × qty`).
   - Supports both swipe-to-delete (`Dismissible`) with undo snackbar and explicit trash icon removal.
   - Displays subtotal labeled **"Base Food Price"** and a **"Proceed to Order"** button.
   - Dynamic **Empty State**: when empty, shows a large cart icon, `"Your cart is empty"`, and a `"Browse Menu"` button that returns to the menu.
   - 100% two-way synchronized with the Menu screen via `CartProvider`.
6. **Mandatory Customer Profile Step**:
   - First "Proceed to Order" forces full-screen **Create Customer Profile** page non-dismissible by outside taps or swipe (`PopScope(canPop: false)`).
   - Only exits are **"Save & Continue"** (saves to session memory) or an explicit **"Back to Cart"** button.
   - Strict input validation:
     - **Full Name**: required, min 3 characters, letters and spaces only.
     - **Mobile Number**: required, exactly 10 digits, starts with 6–9, phone keyboard with 10-digit limit.
   - Second "Proceed to Order" skips the profile page and goes directly to Checkout.
   - Profile icon in the AppBar opens the pre-filled form so customers can edit their details freely.
7. **Real Campus Checkout & Delivery Zone Calculation**:
   - **Delivery Spot Selector**: `DropdownButtonFormField` with hint *"Select your delivery spot"*, listing Zone 1 first, then Zone 2, each with coloured zone tags:
     - **Zone 1 (+₹15 per item)**: `234`, `235`, `236`, `237`, `Backside of Block 3 Building`.
     - **Zone 2 (+₹20 per item)**: `121`, `120`, `Block-2`, `Block-1`.
   - **Automatic Reset**: Whenever the checkout screen opens, the selected delivery location is reset to `null` so no location is accidentally carried over.
   - **Validation & Disabled State**: The **"Confirm Order"** button remains disabled with helper text *"Please select a delivery location"* until a spot is picked.
   - **Live Bill Breakdown**:
     - Itemized ordered items (`name × qty = ₹line total`).
     - Base Food Price (Subtotal): $\sum (\text{price} \times \text{quantity})$.
     - Delivery Location: `<name> (<Zone>)`.
     - Zone Extra Charge: ₹`<per item>` × `<total quantity>` = ₹`<extra>`.
     - Final Total Amount to Pay: ₹`<total>` (large, bold, highlighted).
   - **Simulated Payment & Order Confirmation Dialog**:
     - 1-second simulated loading state protected against double taps.
     - Confirmation dialog featuring success icon, unique Order ID (e.g., `ORD-4821`), student recipient details, delivery spot & zone, itemized items, and `"Total Cash/UPI Amount Payable on Delivery: ₹<TotalAmount>"`.
     - **"Done"** action clears the cart, resets the delivery location, **keeps** the customer profile in memory, and returns directly to the menu.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.0.0`)

### Installation & Run

1. Clone or navigate to the project directory:
   ```bash
   cd "Food Booking"
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run on your desired platform:
   - **Web (Chrome)**:
     ```bash
     flutter run -d chrome
     ```
   - **Android**:
     ```bash
     flutter run -d android
     ```
   - **iOS**:
     ```bash
     flutter run -d ios
     ```

4. Run unit and widget test suite:
   ```bash
   flutter test
   ```
