class AppConstants {
  AppConstants._();

  static const String appName = 'Forest Shoes';
  static const String supportEmail = 'support@forestshoes.mu';

  // Currency
  static const String currency = 'Rs';
  static const double freeDeliveryThreshold = 300.0;
  static const double defaultDeliveryFee = 100.0;
  static const double engravingFee = 100.0;
  static const int engravingMaxChars = 10;

  // Firestore collections
  static const String colUsers = 'users';
  static const String colProducts = 'products';
  static const String colCategories = 'categories';
  static const String colOrders = 'orders';
  static const String colCoupons = 'coupons';
  static const String colBanners = 'banners';
  static const String colPaymentTypes = 'paymentTypes';
  static const String colDeliveryTypes = 'deliveryTypes';
  static const String colNotifications = 'notifications';
  static const String colSupportTickets = 'supportTickets';
  static const String colSettings = 'settings';
  static const String colContent = 'content';
  static const String colReviews = 'reviews';
  static const String colStockAlerts = 'stockAlerts';
  static const String colAuditLogs = 'audit_logs';

  // Subcollections
  static const String subWishlist = 'wishlist';
  static const String subMessages = 'messages';
  static const String subAddresses = 'addresses';

  // Settings document
  static const String settingsGlobal = 'global';
  static const String contentTerms = 'terms';
  static const String contentPrivacy = 'privacy';
  static const String contentDataPrivacy = 'dataPrivacy';
  static const String contentAbout = 'about';

  // Order statuses
  static const String statusNew = 'new';
  static const String statusPending = 'pending_payment';
  static const String statusReviewed = 'reviewed';
  static const String statusProcessing = 'processing';
  static const String statusDispatched = 'dispatched';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  // Ticket statuses
  static const String ticketOpen = 'open';
  static const String ticketInProgress = 'in_progress';
  static const String ticketClosed = 'closed';

  // SharedPreferences keys
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefCartItems = 'cart_items';
  static const String prefTheme = 'theme_mode';

  // Pagination
  static const int pageSize = 20;
  static const int homeFeaturedLimit = 10;
  static const int homeCategoryLimit = 8;
}

class AppAssets {
  AppAssets._();

  static const String logo = 'assets/images/logo.png';
  static const String logoWhite = 'assets/images/logo_white.png';
  static const String placeholder = 'assets/images/placeholder.png';
  static const String emptyCart = 'assets/animations/empty_cart.json';
  static const String emptyOrders = 'assets/animations/empty_orders.json';
  static const String success = 'assets/animations/success.json';
  static const String loading = 'assets/animations/loading.json';
  static const String noWifi = 'assets/animations/no_wifi.json';
  static const String shoe1 = 'assets/images/shoe_placeholder_1.png';
  static const String shoe2 = 'assets/images/shoe_placeholder_2.png';
}
