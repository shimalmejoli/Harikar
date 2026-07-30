// lib/core/app_constants.dart
// ─────────────────────────────────────────────────────────────
// Single source of truth for every URL, key, and timeout.
// Never hardcode these values inside screens or services.
// ─────────────────────────────────────────────────────────────

class AppConstants {
  AppConstants._(); // prevent instantiation

  // ── Base ────────────────────────────────────────────────────
  static const String baseUrl = 'https://legaryan.heama-soft.com';
  static const String uploadsUrl = '$baseUrl/uploads/';

  // ── Cities (Kurdish names) ─────────────────────────────────
  // Single canonical list — used by every city dropdown across the
  // app (register, profile edit, insert/update details, work search,
  // etc.). When adding a city, add it HERE only — all dropdowns will
  // pick it up automatically. Keep the order stable; previously-saved
  // user records reference these exact strings.
  static const List<String> cities = [
    'دهۆک',
    'زاخۆ',
    'سێمێل',
    'ئاکرێ',
    'هەولێر',
    'سلێمانی',
  ];

  // ── API endpoints ───────────────────────────────────────────
  static const String categoriesEndpoint = '$baseUrl/get_categories.php';
  static const String subcategoriesEndpoint = '$baseUrl/get_subcategories.php';
  static const String slideshowEndpoint =
      '$baseUrl/fetch_slideshow_details.php';
  static const String fullDetailsEndpoint = '$baseUrl/fetch_full_details.php';
  static const String availableDetailsEndpoint =
      '$baseUrl/fetch_available_details.php';

  // Details
  static const String getDetailsEndpoint =
      '$baseUrl/get_details.php'; // DetailsPage
  static const String detailByIdEndpoint =
      '$baseUrl/get_details_by_id.php'; // WorkDetailsScreen
  static const String getDetailByIdEndpoint =
      '$baseUrl/get_detail_by_id.php'; // UpdateDetailsPage (single)
  static const String relatedDetailsEndpoint =
      '$baseUrl/get_related_details.php';
  static const String insertDetailsEndpoint = '$baseUrl/insert_details.php';
  static const String updateDetailsEndpoint = '$baseUrl/update_details.php';
  static const String deleteDetailsEndpoint = '$baseUrl/delete_details.php';
  static const String uploadImageEndpoint = '$baseUrl/upload_image.php';
  static const String deleteImageEndpoint = '$baseUrl/delete_image.php';
  static const String incrementViewEndpoint =
      '$baseUrl/increment_view_count.php';

  // Auth
  static const String loginEndpoint = '$baseUrl/login.php';
  static const String registerEndpoint = '$baseUrl/register_user.php';

  // ── Forgot password (3-step WhatsApp OTP flow) ──────────────
  // Backend contract — placeholder endpoints, you implement the PHP:
  //
  //   POST forgotPasswordSendEndpoint
  //     body : { "phone_number": "07XX..." }
  //     1. Verify a user exists for this phone. If not → 404-ish.
  //     2. Generate a random 4-digit code, store it in DB
  //        (code + expires_at + phone_number).
  //     3. Send the code to the user's WhatsApp via your messaging
  //        provider (Twilio / MessageBird / Termii / etc.).
  //     resp : { "status": "success", "message": "..." }
  //
  //   POST forgotPasswordVerifyEndpoint
  //     body : { "phone_number": "07XX...", "code": "1234" }
  //     1. Look up the unexpired row for this phone.
  //     2. If code matches → mark verified, return a one-shot token
  //        the client must include in the reset call.
  //     resp : { "status": "success", "token": "<random-string>" }
  //          | { "status": "error",   "message": "..." }
  //
  //   POST forgotPasswordResetEndpoint
  //     body : { "phone_number": "07XX...", "token": "<...>",
  //              "new_password": "..." }
  //     1. Verify the token matches the row from step 2 and is unused.
  //     2. Update the user's password (hash it!) and invalidate the
  //        token + any pending OTPs for this phone.
  //     resp : { "status": "success" } | { "status": "error", ... }
  static const String forgotPasswordSendEndpoint =
      '$baseUrl/forgot_password_send.php';
  static const String forgotPasswordVerifyEndpoint =
      '$baseUrl/forgot_password_verify.php';
  static const String forgotPasswordResetEndpoint =
      '$baseUrl/forgot_password_reset.php';

  // Users
  static const String updateUserEndpoint = '$baseUrl/update_user.php';
  static const String deleteAccountEndpoint = '$baseUrl/delete_account.php';
  static const String getUserDataEndpoint = '$baseUrl/get_user_data.php';
  static const String getUserInfoEndpoint = '$baseUrl/get_user_info.php';
  static const String getUserDetailsEndpoint = '$baseUrl/get_user_details.php';
  static const String getUsersEndpoint = '$baseUrl/get_users.php';
  static const String getUsers2Endpoint = '$baseUrl/get_users2.php';
  static const String updateUser2Endpoint = '$baseUrl/update_user2.php';
  static const String deleteUserEndpoint = '$baseUrl/delete_user.php';

  // Feedback
  static const String feedbackEndpoint = '$baseUrl/submit_feedback.php';
  static const String getFeedbackEndpoint = '$baseUrl/get_feedback.php';
  static const String deleteFeedbackEndpoint = '$baseUrl/delete_feedback.php';

  // Categories
  static const String addCategoryEndpoint = '$baseUrl/add_category.php';
  static const String updateCategoryEndpoint = '$baseUrl/update_category.php';
  static const String deleteCategoryEndpoint = '$baseUrl/delete_category.php';
  static const String toggleCategoryEndpoint =
      '$baseUrl/toggle_category_status.php';
  static const String activeCategoriesEndpoint =
      '$baseUrl/get_categories_active.php';

  // Subcategories
  static const String addSubcategoryEndpoint = '$baseUrl/add_subcategory.php';
  static const String updateSubcategoryEndpoint =
      '$baseUrl/update_subcategory.php';
  static const String deleteSubcategoryEndpoint =
      '$baseUrl/delete_subcategory.php';
  static const String toggleSubcategoryEndpoint =
      '$baseUrl/toggle_subcategory_status.php';

  // Ads
  static const String updateAdsStatusEndpoint =
      '$baseUrl/update_ads_status.php';

  // ── Store listings (in-app update check) ────────────────────
  // Must match android/app/build.gradle's `applicationId` and the iOS
  // `PRODUCT_BUNDLE_IDENTIFIER` — the update check looks the app up by
  // these ids, so a rename here silently disables the prompt.
  static const String androidPackageId = 'com.legaryan_kare.app';
  static const String appStoreBundleId = 'com.heamasoft.harikar';

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// Opens the Play Store app directly instead of a browser.
  static const String playStoreNativeUrl =
      'market://details?id=$androidPackageId';

  static const String appStoreLookupUrl = 'https://itunes.apple.com/lookup';

  /// Storefronts to query, in order. An app published only in Iraq is
  /// invisible from the default US storefront, hence the explicit list.
  static const List<String> appStoreCountries = ['iq', 'us'];

  // ── Network timeouts ────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Update lookups run at startup, so they stay short — a slow store
  /// response must never delay or block the first screen.
  static const Duration updateCheckTimeout = Duration(seconds: 8);

  // ── Pagination ──────────────────────────────────────────────
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // ── Cache keys ──────────────────────────────────────────────
  static const String cacheCategories = 'cache_categories';
  static const String cacheSubcategories = 'cache_subcategories';
  static const String cacheSlideshow = 'cache_slideshow';
  static const String cacheWorkDetails = 'cache_workdetails_';
  static const String cacheUserData = 'cache_user_data';
  static const String prefUserName = 'userName';
  static const String prefPhoneNumber = 'phoneNumber';
  static const String prefRole = 'role';
  static const String prefCity = 'city';
  static const String prefLanguage = 'language';
  static const String prefLastError = 'last_error';

  // ── App info ─────────────────────────────────────────────────
  static const String appName = 'ليگريان كارێ';
  static const String contactPhone = '07502827299';
  static const String whatsAppNumber = '9647502827299';
  static const String logoUrl = '$uploadsUrl/program_logo.png';
}
