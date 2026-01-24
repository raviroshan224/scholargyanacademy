// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// class ImagePickerWidget extends StatelessWidget {
//   //1 if camera, 2 if gallery
//   // final Function(String) onImagePick;
//   // 1 if camera, 2 if gallery
//   final Function(List<String>) onImagePick;
//
//   const ImagePickerWidget({
//     super.key,
//     required this.onImagePick,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     print("I am image picker");
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(
//             height: 16,
//           ),
//           const Text('Pick a image'),
//           ListTile(
//             onTap: () async {
//               Navigator.of(context).pop();
//               final XFile? value = await ImagePicker()
//                   .pickImage(source: ImageSource.camera, imageQuality: 50);
//
//               if (value != null) {
//                 onImagePick([value.path]);
//               }
//             },
//             leading: const Icon(Icons.camera),
//             title: const Text('Camera'),
//           ),
//           ListTile(
//             onTap: () async {
//               Navigator.of(context).pop();
//
//               final values =
//                   await ImagePicker().pickMultiImage(imageQuality: 50);
//
//               if (values.isNotEmpty) {
//                 List<String> imagePaths =
//                     values.map((value) => value.path).toList();
//                 onImagePick(imagePaths);
//               }
//
//               // if (value != null) {
//               //   onImagePick(value.path);
//               // }
//             },
//             leading: const Icon(Icons.photo),
//             title: const Text('Gallery'),
//           ),
//           const SizedBox(
//             height: 16,
//           ),
//         ],
//       ),
//     );
//   }
// }
