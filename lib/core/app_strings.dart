// lib/core/app_strings.dart
// ─────────────────────────────────────────────────────────────
// Centralized bilingual strings (Arabic + Kurdish) for the app.
//
// Usage from any screen:
//   import '../core/app_strings.dart';
//   ...
//   Text(S.login.of(context))
//
// To add a new string: add a `static const` of type [TString]
// below in the appropriate section. Keep keys in lowerCamelCase
// and semantic (e.g. `loginSubmitButton`, not `button1`).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/widgets.dart';

import '../main.dart' show LocaleContext;

/// A pair of strings — one for Arabic, one for Kurdish.
/// Resolve to the user's currently-selected language with [of].
class TString {
  final String ar;
  final String ku;
  const TString(this.ar, this.ku);

  /// Returns the Arabic or Kurdish text based on [LocaleProvider].
  /// Subscribes to language changes via the watching `context.isArabic`
  /// extension, so any widget reading this from `build()` will rebuild
  /// when the user switches language.
  String of(BuildContext context) => context.isArabic ? ar : ku;
}

/// All app strings live here. Group by section using comment headers.
class S {
  S._();

  // ── Common / shared ──────────────────────────────────────
  static const retry = TString('إعادة المحاولة', 'دووبارەکرن');
  static const yes = TString('نعم', 'بەڵێ');
  static const no = TString('لا', 'نەخێر');
  static const cancel = TString('إلغاء', 'پاشگەزبوونەوە');
  static const fieldRequired = TString('هذا الحقل مطلوب', 'پێویستە');
  static const fieldRequiredFill =
      TString('هذا الحقل مطلوب', 'پێویستە پر بکرێتەوە');
  static const phoneNumberLabel = TString('رقم الهاتف', 'ژمارەی مۆبایل');
  static const phoneNumberLabelColon = TString('رقم الهاتف:', 'ژمارەی مۆبایل:');
  static const cityLabel = TString('المدينة', 'شار');
  static const cityLabelColon = TString('المدينة:', 'شار:');
  static const passwordLabel = TString('كلمة المرور', 'پەیڤا نهێنی');
  static const fullNameLabel = TString('الاسم الكامل', 'ناوی تەواو');
  static const fullNameLabelColon = TString('الاسم الكامل:', 'ناوی تەواو:');
  static const workTypeLabel = TString('نوع العمل', 'جۆری کار');
  static const workTypeLabelColon = TString('نوع العمل:', 'جۆری کار:');
  static const paymentAmountLabel = TString('مبلغ الدفع', 'بڕی پارە');
  static const expiryDateLabel = TString('تاريخ الانتهاء', 'بەسەرچوونی');
  static const updateButton = TString('تحديث', 'نوێکردنەوە');
  static const callLabel = TString('اتصال', 'پەیوەندی');
  static const enterValidNumber =
      TString('يرجى إدخال رقم صحيح', 'ژمارەی دروست بنڤیسە');
  static const nameNotAvailable = TString('اسم غير متوفر', 'ناڤ نییە');
  static const noteSaveSuccess = TString(
      'مرحبا، لقد وجدتك في تطبيق هاريكار. أود التواصل معك.',
      'سلاڤ، من دڤێت پەیوەندی تە بکەم. من پێزانین تە دیتینە رێکا پرۆگرامێ هاریکار.');

  // ── Infinite-scroll lists (shared) ───────────────────────
  static const listLoadingMore =
      TString('جاري تحميل المزيد...', 'جارى باركرنا زێدەتر...');
  static const listAllLoaded =
      TString('تم عرض جميع النتائج', 'هەمی ئەنجام هاتنە پیشاندان');

  // ── Footer menu ─────────────────────────────────────────
  static const footerHome = TString('الرئيسية', 'پەڕا سەرەکی');
  static const footerRegister = TString('التسجيل', 'خۆتۆمارکرن');
  static const footerAbout = TString('حول', 'دەربارە');

  // ── Drawer ───────────────────────────────────────────────
  static const drawerSectionHome = TString('الرئيسية', 'سەرەکی');
  static const drawerHome = TString('الصفحة الرئيسية', 'پەڕەی سەرەکی');
  static const drawerProfile = TString('الملف الشخصي', 'پەڕەی کەسی');
  static const drawerSectionAdmin = TString('الإدارة', 'بەڕێوەبردن');
  static const drawerAddCategory = TString('إضافة وظيفة', 'زیادکردنی کار');
  static const drawerAddSubcategory =
      TString('إضافة مركز عمل', 'زیادکردنی ناوەندی کار');
  static const drawerViewUsers =
      TString('عرض المستخدمين', 'بینینی بەکارهێنەرەکان');
  static const drawerInsertDetails =
      TString('إضافة معلومات', 'زیادکردنی زانیاری');
  static const drawerShowDetails =
      TString('عرض المعلومات', 'پیشاندانی زانیاریەکان');
  static const drawerEditUser = TString('تعديل مستخدم', 'ئاپدتکرنا کارهێنەرا');
  static const drawerEditAds = TString('تعديل اعلانات', 'ئاپدتکرنا ریکلام');
  static const drawerSectionAccount = TString('الحساب', 'هەژمار');
  static const drawerRegister = TString('التسجيل', 'خو توماربکە');
  static const drawerSectionGeneral = TString('عام', 'گشتی');
  static const drawerFeedback = TString('الإبلاغ', 'سکالا');
  static const drawerFeedbackSection = TString('قسم الإبلاغ', 'بەشێ سکالا');
  static const drawerAbout = TString('حول', 'دەربارە');
  static const drawerChangeLanguage = TString('تغيير اللغة', 'گهورینا زمانی');
  static const drawerDeleteAccount = TString('حذف الحساب', 'سڕینەوەی ئەکاونت');
  static const drawerLogout = TString('تسجيل الخروج', 'چوونا دەرێ');
  static const drawerLogin = TString('تسجيل الدخول', 'چوونا ژور');
  static const drawerDeleteConfirmTitle =
      TString('تأكيد الحذف', 'دڵنیایت لە سڕینەوەی ئەکاونت؟');
  static const drawerDeleteConfirmContent = TString(
      'سيتم حذف حسابك وجميع بياناتك نهائيًا.',
      'ئەکاونتەکەت و هەموو زانیاریەکان بە تەواوی دەسڕدرێن.');
  static const drawerDeleteAction = TString('حذف', 'سڕینەوە');
  static const drawerDeleteUserNotFound =
      TString('تعذر تحديد المستخدم.', 'نەیتوانرا ئەکاونتەکەت بدۆزرێتەوە');
  static const drawerDeleteSuccess =
      TString('تم حذف الحساب بنجاح', 'ئەکاونتەکەت بە سەرکەوتوویی سڕدرایەوە');
  static const drawerDeleteFailure =
      TString('فشل حذف الحساب.', 'هەڵەیەک ڕویدا لە سڕینەوەی ئەکاونت.');
  static const drawerLanguageDialogTitle =
      TString('اختر اللغة', 'زمان هەلبژێرە');
  static const drawerWelcome = TString('مرحبا بك', 'بەخێر هاتی');
  static const drawerRoleAdmin = TString('مشرف', 'ئەدمین');
  static const drawerRoleUser = TString('مستخدم', 'بەکارهێنەر');

  // ── Dashboard ────────────────────────────────────────────
  static const dashboardLoadCategoriesError = TString(
      'فشل في تحميل الأقسام. الرجاء المحاولة لاحقاً.',
      'خەلەتی د ڤەهاندنا پۆلان دا. هیڤیە دووبارە بکەڤە.');
  static const dashboardTitle = TString('الصفحة الرئيسية', 'پەڕا سەرەکی');
  static const dashboardFeaturedAds =
      TString('إعلانات مميزة', 'ئیلانە تایبەتەکان');
  static const dashboardAdBadge = TString('إعلان', 'ئیلان');
  static const dashboardCategories = TString('الأقسام', 'پۆلەکان');
  static const dashboardCategoryBadge = TString('قسم', 'پۆل');
  static const dashboardAdCardText = TString(
      'إذا كنت ترغب في عرض إعلانك في التطبيق، اتصل بنا',
      'ژ بۆ ڕیکلامکرنێ دناڤ بەرنامەیێ هاریکار دا پەیوەندی بکە');
  static const dashboardNoAds =
      TString('لا يوجد إعلانات حالياً.', 'چ ئیلانێن بەردەست نین نوکە.');
  static const dashboardLoadingCategories =
      TString('جاري تحميل الأقسام...', 'بەرێخستنا پۆلان د چێبیت...');

  // ── Login ────────────────────────────────────────────────
  static const loginPromptInputs = TString(
      'يجب إدخال رقم الهاتف أو اسم المستخدم وكلمة المرور.',
      'ژمارەی مۆبایل یان ناڤی بەکارەوەر و وشەی نهێنی پێویستە.');
  static const loginFailed =
      TString('فشل تسجيل الدخول', 'چوونەژوورەوە سەرنەکەوت');
  static const loginNetworkError = TString(
      'حدث خطأ: يرجى المحاولة مرة أخرى.', 'هەڵە ڕویدا: تکایە دوبارە هەوڵ بدە.');
  static const loginAppBarTitle = TString('تسجيل الدخول', 'چوونەژوورەوە');
  static const loginInstruction = TString(
      'يرجى إدخال رقم الهاتف أو اسم المستخدم وكلمة المرور',
      'هێڤیە ژمارا مۆبایلێ یان ناڤ و پەیڤا نهێنی تومار بکە');
  static const loginInputLabel =
      TString('رقم الهاتف أو اسم المستخدم', 'ژمارەی مۆبایل یان ناو');
  static const loginPasswordLabel = TString('كلمة المرور', 'پایڤا نهێنی');
  static const loginButton = TString('تسجيل الدخول', 'چونا ژور');
  static const loginForgotPassword =
      TString('هل نسيت كلمة المرور؟', 'پەیڤا نهێنی ژ بیرا تە چوویە');
  static const loginRegisterPrompt = TString('لم تقم بالتسجيل بعد؟ سجل الآن',
      'هێشتا تە خو تومار نەکریە! خو تومار بکە');

  // ── Register ─────────────────────────────────────────────

  static const registerPhoneIraqiInvalid = TString(
      'يرجى إدخال رقم عراقي صحيح (مثل: 0750-###-##-##)',
      'تکایە ژمارەیەکی عێراقی دروست بنووسە (نموونە: 0750-###-##-##)');
  static const registerPhoneHint = TString('0750-###-##-##', '0750-###-##-##');
  static const registerLoadWorkTypesFailed =
      TString('فشل تحميل أنواع العمل', 'هەڵە لە وەرگرتنی جۆرەکانی کار');
  static const registerSuccess =
      TString('تم التسجيل بنجاح!', 'خۆت تۆمار کرا بەرەوپێش!');
  static const registerOperationFailed = TString('فشل العملية', 'ئەرکە نادرا');
  static const registerNetworkError = TString('خطأ في الإنترنت، يرجى المحاولة.',
      'هەڵەی ئینتەرنێت، تکایە هەوڵ بدەرەوە.');
  static const registerTitle = TString('تسجيل', 'خو تومار بکە');
  static const registerAlreadyDone =
      TString('أنت مسجل بالفعل!', 'تە خۆت تۆمار کردووە!');
  static const registerAlreadyDoneSubtitle = TString(
      'يمكنك الذهاب إلى الصفحة الرئيسية والاستفادة من جميع ميزات التطبيق.',
      'دەتوانیت بچیتە پەڕەی سەرەکی و سوود لە هەموو ئامرازەکانی بەرنامە وەربگریت.');
  static const registerGoHome = TString('الذهاب للرئيسية', 'بچو بۆ سەرەکی');
  // Just-registered success state (shown inline after successful submit)
  static const registerSuccessTitle =
      TString('تم تسجيلك بنجاح!', 'خۆت بە سەرکەوتوویی تۆمارکرا!');
  static const registerSuccessSubtitle = TString(
      'مرحباً بك في هاريكار! يمكنك الآن إكمال معلوماتك والاستفادة من ميزات التطبيق.',
      'بەخێر بێیت بۆ هاریکار! ئێستا دەتوانیت زانیاریەکانت تەواو بکەیت و سوود لە بەرنامە وەربگریت.');
  static const registerContinue = TString('متابعة', 'بەردەوام بە');
  // Abort dialog shown when user tries to leave the work-details
  // page after registering but before completing details.
  static const registerAbortTitle = TString(
      'هل تريد إلغاء التسجيل؟', 'دەتەوێت تۆمارکردن هەڵبوەشێنیتەوە؟');
  static const registerAbortMessage = TString(
      'إذا خرجت الآن، سيتم حذف تسجيلك. يجب إكمال إضافة تفاصيل العمل لتثبيت التسجيل.',
      'ئەگەر ئێستا بچیتە دەرەوە، تۆمارکردنەکەت دەسڕێتەوە. پێویستە زانیاری کارەکانت زیاد بکەیت بۆ تەواوکردنی تۆمارکردن.');
  static const registerAbortConfirm =
      TString('نعم، إلغاء', 'بەڵێ، هەڵبوەشێنە');
  static const registerAbortCancel =
      TString('متابعة الإكمال', 'بەردەوامبوون');
  static const registerAbortFailedSnack = TString(
      'فشل إلغاء التسجيل، يرجى المحاولة لاحقاً.',
      'هەڵە لە هەڵوەشاندنەوەی تۆمارکردن، تکایە دواتر هەوڵبدەرەوە.');
  // Shown on the login screen after a registration was cancelled and
  // rolled back — explains why the user has just been logged out.
  static const registerRolledBackSnack = TString(
      'لم يكتمل التسجيل. تم إلغاء حسابك. يرجى التسجيل من جديد.',
      'تۆمارکردن تەواو نەبوو. هەژمارەکەت سڕایەوە. تکایە جارێکی تر خۆت تۆمار بکە.');
  static const registerNow = TString('سجل الآن', 'خۆت تۆمار بکە');
  static const registerHeroSubtitle = TString(
      'انضم إلينا واستفد من جميع ميزات تطبيق هاريكار.',
      'بکەرەوە و سوود لە هەموو ئامرازەکانی بەرنامەی هاریکار وەربگرە.');
  static const registerFullNameLabel = TString('الاسم الكامل', 'ناڤی تەواو');
  static const registerFullNameHint = TString('الاسم الكامل', 'ناڤێ تەواو');
  static const registerPhoneLabel =
      TString('رقم الهاتف المحمول', 'ژمارا موبایلێ');
  static const registerCityLabel = TString('المدينة', 'باژێر');
  static const registerCityHint = TString('اختر المدينة', 'باژێرێ هەلبژێرە');
  static const registerWorkTypeLabel = TString('نوع العمل', 'جۆری کاری');
  static const registerWorkTypeHint =
      TString('اختر نوع العمل', 'جۆری کار هەلبژێرە');
  static const registerPasswordHint =
      TString('أدخل كلمة المرور', 'پەیڤا نهێنی بنڤیسە');
  static const registerSubmit = TString('تسجيل', 'خۆتومارکە');
  static const registerInfoNote = TString(
      'بعد التسجيل، سنتواصل معك للحصول على المزيد من المعلومات والتأكيد على نجاح العملية.',
      'پشتی تومارکرنێ دێ پەیوەندی ب تە کەین بۆ پتر پێزانینان دناف پروگرامێ هاریکاردا.');

  // ── About ────────────────────────────────────────────────
  static const aboutTitle = TString('حولنا', 'دەربارەی ئێمە');
  static const aboutHeroDescription = TString(
      'تطبيق هاريكار يساعدك على إيجاد العمال والمهندسين والخبرات التي تحتاجها بسرعة وكفاءة.',
      'بەرنامەی هاریکار یارمەتیت دەدات بۆ دۆزینەوەی کرێکار، ئەندازیار و پسپۆڕان بە خێرایی و باشترین شێوە.');
  static const aboutBrand = TString('هاريكار', 'هاریکار');
  static const aboutContactTitle =
      TString('رقم التواصل للشركة', 'ژمارەی پەیوەندی کۆمپانیا');
  static const aboutContactCardLabel =
      TString('اتصل بنا', 'پەیوەندیمان پێوە بکە');
  static const aboutAdvertiseTitle = TString('أعلن معنا', 'ڕیکلام لەگەڵمان');
  static const aboutAdvertiseDescription = TString(
      'إذا كنت ترغب في عرض إعلانك في التطبيق، تواصل معنا الآن.',
      'بۆ ڕیکلامکردن لە ناو بەرنامەکەدا، پەیوەندیمان پێوە بکە.');
  static const aboutCreditsTitle =
      TString('تم تطوير هذا التطبيق من قبل', 'ئەم بەرنامەیە لەلایەن');

  // ── AdsManagement ────────────────────────────────────────
  static const adsDeleteFailed =
      TString('فشل حذف الإعلان', 'خەلەتی د ژێبرنا ریکلامی دا');
  static const adsConfirmDeleteTitle =
      TString('تأكيد الحذف', 'دڵنیابوون ژێبرنێ');
  static const adsConfirmDeleteContent = TString(
      'هل أنت متأكد أنك تريد حذف هذا الإعلان؟', 'دڵنیای ژێبرنا ڤی ریکلامی؟');
  static const adsCancelButton = TString('إلغاء', 'هەلڤەشاندن');
  static const adsDeleteButton = TString('حذف', 'ژێبرن');
  static const adsLimitReached = TString(
      'لا يمكن أن يكون هناك أكثر من 5 إعلانات.',
      'ناهێت کرن پتر ژ ٥ ریکلامان هەبن.');
  static const adsAddFailed =
      TString('فشل إضافة الإعلان', 'خەلەتی د زێدەکرنا ریکلامی دا');
  static const adsSearchHint =
      TString('ابحث بالاسم أو رقم الهاتف', 'گەڕیان ب ناڤ یان ژمارێ');
  static const adsAddTooltip = TString('إضافة إعلان', 'زێدەکرنا ریکلامی');
  static const adsEmpty = TString('لا توجد إعلانات', 'چ ریکلام نینن');
  static const adsActiveBadge = TString('إعلان نشط', 'ریکلام چالاک');

  // ── DetailsPage (admin list) ─────────────────────────────
  static const detailsDeleteSuccess =
      TString('تم حذف المعلومات بنجاح', 'زانیاری بە سەرکەوتوویی سڕاوە');
  static const detailsDeleteTitle = TString('حذف', 'سڕینەوە');
  static const detailsDeleteContent = TString(
      'هل أنت متأكد من حذف هذه المعلومات؟', 'دڵنیای کە ئەم زانیاریە بسڕیتەوە؟');
  static const detailsEmpty = TString('لا توجد معلومات', 'هیچ زانیاری نییە');
  static const detailsSearchHint =
      TString('البحث باسم المعلومات...', 'گەڕان بەناوی زانیاری...');
  static const detailsFilterByUser =
      TString('بحث بالمستخدم', 'گەڕان بەبەکارهێنەر');
  static const detailsAllUsers =
      TString('جميع المستخدمين', 'هەموو بەکارهێنەران');
  static const detailsFilterByCategory =
      TString('بحث بالفئة', 'گەڕان بەژێرپۆل');
  static const detailsAllCategories =
      TString('جميع الفئات', 'هەموو ژێرپۆلەکان');
  static const detailsNoName = TString('لا يوجد اسم', 'ناو نییە');
  static const detailsSubcategoryType =
      TString('نوع الفئة الفرعية', 'جۆری ژێرپۆل');
  static const detailsName = TString('الاسم', 'ناو');
  static const detailsContact = TString('رقم الاتصال', 'ژمارەی پەیوەندی');
  static const detailsLocation = TString('الموقع', 'شوێن');
  static const detailsDescription = TString('الوصف', 'وەسف');
  static const detailsImagesLabel = TString('الصور:', 'وێنەکان:');

  // ── FeedbackPage (admin) ─────────────────────────────────
  static const feedbackPageLoadError =
      TString('فشل في تحميل الملاحظات.', 'خەلەتی لە هنارتنا داتا دا');
  static const feedbackPageFetchError = TString(
      'حدث خطأ أثناء جلب الملاحظات.', 'خەلەتی ڕوویدا لە هنارتنا فیدباکی دا.');
  static const feedbackPageDeleteTitle = TString('حذف', 'ژێبرن');
  static const feedbackPageDeleteContent =
      TString('هل أنت متأكد من حذف هذه الملاحظات؟', 'پشت راستی ژێبرنێ؟');
  static const feedbackPageDeletedSnack =
      TString('تم حذف الملاحظات.', 'فیدباکەکە هاتن ژێبرن.');
  static const feedbackPageDeleteFailedSnack =
      TString('فشل حذف الملاحظات.', 'ژێبرن فیدباکە سەرکەفتی نەبی.');
  static const feedbackPageUserName = TString('اسم المستخدم', 'ناڤ بەکارهێنەر');
  static const feedbackPageMessageLabel = TString('الرسالة:', 'پەیام:');
  static const feedbackPageMessageNone =
      TString('الرسالة غير محددة', 'پەیام نادیارە');
  static const feedbackPageClose = TString('إغلاق', 'داخستن');
  static const feedbackPageTitle = TString('الملاحظات', 'فیدباکەکان');
  static const feedbackPageEmpty =
      TString('لا توجد ملاحظات.', 'هیچ فیدباکێک نەدۆزرایەوە.');

  // ── FeedbackScreen (user-facing) ─────────────────────────
  static const feedbackSubmitSnack =
      TString('تم إرسال ملاحظاتك بنجاح!', 'فیدبەکەت بە سەرکەوتوویی نێردرا!');
  static const feedbackTitle = TString('الإبلاغ', 'سکالا');
  static const feedbackHeroTitle =
      TString('شاركنا رأيك', 'بیر و ڕای خۆت بنووسە');
  static const feedbackHeroSubtitle = TString(
      'ساعدنا في تحسين التطبيق بإرسال ملاحظاتك واقتراحاتك.',
      'یارمەتیمان بدە بۆ باشترکردنی بەرنامە بە ناردنی ڕای خۆت.');
  static const feedbackSuccessTitle =
      TString('تم الإرسال بنجاح', 'بە سەرکەوتوویی نێردرا');
  static const feedbackSuccessBody = TString(
      'شكراً لك! سنقوم بمراجعة ملاحظاتك والرد قريباً.',
      'سپاسی بۆ هەوە. ئەم دێ ئاریشێ چارەسەر کەین و پەیوەندی بکەین.');
  static const feedbackBackHome =
      TString('العودة إلى الرئيسية', 'زڤرین بۆ سەرەکی');
  static const feedbackNameLabel = TString('الاسم', 'ناڤ');
  static const feedbackNameHint = TString('اسمك الكامل', 'ناڤێ تەواو');
  static const feedbackNameRequired =
      TString('يرجى إدخال اسمك', 'تکایە ناوی خۆت بنووسە');
  static const feedbackPhoneLabel = TString('رقم الجوال', 'ژمارەی مۆبایلێ');
  static const feedbackPhoneRequired =
      TString('يرجى إدخال رقم الجوال', 'ژمارەی مۆبایلێ بنڤیسە');
  static const feedbackPhoneInvalid =
      TString('يرجى إدخال رقم صحيح', 'ژمارەی مۆبایلێ دروست بنڤیسە');
  static const feedbackMessageLabel = TString('الرسالة', 'پەیام');
  static const feedbackMessageHint = TString(
      'اكتب ملاحظاتك أو اقتراحاتك هنا...',
      'فیدباک یان پێشنیارا خو لێرە بنڤیسە...');
  static const feedbackMessageRequired =
      TString('يرجى إدخال رسالتك', 'پەیاما خو ژی بنڤیسە');
  static const feedbackSubmit = TString('إرسال', 'هنارتن');

  // ── ForgetPassword ───────────────────────────────────────
  static const forgetPasswordTitle =
      TString('هل نسيت كلمة السر؟', 'وشەی نهێنی لەبیرت چووە؟');
  static const forgetPasswordInstruction = TString(
      'يرجى إدخال رقم هاتفك لإرسال رمز التحقق.',
      'تکایە ژمارەی مۆبایلەکەت بنووسە بۆ ناردنی کۆدی نوسینەوە.');
  static const forgetPasswordSentSnack = TString(
      'تم إرسال رمز التحقق إلى رقم الهاتف.',
      'کۆدی نوسینەوە بۆ ژمارەیەکە نێردرا.');
  static const forgetPasswordSendButton = TString('إرسال الرمز', 'ناردنی کۆد');
  // 3-step OTP flow (phone → code → new password)
  static const forgotPasswordHeroSubtitle = TString(
      'أدخل رقم هاتفك وسنرسل لك رمز التحقق عبر WhatsApp.',
      'ژمارەی مۆبایلت بنووسە و کۆدی پشتڕاستکردنەوە لە ڕێگەی WhatsApp بۆت دەنێرین.');
  static const forgotPasswordPhoneInvalid =
      TString('رقم الهاتف غير صحيح', 'ژمارەی مۆبایل دروست نییە');
  static const forgotPasswordSendFailed = TString(
      'فشل إرسال الرمز. حاول مرة أخرى.',
      'ناردنی کۆد سەرنەکەوت. تکایە دووبارە هەوڵ بدە.');
  static const forgotPasswordCodeStepTitle =
      TString('أدخل رمز التحقق', 'کۆدی پشتڕاستکردنەوە بنووسە');
  static const forgotPasswordCodeStepSubtitle = TString(
      'أرسلنا رمزاً مكوناً من 4 أرقام إلى رقم WhatsApp التالي:',
      'کۆدێکی ٤ ژمارەییمان نارد بۆ ژمارەی WhatsApp ـی خوارەوە:');
  static const forgotPasswordChangePhone =
      TString('تغيير الرقم', 'گۆڕینی ژمارە');
  static const forgotPasswordVerifyButton = TString('تحقق', 'پشتڕاستکردنەوە');
  static const forgotPasswordResendCode =
      TString('إعادة إرسال الرمز', 'دووبارە ناردنی کۆد');
  static const forgotPasswordResendInPrefix =
      TString('إعادة الإرسال خلال', 'دووبارە ناردن لە');
  static const forgotPasswordResendSecondsSuffix = TString('ث', 'چ');
  static const forgotPasswordCodeRequired =
      TString('يرجى إدخال الرمز كاملاً', 'تکایە کۆدەکە تەواو بنووسە');
  static const forgotPasswordCodeWrong =
      TString('الرمز غير صحيح', 'کۆدەکە دروست نییە');
  static const forgotPasswordResetTitle =
      TString('كلمة مرور جديدة', 'وشەی نهێنی نوێ');
  static const forgotPasswordResetSubtitle = TString(
      'تم التحقق بنجاح! اختر كلمة مرور جديدة.',
      'پشتڕاستکرایەوە! وشەیەکی نوێ بۆ خۆت هەڵبژێرە.');
  static const forgotPasswordNewPasswordLabel =
      TString('كلمة المرور الجديدة', 'وشەی نهێنی نوێ');
  static const forgotPasswordConfirmPasswordLabel =
      TString('تأكيد كلمة المرور', 'دووبارەکردنەوەی وشەی نهێنی');
  static const forgotPasswordPasswordTooShort = TString(
      'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'وشەی نهێنی دەبێت لانی کەم ٦ پیت بێت');
  static const forgotPasswordPasswordMismatch =
      TString('كلمتا المرور غير متطابقتين', 'وشەکانی نهێنی یەک ناگرنەوە');
  static const forgotPasswordResetButton =
      TString('تغيير كلمة المرور', 'گۆڕینی وشەی نهێنی');
  static const forgotPasswordResetSuccess = TString(
      'تم تغيير كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول.',
      'وشەی نهێنی بە سەرکەوتوویی گۆڕدرا. ئێستا دەتوانیت بچیتە ژوورەوە.');
  static const forgotPasswordResetFailed = TString(
      'فشل تغيير كلمة المرور. حاول مرة أخرى.',
      'گۆڕینی وشەی نهێنی سەرنەکەوت. تکایە دووبارە هەوڵ بدە.');
  static const forgotPasswordSessionExpired = TString(
      'انتهت صلاحية الجلسة. يرجى البدء من جديد.',
      'کاتی جلسەکە تەواو بوو. تکایە لە سەرەتاوە دەست پێبکەرەوە.');

  // ── App update prompt (UpdateService + showUpdateDialog) ──
  static const updateAvailableTitle =
      TString('تحديث متاح', 'نوێکردنەوە بەردەستە');
  static const updateAvailableMessage = TString(
      'يتوفر إصدار جديد من التطبيق. يُرجى التحديث للحصول على آخر المزايا والإصلاحات.',
      'وەشانێکی نوێی ئەپ بەردەستە. تکایە نوێی بکەرەوە بۆ بەدەستهێنانی تایبەتمەندی و چاکسازییەکانی نوێ.');
  static const updatePrompt = TString(
      'هل ترغب في التحديث الآن؟', 'دەتەوێت ئێستا نوێی بکەیتەوە؟');
  static const updateButtonNow = TString('تحديث الآن', 'ئێستا نوێی بکەرەوە');
  static const updateButtonLater = TString('لاحقاً', 'دواتر');

  // ── ViewUsersScreen ──────────────────────────────────────
  static const viewUsersDeletedSnack =
      TString('تم حذف المستخدم', 'بەکارهێنەر سڕاوە');
  static const viewUsersDeleteTitle =
      TString('حذف المستخدم', 'سڕینەوەی بەکارهێنەر');
  static const viewUsersDeleteContent = TString(
      'هل أنت متأكد من حذف هذا المستخدم؟',
      'دڵنیای کە دەیتە سڕینەوەی ئەم بەکارهێنەرە؟');
  static const viewUsersSearchHint =
      TString('ابحث حسب الاسم...', 'گەڕان بەپێی ناو...');
  static const viewUsersTabApprovedPrefix =
      TString('الموافق عليهم', 'پەسندکراوەکان');
  static const viewUsersTabNotApprovedPrefix =
      TString('غير الموافق عليهم', 'پەسندنەکراوەکان');
  static const viewUsersTabNewPrefix =
      TString('المستخدمين الجدد', 'بەکارهێنەری نوێ');
  static const viewUsersEmptyApproved =
      TString('لا يوجد مستخدمون موافق عليهم', 'هیچ بەکارهێنەر پەسندکراو نیە');
  static const viewUsersEmptyNotApproved = TString(
      'لا يوجد مستخدمون غير موافق عليهم', 'هیچ بەکارهێنەر پەسندنەکراو نیە');
  static const viewUsersEmptyNew =
      TString('لا يوجد مستخدمون جدد', 'هیچ بەکارهێنەری نوێ نیە');
  static const viewUsersNewBadge = TString('جديد', 'نوێ');
  static const viewUsersUnknownName =
      TString('اسم غير معروف', 'ناو نەدۆزرایەوە');
  static const viewUsersRowsLabel = TString('عدد الصفوف: ', 'ڕیز: ');
  static const viewUsersPageOfPrefix = TString('صفحة', 'پەڕە');
  static const viewUsersPageOfMid = TString('من', 'لە');

  // ── UsersPage (admin edit dialog) ────────────────────────
  static const usersPageLoadError =
      TString('خطأ في تحميل المستخدمين', 'هەڵە لە بارکردنی بەکارهێنەرەکان');
  static const usersPageEditTitle =
      TString('تعديل المستخدم', 'دەستکاری بەکارهێنەر');
  static const usersPageEnterName =
      TString('يرجى إدخال الاسم', 'تکایە ناو بنووسە');
  static const usersPagePhoneLabel = TString('رقم الهاتف', 'ژمارەی تەلەفون');
  static const usersPageEnterPhone =
      TString('يرجى إدخال رقم الهاتف', 'تکایە ژمارەی تەلەفون بنووسە');
  static const usersPagePasswordLabel = TString('كلمة المرور', 'وشەی تێپەڕەوە');
  static const usersPageEnterPassword =
      TString('يرجى إدخال كلمة المرور', 'تکایە وشەی تێپەڕەوە بنووسە');
  static const usersPageApprovedSwitch = TString('معتمد', 'پەسەندکراو');
  static const usersPageCancelButton = TString('إلغاء', 'هەڵبگرەوە');
  static const usersPageUpdateSuccess = TString(
      'تم تحديث المستخدم بنجاح', 'بەکارهێنەر بە سەرکەوتوویی نوێکرایەوە');
  static const usersPageGenericError = TString('حدث خطأ ما', 'هەڵەیەک ڕوویدا');
  static const usersPageSearchHint =
      TString('ابحث بالاسم أو رقم الهاتف', 'گەڕان بە ناو یان ژمارەی تەلەفون');
  static const usersPageEmpty =
      TString('لا يوجد مستخدمون', 'هیچ بەکارهێنەرێک نیە');
  static const usersPageApprovedBadge = TString('معتمد', 'پەسەندکراو');
  static const usersPageNotApprovedBadge = TString('غير معتمد', 'پەسەندنەکراو');

  // ── UserInfoPage ─────────────────────────────────────────
  static const userInfoTitle =
      TString('معلومات المستخدم', 'زانیاری بەکارھێنەر');
  static const userInfoErrorBody = TString(
      'خطأ: لم يتم العثور على المعلومات.', 'هەڵە: زانیاری نەدۆزرایەوە.');
  static const userInfoThanksTitle =
      TString('شكراً للتسجيل!', 'سوپاس بۆ تۆمارکردن!');
  static const userInfoSubtitle =
      TString('معلومات المستخدم:', 'زانیاری تایبەتی بەکارھێنەر:');
  static const userInfoFullNameLabel = TString('الاسم الكامل:', 'ناوی تەواو:');
  static const userInfoThankYouMessage = TString(
      'شكراً للتسجيل! سنتواصل معك قريباً لإنهاء عملك.',
      'سوپاس بۆ تۆمارکردن! ئێمە پەیوەندی پێوە دەکەین لە نزیکترین کاتدا.');
  static const userInfoAddMore =
      TString('إضافة المزيد من المعلومات', 'زیادکردنی زانیاری زیاتر');

  // ── UserDetailsPage (admin edit user) ───────────────────
  static const userDetailsTitle = TString('تفاصيل المستخدم', 'پەڕەی کەسی');
  static const userDetailsEditHeader =
      TString('تعديل بيانات المستخدم', 'گۆڕینی زانیاری بەکارهێنەر');
  static const userDetailsSubscriptionDate =
      TString('تاريخ الاشتراك', 'بەسەرچوونی');
  static const userDetailsPickDate = TString('اختر التاريخ', 'بەروار هەڵبژێرە');
  static const userDetailsUpdateSuccess = TString(
      'تم تحديث المعلومات بنجاح!', 'زانیاری بە سەرکەوتوویی نوێکرایەوە!');
  static const userDetailsApprovalLabel = TString('موافقة:', 'پەسندکراو:');

  // ── ProfileScreen ────────────────────────────────────────
  static const profileTitle = TString('الملف الشخصي', 'پەڕەی کەسی');
  static const profileFetchError = TString('حدث خطأ، يرجى المحاولة مرة أخرى.',
      'هەڵە ڕوویدا، تکایە دووبارە هەوڵ بدە.');
  static const profileInfoSection = TString('المعلومات', 'زانیاریەکان');
  static const profilePaymentLabel = TString('مبلغ الدفع', 'بڕی پارەدان');
  static const profileDinar = TString('دينار', 'دینار');
  static const profileActiveStatus = TString('حالة التفعيل', 'دۆخی چالاکی');
  static const profileActive = TString('مفعل', 'چالاکە');
  static const profileInactive = TString('غير مفعل', 'ناچالاکە');

  // ── WorkDetailsScreen ────────────────────────────────────
  static const workDetailsNoData = TString('لا توجد بيانات للمعرّف المُقدم.',
      'زانیاری بۆ ئەم ناسنامەیە نەدۆزرایەوە.');
  static const workDetailsLoadFailedAr =
      TString('فشل في تحميل التفاصيل.', 'زانیاریەکان بارنەکرا.');
  static const workDetailsLoadException = TString(
      'حدث خطأ أثناء تحميل التفاصيل.',
      'هەڵەیەک ڕوویدا لە بارکردنی زانیاریەکان.');
  static const workDetailsCannotOpenDialer =
      TString('لا يمكن فتح برنامج الاتصال.', 'نەشێ تەلەفۆنەکە بکرێتەوە.');
  static const workDetailsCannotOpenWhatsApp =
      TString('لا يمكن فتح WhatsApp.', 'نەشی پەیوەندی ب وتس ئاپ وی بەکەی.');
  static const workDetailsTitle = TString('صفحة التفاصيل', 'لاپەری زانیاری');
  static const workDetailsDescriptionTitle =
      TString('وصف المستخدم', 'دەربارەی بەکارهێنەری');
  static const workDetailsNoDescription =
      TString('لا يوجد وصف', 'دەربارەی نییە');
  static const workDetailsExtraInfoTitle =
      TString('معلومات إضافية', 'پێزانین زێدەتر');
  static const workDetailsNoExtraInfo =
      TString('لا توجد معلومات إضافية', 'زانیاری زێدە نییە');
  static const workDetailsImages = TString('الصور', 'وێنەکان');
  static const workDetailsRelated =
      TString('تفاصيل ذات صلة', 'پێزانینی پەیوەندیدار');
  static const workDetailsNoRelated =
      TString('لا يوجد تفاصيل ذات صلة.', 'هیچ پەیوەندیدارێک نەدۆزرایەوە.');
  static const workDetailsUnspecified = TString('غير محدد', 'نادیار');

  // ── WorkDetailsPage (list/search) ────────────────────────
  static const workListTitle = TString('تفاصيل العمل', 'زانیاری کاری');
  static const workListChooseSection = TString('اختر القسم', 'هەموو بەشان');
  static const workListAllSections = TString('جميع الأقسام', 'هەموو بەشان');
  static const workListAllCities = TString('جميع المدن', 'هەموو شارەکان');
  static const workListEmpty =
      TString('لم يتم العثور على معلومات', 'چ تشت بەر دەست نینن نوکە');
  // Suffix for the loaded-rows counter above the list ("120+ ئەنجام").
  static const workListResultsSuffix = TString('نتيجة', 'ئەنجام');

  // ── FormSearchWork ───────────────────────────────────────
  static const searchWorkLoadError = TString(
      'فشل تحميل البيانات. حاول مرة أخرى لاحقاً.',
      'زانیاریەکان بارنەکران. تکایە دووبارە هەوڵ بدە.');
  static const searchWorkAppBarTitle = TString('البحث عن عمل', 'زانیاری کار');
  static const searchWorkLoadingData =
      TString('جاري تحميل البيانات...', 'جارى باركردنى زانیاریەکان...');
  static const searchWorkAllSections = TString('جميع الأقسام', 'هەمی بەش');
  static const searchWorkNoSections =
      TString('لا توجد أقسام متاحة.', 'هیچ بەشی بەردەست نیە.');
  static const searchWorkNoData =
      TString('لا توجد بيانات متاحة.', 'هیچ زانیاریەکی بەردەست نیە.');

  // ── AddCategory ─────────────────────────────────────────
  static const addCategoryNameRequired =
      TString('يجب إدخال اسم الفئة.', 'ناڤێ کارێ گەلەک یێ پێدڤیە.');
  static const addCategoryConfirmTitle = TString('تأكيد', 'پشتڕاستکردنەوە');
  static const addCategoryConfirmContent =
      TString('هل أنت متأكد من حذف الفئة؟', 'دڵنیای ژێبرنا جۆرێ کارێ؟');
  static const addCategoryEditTitle =
      TString('تحديث الفئة', 'نویژەنکرنا جۆرێ کارێ');
  static const addCategoryEditNameLabel = TString('اسم الفئة', 'ناڤێ کارێ');
  static const addCategoryEditCancel = TString('إلغاء', 'پەشیمان بوون');
  static const addCategoryEditUpdate = TString('تحديث', 'نویژەنکرن');
  static const addCategoryTitle =
      TString('إضافة فئة جديدة', 'زێدەکرنا کارەکێ نوی');
  static const addCategoryNameHint = TString('اسم الفئة', 'ناڤێ جۆرێ کارێ');
  static const addCategoryAddButton = TString('إضافة', 'زیادکردن');
  static const addCategoryEmpty =
      TString('لم يتم العثور على فئة.', 'چ کار نەهاتنە دیتن');

  // ── AddSubCategory ──────────────────────────────────────
  static const addSubcategoryFieldsRequired = TString(
      'يجب اختيار الفئة واسم الفئة الفرعية.',
      'پۆل و ناڤێ ژێرپۆلێ گەلەک یێ پێدڤیە');
  static const addSubcategoryConfirmTitle = TString('تأكيد', 'پشتڕاستکرن');
  static const addSubcategoryConfirmContent =
      TString('هل أنت متأكد من حذف الفئة الفرعية؟', 'دڵنیای ژێبرنا ژێرپۆلێ؟');
  static const addSubcategoryEditTitle =
      TString('تحديث الفئة الفرعية', 'نویژەنکرنا ژێرپۆلێ');
  static const addSubcategoryEditNameLabel =
      TString('اسم الفئة الفرعية', 'ناڤێ ژێرپۆلێ');
  static const addSubcategoryEditCancel = TString('إلغاء', 'پەشیمان بوون');
  static const addSubcategoryEditUpdate = TString('تحديث', 'نویژەنکرن');
  static const addSubcategoryAddTitle =
      TString('إضافة فئة فرعية', 'زێدەکرنا ژێرپۆلێ نوی');
  static const addSubcategoryChooseCategoryHint =
      TString('اختر الفئة', 'پۆل هەڵبژێرە');
  static const addSubcategoryNameHint =
      TString('اسم الفئة الفرعية', 'ناڤێ ژێرپۆلێ');
  static const addSubcategoryAddButton = TString('إضافة', 'زێدەکرن');
  static const addSubcategoryEmpty =
      TString('لم يتم العثور على فئة.', 'چ پۆل نەهاتنە دیتن.');
  static const addSubcategoryHeroSubtitle = TString(
      'اختر الفئة، أدخل اسم الفئة الفرعية وأضف صورة لها.',
      'پۆلێ هەلبژێرە، ناڤێ ژێرپۆلێ بنڤیسە و وێنەیێ زیاد بکە.');
  static const addSubcategoryCategoryPrefix = TString('الفئة', 'پۆلی');
  static const addSubcategoryFormSection =
      TString('إضافة فئة فرعية', 'زێدەکرنا ژێرپۆلێ');
  static const addSubcategoryListSection =
      TString('الفئات الفرعية الحالية', 'ژێرپۆلێن بەردەست');

  // ── InsertDetailsPage (admin) ───────────────────────────
  static const insertDetailsMaxImages = TString(
      'الرجاء عدم اختيار أكثر من 3 صور', 'تکایە زیاتر لە ٣ وێنە نەهەڵبژێرە');
  static const insertDetailsImageRequired = TString(
      'يجب اختيار صورة واحدة على الأقل',
      'پێویستە بەلایەنی کەم یەک وێنە هەڵبژێردرێت');
  static const insertDetailsSuccess =
      TString('تم إضافة المعلومات بنجاح ✓', 'زانیاری بە سەرکەوتوویی زیادکرا ✓');
  static const insertDetailsTitle =
      TString('إضافة معلومات جديدة', 'زیادکردنی زانیاری نوێ');
  static const insertDetailsHeader =
      TString('إضافة معلومات', 'زیادکردنی زانیاری');
  static const insertDetailsSubcategoryLabel =
      TString('نوع الفئة الفرعية', 'جۆری ژێرپۆل');
  static const insertDetailsUserLabel = TString('المستخدم', 'بەکارهێنەر');
  static const insertDetailsNameLabel =
      TString('اسم المعلومات', 'ناوی زانیاری');
  static const insertDetailsContactLabel =
      TString('رقم الاتصال', 'ژمارەی پەیوەندیدان');
  static const insertDetailsContactRequired =
      TString('يجب كتابة الرقم', 'پێویستە ژمارەکە بنووسرێت');
  static const insertDetailsContactRange = TString(
      'يجب أن يكون الرقم بين 10 و 15 رقماً',
      'ژمارەکە دەبێت لانی کەم ١٠ ڕەقەم بێت');
  static const insertDetailsLocationLabel = TString('الموقع', 'شوێن');
  static const insertDetailsDescLabel = TString('الوصف', 'وەسف');
  static const insertDetailsDescRequired =
      TString('يجب كتابة الوصف', 'پێویستە وەسف بنووسرێت');
  static const insertDetailsDescMin = TString(
      'يجب أن يكون الوصف 10 حروف على الأقل',
      'پێویستە وەسف لانی کەم ١٠ پیت بێت');
  static const insertDetailsAdditional =
      TString('معلومات إضافية (اختياري)', 'زانیاری زیاتر (اختیاری)');
  static const insertDetailsAddButton = TString('إضافة', 'زیادکردن');
  static const insertDetailsActiveLabel = TString('هل هو نشط؟', 'ئایا چالاکە؟');
  static const insertDetailsAddImagesLabel =
      TString('أضف صور (بحد أقصى 3)', 'وێنە زیاد بکە (زۆرترین ٣)');
  static const insertDetailsImageRequiredAsterisk = TString(
      '* يجب اختيار صورة واحدة على الأقل',
      '* پێویستە بەلایەنی کەم یەک وێنە هەڵبژێردرێت');

  // ── InsertDetailsPageNo (user-facing) ───────────────────
  static const insertNoTitle =
      TString('إضافة معلوماتك', 'زانیاریەکانت زیاد بکە');
  static const insertNoBanner = TString(
      'يرجى ملء جميع المعلومات بدقة لكي يمكن للعملاء التواصل معك.',
      'تکایە هەموو زانیاریەکان بە دروستی پر بکەرەوە تا کڕیارەکان پەیوەندیت پێوە بکەن.');
  static const insertNoWorkType = TString('نوع العمل', 'جۆری کار');
  static const insertNoUserLabel = TString('المستخدم', 'بەکارهێنەر');
  static const insertNoUserRequired =
      TString('يجب تسجيل الدخول أولاً', 'پێویستە پێشتر بچیتە ژوورەوە');
  static const insertNoNameLabel =
      TString('اسم المعلومات / اسمك', 'ناوی زانیاری / ناوت');
  static const insertNoContactRequired =
      TString('هذا الحقل مطلوب', 'پێویستە ژمارەکە بنووسرێت');
  static const insertNoDescLabel = TString('وصف عملك', 'وەسفی کارەکەت');
  static const insertNoDescRequired =
      TString('هذا الحقل مطلوب', 'پێویستە وەسف بنووسرێت');
  static const insertNoSubmit = TString('إرسال', 'ناردن');
  static const insertNoAddImagesLabel = TString(
      'أضف صورة لعملك (بحد أقصى 3)', 'وێنەی کارەکەت زیاد بکە (زۆرترین ٣)');

  // ── UpdateDetailsPage ───────────────────────────────────
  static const updateDetailsImageDeleted =
      TString('تم حذف الصورة بنجاح', 'وێنەکە سڕایەوە');
  static const updateDetailsTitle =
      TString('تحديث المعلومات', 'نوێکردنەوەی زانیاری');
  static const updateDetailsSuccess =
      TString('تم تحديث المعلومات بنجاح', 'زانیاری بە سەرکەوتوویی نوێکرایەوە');
  static const updateDetailsAddPhotos = TString('أضف صوراً', 'وێنە زیاد بکە');
  static const updateDetailsActiveLabel =
      TString('هل هو مفعل؟', 'ئایا چالاکە؟');
  static const updateDetailsHeroSubtitle = TString(
      'حدّث بيانات هذا السجل والصور المرتبطة به.',
      'زانیاری ئەم تۆمارە و وێنەکانی نوێ بکەرەوە.');
  static const updateDetailsImagesSection = TString('الصور', 'وێنەکان');

  // ── SaveSuccessPage ─────────────────────────────────────
  static const saveSuccessAppBarTitle =
      TString('تم حفظ المعلومات بنجاح', 'زانیاری بە سەرکەوتوویی زیادکرا');
  static const saveSuccessTitle =
      TString('تم حفظ المعلومات بنجاح!', 'زانیاری بە سەرکەوتوویی زیادکرا!');
  static const saveSuccessBody = TString(
      'سنتواصل معك في أقرب وقت لإنهاء العملية.',
      'ئێمە پەیوەندی پێوە دەکەین لە نزیکترین کاتدا بۆ تەواوکردنی کارەکەت.');
  static const saveSuccessButton =
      TString('العودة إلى الصفحة الرئيسية', 'گەڕانەوە بۆ پەڕەی سەرەکی');

  // ── SelectDetailPage ────────────────────────────────────
  static const selectDetailEmpty = TString('لا توجد نتائج', 'هیچ دۆخێک نیە');
  static const selectDetailSearchHint =
      TString('ابحث بالاسم أو رقم الهاتف', 'گەران بە ناو یان ژمارە');
}
