## Installation

1. Follow `Step 1` described in iOS SDK setup guide: [link](https://docs.reteno.com/reference/ios#step-1-add-the-notification-service-extension)


2. Modify your cocoapod file to contain next dependencies:
```

target 'NotificationServiceExtension' do
  pod 'Reteno', '1.3.0'
  pod 'Sentry', '7.28.0', :modular_headers => true

end

target 'RetenoSdkExample' do
  ...
  pod 'Reteno', '1.3.0'
  pod 'Sentry', '7.28.0', :modular_headers => true
end

```

3. Run next command from root of your project:

```sh
flutter pub add reteno_plugin 
```
4. Next step for iOS is to call `Reteno.start` inside of your `AppDelegate` file. If you have migrated to `AppDelegate.swift`, follow `Step 3` in iOS SDK setup guide: [link](https://docs.reteno.com/reference/ios#step-3-import-reteno-into-your-app-delegate)

5. Follow `Step 4` described in iOS SDK setup guide: [link](https://docs.reteno.com/reference/ios#step-4-add-app-groups)

6. Add `Push Notification` capability to your main app target (not `NotificationServiceExtension`!)l
