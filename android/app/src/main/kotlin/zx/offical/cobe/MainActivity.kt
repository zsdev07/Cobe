package zx.offical.cobe

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "zx.offical.cobe/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getExternalStoragePath" -> {
                        result.success(getExternalFilesDir(null)?.absolutePath)
                    }
                    "getRootPath" -> {
                        result.success(filesDir.absolutePath)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
