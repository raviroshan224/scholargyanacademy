// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:olp/config/dependencies/notification/notification_list.dart';
// import 'package:olp/core/utils/connectivity/no_internet_page.dart';
// import '../../../features/auth/presentaion/pages/login_page.dart';
// import '../../../features/beforeauth/presentaion/pages/onboard_page.dart';
//
// class AppRouter {
//   static final GoRouter router = GoRouter(
//     routes: <RouteBase>[
//       GoRoute(
//         path: '/',
//         builder: (BuildContext context, GoRouterState state) {
//           return const OnboardingOLP();
//         },
//         routes: <RouteBase>[
//           // GoRoute(
//           //   path: 'course_screen', // Use relative paths
//           //   builder: (BuildContext context, GoRouterState state) {
//           //     return CourseSelectionScreen();
//           //   },
//           // ),
//           GoRoute(
//             path: 'no_internet_page', // Use relative paths
//             builder: (BuildContext context, GoRouterState state) {
//               return const NoInternetPage();
//             },
//           ),
//           // GoRoute(
//           //   path: 'course_home_page', // Use relative paths
//           //   builder: (BuildContext context, GoRouterState state) {
//           //     return CourseHomePage();
//           //   },
//           // ),
//           GoRoute(
//             path: 'login_page', // Use relative paths
//             builder: (BuildContext context, GoRouterState state) {
//               return const LoginScreen();
//             },
//           ),
//
//           GoRoute(
//             path: 'notifications',
//             builder: (context, state) {
//               // Access the notification data if available
//               final notificationData = state.extra as Map<String, dynamic>?;
//               return NotificationList(data: notificationData);
//             },
//           ),
//         ],
//       ),
//     ],
//   );
// }
