# App Store Review Notes

## App Store Connect - Review Notes

Please add the following note in App Store Connect when submitting for review:

---

**Review Notes:**

"All courses and tests are free. There are no purchases, subscriptions, or paid features. No In-App Purchase (IAP) is used. The app provides educational content completely free of charge to all users."

---

## Changes Made for Guideline 3.1.1 Compliance

The following changes were made to ensure full compliance with Apple's Guideline 3.1.1 (Payments – In-App Purchase):

### Removed Payment UI and Screens
- ✅ Deleted `purchase_test.dart` - payment page for tests
- ✅ Deleted `package_payment_page.dart` - payment page for courses
- ✅ Deleted `enroll_with_esewa_button.dart` - external payment button
- ✅ Deleted `payment_web_view.dart` - payment web view
- ✅ Deleted `checkout_page.dart` - checkout page
- ✅ Deleted `checkout_widget.dart` - checkout widget
- ✅ Updated `confirm_page.dart` to be a generic success page (no payment mention)

### Removed Payment Services and API Calls
- ✅ Deleted `simple_payment_service.dart`
- ✅ Deleted `test_access_service.dart`
- ✅ Removed `payments/initiate` and `payments/verify` endpoints from `api_endpoints.dart`
- ✅ Deleted entire `lib/core/iap/` folder (IAP controller, provider, paywall, entitlement store)

### Removed Price Displays from UI
- ✅ `home_course_card.dart` - removed price parameters, shows "Free" for all courses
- ✅ `grab_the_deal.dart` - removed price/discount logic, shows "Free" for all courses
- ✅ `available_test.dart` - always displays "Free" for all tests
- ✅ `select_course.dart` - shows "Free" instead of prices
- ✅ `enrolled_course_details_page.dart` - shows "Free" instead of enrollment cost
- ✅ `courses_tab.dart` - removed price-related parameters
- ✅ `recommended_course.dart` - removed price-related parameters

### Neutralized Data Models and API Fields
- ✅ `mock_test_models.dart` - `isFree`, `isPurchased`, `canTakeTest` always return `true`
- ✅ `exam_models.dart` - `isFree`, `isPurchased` always return `true`, `price` always `0`

### Removed Dependencies
- ✅ Removed `in_app_purchase` package from `pubspec.yaml`
- ✅ Removed `in_app_purchase_storekit` package from `pubspec.yaml`

### Export Files Updated
- ✅ `profile.dart` - removed checkout exports
- ✅ `test.dart` - removed purchase_test export

## Verification Checklist

- [x] No clickable buttons open external payment URLs
- [x] All tests and courses start/open without payment prompts
- [x] UI displays all content as "Free"
- [x] Content is identical for all users (guest or logged-in)
- [x] No IAP code remains in the app
- [x] No payment endpoints are called
- [x] No external payment gateway references (eSewa, Stripe, etc.)

## Date of Changes
March 13, 2026

