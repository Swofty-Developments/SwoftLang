package net.swofty.nativebridge;

public final class NativeBridge {
    private NativeBridge() {
    } // no instances

    public static native void printFromNative(String message);

    // Helper method to check if the native library is loaded
    public static boolean isNativeLibraryLoaded() {
        try {
            // Try calling a simple native method
            printFromNative("");
            return true;
        } catch (UnsatisfiedLinkError e) {
            return false;
        }
    }
}
