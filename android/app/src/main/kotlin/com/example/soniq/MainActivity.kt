package com.example.soniq

import android.content.Intent
import android.media.audiofx.Equalizer
import kotlin.math.ln
import kotlin.math.roundToInt
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var equalizer: Equalizer? = null
    private var session: Int? = null
    private val frequencies = listOf(60.0, 230.0, 910.0, 3600.0, 14000.0)

    private fun attach(id: Int?): Boolean {
        if (id == session && equalizer != null) return true
        equalizer?.release()
        equalizer = null
        session = null
        if (id == null || id <= 0) return false
        val effect = Equalizer(0, id)
        equalizer = effect
        session = id
        return true
    }

    private fun levelAt(levels: List<Double>, frequency: Double): Double {
        if (frequency <= frequencies.first()) return levels.first()
        if (frequency >= frequencies.last()) return levels.last()
        val i = (0 until frequencies.lastIndex).first { frequency <= frequencies[it + 1] }
        val t = ln(frequency / frequencies[i]) / ln(frequencies[i + 1] / frequencies[i])
        return levels[i] + (levels[i + 1] - levels[i]) * t
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "soniq/native").setMethodCallHandler { call, result ->
            when (call.method) {
                "eqAttach" -> {
                    try { result.success(attach(call.arguments as? Int)) }
                    catch (e: Exception) { result.error("EQ_ATTACH", e.message, null) }
                }
                "eqApply" -> {
                    try {
                        val effect = equalizer ?: error("Sessão indisponível")
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val levels = call.argument<List<Double>>("levels") ?: error("Bandas ausentes")
                        require(levels.size == 5)
                        val bass = call.argument<Boolean>("bassBoost") ?: false
                        val strength = call.argument<Double>("bassStrength") ?: 0.0
                        val range = effect.bandLevelRange
                        if (enabled) {
                            for (i in 0 until effect.numberOfBands.toInt()) {
                                val band = i.toShort()
                                val hz = effect.getCenterFreq(band) / 1000.0
                                var gain = (levelAt(levels, hz) - 0.5) * 3000.0
                                if (bass && hz <= 250) gain += strength * 900 * (if (hz <= 120) 1.0 else 0.55)
                                effect.setBandLevel(band, gain.roundToInt().coerceIn(range[0].toInt(), range[1].toInt()).toShort())
                            }
                        }
                        val status = effect.setEnabled(enabled)
                        check(status == 0) { "Efeito recusado: $status" }
                        result.success(null)
                    } catch (e: Exception) { result.error("EQ_APPLY", e.message, null) }
                }
                "share" -> {
                    val text = call.arguments as? String
                    if (text == null) { result.error("INVALID", "Texto ausente", null); return@setMethodCallHandler }
                    val intent = Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, text) }
                    startActivity(Intent.createChooser(intent, "Compartilhar música"))
                    result.success(null)
                }
                "filesDir" -> result.success(filesDir.absolutePath)
                else -> result.notImplemented()
            }
        }
    }
}
