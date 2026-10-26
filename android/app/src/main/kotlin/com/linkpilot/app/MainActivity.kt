package com.linkpilot.app

import com.linkpilot.app.pigeon.LinkPilotHostApi
import com.linkpilot.app.pigeon.LinkPilotHostApiImpl
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val apiImpl = LinkPilotHostApiImpl(applicationContext)
        LinkPilotHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, apiImpl)
    }
}
