## Installation


1. Run next command from root of your project:

```sh
flutter pub add reteno_plugin 
```
2. Add mavenCentral repository in your project level `build.gradle`:
```groovy
buildscript { 
    repositories { 
        mavenCentral() 
    } 
... 
}
```
3. Also you may need to increase `minSdkVersion` in project level `build.gradle` to `26`, since `Reteno` uses this version as minimal;

## Setting up SDK

1. Follow `Step 1` described in Android SDK setup guide: [link](https://docs.reteno.com/reference/android-sdk-setup#step-1-make-sure-to-enable-androidx-in-your-gradleproperties-file);

2. Follow `Step 2` described in Android SDK setup guide: [link](https://docs.reteno.com/reference/android-sdk-setup#step-2-make-sure-to-add-comretenofcm-and-firebase-dependencies-in-buildgradle);

3. Edit your MainApplication class and provider API Access-Key at SDK initialization.

Below is sample code you can add to your application class which gets you started with `RetenoSDK`.

```kotlin
package [com.YOUR_PACKAGE];

import com.reteno.core.Reteno
import com.reteno.core.RetenoApplication
import com.reteno.core.RetenoImpl
import io.flutter.app.FlutterApplication

class CustomApplication : FlutterApplication(), RetenoApplication {
    override fun onCreate() {
        super.onCreate()
        retenoInstance = RetenoImpl(this, "630A66AF-C1D3-4F2A-ACC1-0D51C38D2B05")
    }

    private lateinit var retenoInstance: Reteno
    override fun getRetenoInstance(): Reteno {
        return retenoInstance
    }
}

```

4. Follow `Step 5` described in Android SDK setup guide: [link](https://docs.reteno.com/reference/android-sdk-setup#step-5-make-sure-to-set-up-your-firebase-application-for-firebase-cloud-messaging);
