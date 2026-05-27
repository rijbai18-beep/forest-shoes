// Semantic keys used by integration tests to locate widgets.
// Only add keys here — never hard-code strings in test files.
abstract class TestKeys {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const emailField    = 'login_email_field';
  static const passwordField = 'login_password_field';
  static const signInButton  = 'login_sign_in_button';
  static const signUpButton  = 'login_sign_up_button';
  static const guestButton   = 'login_guest_button';

  // ── Register ──────────────────────────────────────────────────────────────
  static const registerNameField     = 'register_name_field';
  static const registerEmailField    = 'register_email_field';
  static const registerPasswordField = 'register_password_field';
  static const registerButton        = 'register_button';

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  static const navHome    = 'nav_home';
  static const navShop    = 'nav_shop';
  static const navCart    = 'nav_cart';
  static const navProfile = 'nav_profile';

  // ── Shop / Product ────────────────────────────────────────────────────────
  static const productCard       = 'product_card';
  static const addToCartButton   = 'add_to_cart_button';
  static const wishlistButton    = 'wishlist_button';
  static const productSearchBar  = 'product_search_bar';

  // ── Cart ──────────────────────────────────────────────────────────────────
  static const cartEmptyMsg      = 'cart_empty_message';
  static const checkoutButton    = 'cart_checkout_button';
  static const cartItemRemove    = 'cart_item_remove';
  static const promoCodeField    = 'promo_code_field';
  static const applyPromoButton  = 'apply_promo_button';

  // ── Checkout ──────────────────────────────────────────────────────────────
  static const checkoutNameField    = 'checkout_name_field';
  static const checkoutPhoneField   = 'checkout_phone_field';
  static const checkoutAddressField = 'checkout_address_field';
  static const checkoutCityField    = 'checkout_city_field';
  static const placeOrderButton     = 'checkout_place_order_button';
  static const orderSuccessDialog   = 'order_success_dialog';
  static const trackOrderButton     = 'order_track_button';

  // ── Order History ─────────────────────────────────────────────────────────
  static const orderHistoryList = 'order_history_list';
  static const orderHistoryItem = 'order_history_item';
}
