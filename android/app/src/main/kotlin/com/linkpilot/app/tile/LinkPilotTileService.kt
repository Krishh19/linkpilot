package com.linkpilot.app.tile

import android.app.PendingIntent
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.widget.Toast
import com.linkpilot.app.R
import com.linkpilot.app.RouterActivity

class LinkPilotTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.let {
            it.state = Tile.STATE_INACTIVE
            it.label = getString(R.string.tile_open_copied_link)
            it.updateTile()
        }
    }

    override fun onClick() {
        super.onClick()

        // Read clipboard on explicit user tap only (FR-G2)
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
        val clip = clipboard?.primaryClip
        val text = if (clip != null && clip.itemCount > 0) {
            clip.getItemAt(0)?.coerceToText(this)?.toString()
        } else {
            null
        }

        val url = if (!text.isNullOrBlank()) {
            Regex("https?://[^\\s]+").find(text)?.value
        } else {
            null
        }

        if (url.isNullOrBlank()) {
            Toast.makeText(this, getString(R.string.no_link_on_clipboard), Toast.LENGTH_SHORT).show()
            return
        }

        val launchIntent = Intent(this, RouterActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(url)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(launchIntent)
        }
    }
}
