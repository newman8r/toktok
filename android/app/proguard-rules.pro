-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}

# Suppress specific tags
-assumenosideeffects class * {
    static void IMGGralloc(...);
    static void MediaCodec(...);
    static void BufferPoolAccessor(...);
    static void Surface(...);
} 