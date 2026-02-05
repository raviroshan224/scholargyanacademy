#!/bin/bash

export LC_ALL=en_US.UTF-8
sdk_project_path=`pwd`

flutter pub get
cd example/ios
arch -x86_64 pod update  --repo-update

cd $sdk_project_path/example
flutter build apk
flutter build ios --simulator --no-codesign

cd $sdk_project_path

package_name="flutter-zoom-video-sdk-${VERSION}"

mkdir -p ./output
mkdir -p ./output/$package_name
mkdir -p ./output/$package_name/ios
mkdir -p ./output/$package_name/android
mkdir -p ./output/$package_name/example
mkdir -p ./output/$package_name/lib
mkdir -p ./output/$package_name/example/android
mkdir -p ./output/$package_name/example/ios
mkdir -p ./output/$package_name/example/lib
mkdir -p ./output/$package_name/example/assets

package_path=./output/$package_name

cp -r ./ios $package_path/
cp -r ./android $package_path/
cp -r ./lib $package_path/
cp -r ./example/android $package_path/example/
cp -r ./example/lib $package_path/example/
cp -r ./example/assets $package_path/example/
cp -r ./example/ios/Flutter $package_path/example/ios
cp -r ./example/ios/Runner $package_path/example/ios
cp -r ./example/ios/Runner.xcodeproj $package_path/example/ios
cp -r ./example/ios/Runner.xcworkspace $package_path/example/ios
cp -r ./example/ios/ScreenShare $package_path/example/ios
cp -r ./example/ios/Podfile $package_path/example/ios
cp -r ./example/analysis_options.yaml $package_path/example
cp -r ./example/pubspec.yaml $package_path/example
cp -r ./example/README.md $package_path/example
cp -r ./analysis_options.yaml $package_path
cp -r ./pubspec.yaml $package_path
cp -r ./README.md $package_path
cp -r ./CHANGELOG.md $package_path
cp -r ./LICENSE $package_path
rm -rf $package_path/example/android/gradle/verification-metadata.xml
rm -rf $package_path/android/gradle/verification-metadata.xml

touch ./output/$package_name/version.txt
echo 'v'${VERSION} >> ./output/$package_name/version.txt

cd $sdk_project_path/output
zip -r ./$package_name.zip ./$package_name