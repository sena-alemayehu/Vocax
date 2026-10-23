package com.vocax.vocax

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Lets Vocax AI do what Android only allows through accessibility: back, home,
 * recents, notifications, screenshots, lock screen, scrolling, tapping text on
 * screen, typing, and switching Wi-Fi / Bluetooth / airplane mode (and other
 * quick-settings tiles).
 *
 * The user turns it on once in Settings > Accessibility. It only acts when
 * Vocax asks it to, after a voice command.
 */
class VocaxAccessibilityService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Nothing to do: Vocax acts only on request.
    }

    override fun onInterrupt() {}

    override fun onUnbind(intent: Intent?): Boolean {
        if (instance === this) instance = null
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        super.onDestroy()
    }

    /** back, home, recents, notifications, quick_settings, power, lock, screenshot */
    fun globalAction(name: String): Boolean {
        val action = when (name) {
            "back" -> GLOBAL_ACTION_BACK
            "home" -> GLOBAL_ACTION_HOME
            "recents" -> GLOBAL_ACTION_RECENTS
            "notifications" -> GLOBAL_ACTION_NOTIFICATIONS
            "quick_settings" -> GLOBAL_ACTION_QUICK_SETTINGS
            "power" -> GLOBAL_ACTION_POWER_DIALOG
            "lock" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) GLOBAL_ACTION_LOCK_SCREEN else return false
            "screenshot" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) GLOBAL_ACTION_TAKE_SCREENSHOT else return false
            else -> return false
        }
        return performGlobalAction(action)
    }

    /**
     * Scrolls the screen. [direction] is where you want to read: "down" shows
     * what is below (the finger moves up), "up" shows what is above, "left"
     * and "right" move sideways.
     */
    fun scroll(direction: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false

        val metrics = resources.displayMetrics
        val w = metrics.widthPixels.toFloat()
        val h = metrics.heightPixels.toFloat()
        val path = Path()

        when (direction) {
            "down" -> {
                path.moveTo(w / 2, h * 0.72f)
                path.lineTo(w / 2, h * 0.28f)
            }
            "up" -> {
                path.moveTo(w / 2, h * 0.28f)
                path.lineTo(w / 2, h * 0.72f)
            }
            "right" -> {
                path.moveTo(w * 0.8f, h / 2)
                path.lineTo(w * 0.2f, h / 2)
            }
            "left" -> {
                path.moveTo(w * 0.2f, h / 2)
                path.lineTo(w * 0.8f, h / 2)
            }
            else -> return false
        }

        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 350))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    /** Taps the first thing on screen whose text or description matches [text]. */
    fun clickText(text: String): Boolean {
        if (text.isBlank()) return false
        val root = rootInActiveWindow ?: return false

        for (node in root.findAccessibilityNodeInfosByText(text)) {
            if (clickNode(node)) return true
        }

        val byDescription = findByDescription(root, text.lowercase()) ?: return false
        return clickNode(byDescription)
    }

    /** Types [text] into the field that currently has the cursor. */
    fun typeText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val field = root.findFocus(AccessibilityNodeInfo.FOCUS_INPUT) ?: return false
        val args = Bundle()
        args.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        return field.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }

    /**
     * Opens the quick-settings panel, finds the tile whose name matches one of
     * [labels] (for example "Wi-Fi", "Internet"), switches it to [on] and
     * closes the panel again. [onDone] gets: done, already, notfound or failed.
     */
    fun toggleTile(labels: List<String>, on: Boolean, onDone: (String) -> Unit) {
        if (!performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)) {
            onDone("failed")
            return
        }
        findTileAttempt(labels.map { it.lowercase() }, on, 0, onDone)
    }

    private fun findTileAttempt(
        labels: List<String>,
        on: Boolean,
        attempt: Int,
        onDone: (String) -> Unit
    ) {
        val delay = if (attempt == 0) 900L else 600L
        handler.postDelayed({
            val root = rootInActiveWindow
            val tile = if (root != null) findTile(root, labels) else null

            if (tile == null) {
                if (attempt < 5) {
                    findTileAttempt(labels, on, attempt + 1, onDone)
                } else {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    onDone("notfound")
                }
            } else {
                val current = tileState(tile)
                if (current == on) {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    onDone("already")
                } else {
                    val clicked = clickNode(tile)
                    handler.postDelayed({ performGlobalAction(GLOBAL_ACTION_BACK) }, 700L)
                    onDone(if (clicked) "done" else "failed")
                }
            }
        }, delay)
    }

    private fun findTile(node: AccessibilityNodeInfo, labels: List<String>): AccessibilityNodeInfo? {
        val text = node.text?.toString()?.lowercase() ?: ""
        val description = node.contentDescription?.toString()?.lowercase() ?: ""
        if (labels.any { text.contains(it) || description.contains(it) }) return node

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findTile(child, labels)
            if (found != null) return found
        }
        return null
    }

    /** true = on, false = off, null = unknown. */
    private fun tileState(tile: AccessibilityNodeInfo): Boolean? {
        var node: AccessibilityNodeInfo? = tile
        while (node != null) {
            if (node.isCheckable) return node.isChecked
            if (node.isClickable) break
            node = node.parent
        }

        val target = node ?: tile
        val texts = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val state = target.stateDescription
            if (state != null) texts.add(state.toString())
        }
        val description = target.contentDescription
        if (description != null) texts.add(description.toString())
        val label = target.text
        if (label != null) texts.add(label.toString())

        for (text in texts) {
            val lower = text.lowercase()
            if (Regex("\\boff\\b").containsMatchIn(lower)) return false
            if (Regex("\\bon\\b").containsMatchIn(lower)) return true
        }
        return null
    }

    private fun findByDescription(node: AccessibilityNodeInfo, lower: String): AccessibilityNodeInfo? {
        val description = node.contentDescription?.toString()?.lowercase() ?: ""
        if (description.contains(lower)) return node

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findByDescription(child, lower)
            if (found != null) return found
        }
        return null
    }

    private fun clickNode(node: AccessibilityNodeInfo): Boolean {
        var current: AccessibilityNodeInfo? = node
        while (current != null) {
            if (current.isClickable) {
                return current.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            }
            current = current.parent
        }
        return false
    }

    companion object {
        @Volatile
        var instance: VocaxAccessibilityService? = null
    }
}
