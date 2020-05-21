# Swift_Android_NativeWindow

## Usage

```swift
import Swift_Android_NativeWindow

let androidNativeWindow = AndroidNativeWindow.fromSurface(env, jsurface)

androidNativeWindow.setBuffersGeometry(width: width, height: height, format: LegacyFormat.WINDOW_FORMAT_RGBA_8888)

let returnFromBlock: SomeType = androidNativeWindow.acquire {
    var buffer: AndroidNativeWindow.Buffer = AndroidNativeWindow.Buffer()
    return $0.lock(&buffer, nil) { (window: AndroidNativeWindow, outBuffer: inout AndroidNativeWindow.Buffer, inOutDirtyBounds: inout AndroidNativeWindow.Rect?) in
        
        // draw sth here, eg using skia to draw sth here    
    
        // it will auto unlock here, because using defer internal !!!
    
        return SomeType_instance
    }
}

// auto release androidNativeWindow here !!!

```


**Compare to C++ version**

```cpp
extern "C"
JNIEXPORT void JNICALL
native_render(JNIEnv *env, jobject thiz, jobject jSurface,jint width,jint height) {
    ANativeWindow *nativeWindow = ANativeWindow_fromSurface(env,jSurface);
    ANativeWindow_setBuffersGeometry(nativeWindow,  width, height, WINDOW_FORMAT_RGBA_8888);
    ANativeWindow_Buffer *buffer = new ANativeWindow_Buffer();
    ANativeWindow_lock(nativeWindow,buffer,0);

    // draw sth here, eg using skia to draw sth here    

    ANativeWindow_unlockAndPost(nativeWindow);
}
```


