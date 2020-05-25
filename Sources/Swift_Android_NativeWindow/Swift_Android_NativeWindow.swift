import CSwift_Android_NativeWindow
import Swift_FP

public enum AndroidNativeWindowError: Error {
    case LOCK_FAILURE(statusCode: Int32)
    case UNLOCK_FAILURE(statusCode: Int32)
}

public class AndroidNativeWindow: CustomStringConvertible, CustomDebugStringConvertible {

    public typealias Buffer = ANativeWindow_Buffer

    public typealias Rect = ARect

    public enum LegacyFormat: Int32 {
        /**
         * Corresponding formats:
         *   Vulkan: VK_FORMAT_R8G8B8A8_UNORM
         *   OpenGL ES: GL_RGBA8
         */
        case WINDOW_FORMAT_RGBA_8888 = 1

        /**
         * 32 bits per pixel, 8 bits per channel format where alpha values are
         * ignored (always opaque).
         * Corresponding formats:
         *   Vulkan: VK_FORMAT_R8G8B8A8_UNORM
         *   OpenGL ES: GL_RGB8
         */
        case WINDOW_FORMAT_RGBX_8888 = 2

        /**
         * Corresponding formats:
         *   Vulkan: VK_FORMAT_R8G8B8_UNORM
         *   OpenGL ES: GL_RGB8
         */
        case WINDOW_FORMAT_RGB_888 = 3

        /**
         * Corresponding formats:
         *   Vulkan: VK_FORMAT_R5G6B5_UNORM_PACK16
         *   OpenGL ES: GL_RGB565
         */
        case WINDOW_FORMAT_RGB_565 = 4


        public func toC() -> ANativeWindow_LegacyFormat {
            ANativeWindow_LegacyFormat(rawValue: UInt32(self.rawValue))
        }
    }

    let mHandle: OpaquePointer

    private init(_ handle: OpaquePointer) {
        mHandle = handle
    }

    deinit {
        release()
    }

    public var description: String {
        return "AndroidNativeWindow(mHandle: \(mHandle))"
    }

    public var debugDescription: String {
        return "AndroidNativeWindow(mHandle: \(mHandle))"
    }

    public func toC() -> UnsafeMutableRawPointer {
        return UnsafeMutableRawPointer(mHandle)
    }

    public static func fromSurface(env: UnsafeMutablePointer<JNIEnv?>!, jsurface: jobject) -> AndroidNativeWindow {
        return AndroidNativeWindow(ANativeWindow_fromSurface(env, jsurface)!)
    }

    /// __ANDROID_API__ >= 26,  Swift_Android_ToolChain support android-api-24 at least.
    /// so comment it.
    /* public func toSurface(env: UnsafeMutablePointer<JNIEnv?>!) -> jobject {
        return ANativeWindow_toSurface(env, mHandle)
    }*/

    public static func fromWindowPtr(_ ptr: UnsafeMutableRawPointer) -> AndroidNativeWindow {
        return AndroidNativeWindow(OpaquePointer(ptr)).acquire()
    }

    public static func fromWindowPtr(_ ptr: OpaquePointer) -> AndroidNativeWindow {
        return AndroidNativeWindow(ptr).acquire()
    }

    @discardableResult
    private func acquire() -> AndroidNativeWindow {
        ANativeWindow_acquire(mHandle)
        return self
    }

    private func release() {
        ANativeWindow_release(mHandle)
    }

    public func acquire<R>(_ block: (AndroidNativeWindow) throws -> R) throws -> R {
        acquire()
        defer {
            release()
        }

        return try block(self)
    }

    /**
     * Return the current width in pixels of the window surface.
     *
     * \return negative value on error.
     */
    public var width: Int32 {
        return ANativeWindow_getWidth(mHandle)
    }

    /**
     * Return the current height in pixels of the window surface.
     *
     * \return a negative value on error.
     */
    public var height: Int32 {
        return ANativeWindow_getHeight(mHandle)
    }

    /**
     * Return the current pixel format (AHARDWAREBUFFER_FORMAT_*) of the window surface.
     *
     * \return a negative value on error.
     *  \return a nil value on error.
     */
    public var format: LegacyFormat? {
        return LegacyFormat(rawValue: ANativeWindow_getFormat(mHandle))
    }

    /**
     * Change the format and size of the window buffers.
     *
     * The width and height control the number of pixels in the buffers, not the
     * dimensions of the window on screen. If these are different than the
     * window's physical size, then its buffer will be scaled to match that size
     * when compositing it to the screen. The width and height must be either both zero
     * or both non-zero.
     *
     * For all of these parameters, if 0 is supplied then the window's base
     * value will come back in force.
     *
     * \param width width of the buffers in pixels.
     * \param height height of the buffers in pixels.
     * \param format one of the AHardwareBuffer_Format constants.
     * \return 0 for success, or a negative value on error.
     */
    public func setBuffersGeometry(width: Int32, height: Int32, format: LegacyFormat) -> Int32 {
        return ANativeWindow_setBuffersGeometry(mHandle, width, height, format.rawValue)
    }

    /**
     * Lock the window's next drawing surface for writing.
     * inOutDirtyBounds is used as an in/out parameter, upon entering the
     * function, it contains the dirty region, that is, the region the caller
     * intends to redraw. When the function returns, inOutDirtyBounds is updated
     * with the actual area the caller needs to redraw -- this region is often
     * extended by {@link ANativeWindow_lock}.
     *
     * \return 0 for success, or a negative value on error.
     */
    private func lock(_ outBuffer: inout Buffer, _ inOutDirtyBounds: inout Rect?) -> Int32 {
        if var dirtyRect = inOutDirtyBounds {
            defer {
                inOutDirtyBounds = dirtyRect
            }
            return ANativeWindow_lock(mHandle, &outBuffer, &dirtyRect)
        } else {
            return ANativeWindow_lock(mHandle, &outBuffer, nil)
        }
    }

    /**
     * Unlock the window's drawing surface after previously locking it,
     * posting the new buffer to the display.
     *
     * \return 0 for success, or a negative value on error.
     */
    private func unlockAndPost() -> Int32 {
        return ANativeWindow_unlockAndPost(mHandle)
    }

    public func lock<R>(outBuffer: inout Buffer, inOutDirtyBounds: inout Rect?, _ block: (AndroidNativeWindow, inout Buffer, inout Rect?) throws -> R) throws -> R {
        let statusLock = lock(&outBuffer, &inOutDirtyBounds)
        /*defer {
            if statusLock >= 0 {
                let statusUnlock = unlockAndPost()
                guard statusUnlock >= 0 else {
                    throw AndroidNativeWindowError.UNLOCK_FAILURE(statusCode: statusUnlock)
                }
            }
        }*/

        guard statusLock >= 0 else {
            throw AndroidNativeWindowError.LOCK_FAILURE(statusCode: statusLock)
        }

        let unlock = { (statusLock: Int32) throws -> Void in
            if statusLock >= 0 {
                let statusUnlock = self.unlockAndPost()
                guard statusUnlock >= 0 else {
                    throw AndroidNativeWindowError.UNLOCK_FAILURE(statusCode: statusUnlock)
                }
            }
        }

        return try Result {
            try block(self, &outBuffer, &inOutDirtyBounds)
        }.doFinally {
            try unlock(statusLock)
        }.get()
    }
}