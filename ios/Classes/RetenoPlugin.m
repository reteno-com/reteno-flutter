#import "RetenoPlugin.h"
#if __has_include(<reteno_plugin/reteno_plugin-Swift.h>)
#import <reteno_plugin/reteno_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "reteno_plugin-Swift.h"
#endif

@implementation RetenoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftRetenoPlugin registerWithRegistrar:registrar];
}
@end
