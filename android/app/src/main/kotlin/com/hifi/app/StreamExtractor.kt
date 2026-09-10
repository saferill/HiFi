package com.hifi.app

import android.util.Log
import okhttp3.OkHttpClient
import okhttp3.RequestBody.Companion.toRequestBody
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.stream.StreamInfo
import java.io.IOException
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

class OkHttpDownloader(private val client: OkHttpClient) : Downloader() {
    companion object {
        fun create(): OkHttpDownloader {
            val client = OkHttpClient.Builder()
                .connectTimeout(20, TimeUnit.SECONDS)
                .readTimeout(20, TimeUnit.SECONDS)
                .followRedirects(true)
                .followSslRedirects(true)
                .build()
            return OkHttpDownloader(client)
        }
    }

    @Throws(IOException::class)
    override fun execute(request: Request): Response {
        val httpMethod = request.httpMethod()
        val url = request.url()
        val headers = request.headers()
        val dataToSend = request.dataToSend()

        val okRequestBuilder = okhttp3.Request.Builder().url(url)

        var hasUserAgent = false
        var hasAcceptLanguage = false
        var hasCookie = false

        headers?.forEach { (key, values) ->
            if (key.equals("User-Agent", ignoreCase = true)) hasUserAgent = true
            if (key.equals("Accept-Language", ignoreCase = true)) hasAcceptLanguage = true
            if (key.equals("Cookie", ignoreCase = true)) hasCookie = true
            values.forEach { value ->
                okRequestBuilder.addHeader(key, value)
            }
        }

        if (!hasUserAgent) {
            okRequestBuilder.header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36")
        }
        if (!hasAcceptLanguage) {
            okRequestBuilder.header("Accept-Language", "en-US,en;q=0.9")
        }
        if (!hasCookie) {
            okRequestBuilder.header("Cookie", "CONSENT=YES+1; SOCS=CAI")
        }

        val requestBody = if (httpMethod == "POST" || httpMethod == "PUT") {
            (dataToSend ?: ByteArray(0)).toRequestBody()
        } else null

        okRequestBuilder.method(httpMethod, requestBody)

        val okCall = client.newCall(okRequestBuilder.build())
        val okResponse = okCall.execute()

        val responseBody = okResponse.body?.string() ?: ""
        val responseHeaders = okResponse.headers.toMultimap()

        return Response(
            okResponse.code,
            okResponse.message,
            responseHeaders,
            responseBody,
            okResponse.request.url.toString()
        )
    }
}

object StreamExtractor {
    private const val TAG = "StreamExtractor"
    private val isInitialized = AtomicBoolean(false)

    fun initNewPipe() {
        if (isInitialized.compareAndSet(false, true)) {
            try {
                NewPipe.init(OkHttpDownloader.create())
                Log.d(TAG, "NewPipe initialized successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error initializing NewPipe", e)
                isInitialized.set(false)
            }
        }
    }

    fun getAudioStreamUrl(videoId: String): String? {
        return try {
            initNewPipe()
            Log.d(TAG, "Fetching StreamInfo for videoId: $videoId")
            val streamUrl = "https://www.youtube.com/watch?v=$videoId"
            val streamInfo = StreamInfo.getInfo(ServiceList.YouTube, streamUrl)

            val audioStreams = streamInfo.audioStreams
            if (audioStreams.isNullOrEmpty()) {
                Log.w(TAG, "No audio streams found for videoId: $videoId")
                return null
            }

            // Sort by averageBitrate descending
            val bestAudioStream = audioStreams.maxByOrNull { it.averageBitrate }
            val url = bestAudioStream?.url ?: bestAudioStream?.content
            Log.d(TAG, "Found best audio stream for $videoId (bitrate: ${bestAudioStream?.averageBitrate}, format: ${bestAudioStream?.format}): $url")
            url
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting audio stream for $videoId", e)
            null
        }
    }
}
