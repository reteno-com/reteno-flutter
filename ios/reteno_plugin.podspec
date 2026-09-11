#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint reteno_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'reteno_plugin'
  s.version          = '0.0.1'
  s.summary          = 'The Reteno Flutter Plugin for Mobile Customer Engagement and Analytics solutions'
  s.description      = <<-DESC
The Reteno Flutter Plugin for Mobile Customer Engagement and Analytics solutions.
                       DESC
  s.homepage         = 'https://github.com/reteno-com/reteno-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Reteno' => 'support@reteno.com' }
  s.source           = { :path => '.' }
  s.source_files = 'reteno_plugin/Sources/reteno_plugin/**/*.swift'
  s.dependency 'Flutter'
  # Floor only, no ceiling: FlutterFire pins Firebase exactly on the CocoaPods path, and a
  # ceiling here would hard-conflict the day it pins a newer major. CocoaPods consumers can
  # still override via `$FirebaseSDKVersion` in their Podfile.
  s.dependency 'FirebaseMessaging', '>= 11.0'
  s.dependency 'Reteno', '2.7.4'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
