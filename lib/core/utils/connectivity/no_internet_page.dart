// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// import '../../constant/app_colors.dart';
// import '../../widgets/text/custom_text.dart';
//
// final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
//   return Connectivity()
//       .onConnectivityChanged
//       .map((list) => list.isNotEmpty ? list.first : ConnectivityResult.none);
// });
//
// class NoInternetPage extends ConsumerWidget {
//   const NoInternetPage({Key? key}) : super(key: key);
//
//   void _tryAgain(BuildContext context) async {
//     var connectivityResult = await (Connectivity().checkConnectivity());
//     if (connectivityResult != ConnectivityResult.none) {
//       if (Navigator.of(context).canPop()) {
//         Navigator.of(context).pop();
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     ref.listen<AsyncValue<ConnectivityResult>>(connectivityProvider,
//         (_, state) {
//       // Automatically pop the page when internet is restored
//       state.whenData((value) {
//         if (value != ConnectivityResult.none) {
//           if (Navigator.of(context).canPop()) {
//             Navigator.of(context).pop();
//           }
//         }
//       });
//     });
//
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CText('You are not connected to the internet.'),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => _tryAgain(context),
//               child: const CText(
//                 'Try Again',
//                 type: TextType.bodyLarge,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
