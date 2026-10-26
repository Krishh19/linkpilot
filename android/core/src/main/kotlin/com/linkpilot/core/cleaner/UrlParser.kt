package com.linkpilot.core.cleaner

import java.net.IDN
import java.net.URI
import java.net.URLDecoder
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

data class QueryParam(val key: String, val value: String?)

data class ParsedUrl(
    val scheme: String,          // lowercase, http or https
    val rawHost: String,        // original host (e.g. "München.de")
    val asciiHost: String,      // punycode/ascii lowercase (e.g. "xn--mnchen-3ya.de")
    val port: Int,              // -1 if default
    val path: String,           // starts with "/", or empty
    val queryParams: List<QueryParam>,
    val fragment: String?       // without "#"
) {
    /**
     * Reconstructs the URL string with the given query parameters.
     */
    fun buildUrl(newParams: List<QueryParam> = queryParams): String {
        val sb = StringBuilder()
        sb.append(scheme).append("://").append(rawHost)
        if (port != -1 && !isDefaultPort(scheme, port)) {
            sb.append(":").append(port)
        }
        if (path.isNotEmpty()) {
            if (!path.startsWith("/")) sb.append("/")
            sb.append(path)
        } else if (newParams.isNotEmpty() || fragment != null) {
            sb.append("/")
        }

        if (newParams.isNotEmpty()) {
            sb.append("?")
            val queryString = newParams.joinToString("&") { param ->
                val encodedKey = encodeComponent(param.key)
                if (param.value != null) {
                    encodedKey + "=" + encodeComponent(param.value)
                } else {
                    encodedKey
                }
            }
            sb.append(queryString)
        }

        if (fragment != null) {
            sb.append("#").append(fragment)
        }

        return sb.toString()
    }

    private fun isDefaultPort(scheme: String, port: Int): Boolean {
        return (scheme == "http" && port == 80) || (scheme == "https" && port == 443)
    }

    private fun encodeComponent(value: String): String {
        return URLEncoder.encode(value, StandardCharsets.UTF_8.name())
            .replace("+", "%20")
    }

    companion object {
        private const val MAX_URL_LENGTH = 8192

        fun parse(url: String): ParsedUrl? {
            val trimmed = url.trim()
            if (trimmed.length > MAX_URL_LENGTH || trimmed.isEmpty()) {
                return null
            }

            // Quick scheme check
            val schemeIndex = trimmed.indexOf("://")
            if (schemeIndex <= 0) return null
            val scheme = trimmed.substring(0, schemeIndex).lowercase()
            if (scheme != "http" && scheme != "https") {
                return null
            }

            return try {
                val uri = URI(trimmed)
                val rawHost = uri.host ?: extractHostFallback(trimmed.substring(schemeIndex + 3)) ?: return null
                val asciiHost = normalizeHost(rawHost)
                val port = uri.port
                val path = uri.rawPath ?: ""
                val fragment = uri.rawFragment

                val query = uri.rawQuery
                val params = parseQueryParams(query)

                ParsedUrl(
                    scheme = scheme,
                    rawHost = rawHost,
                    asciiHost = asciiHost,
                    port = port,
                    path = path,
                    queryParams = params,
                    fragment = fragment
                )
            } catch (_: Exception) {
                // Fallback manual parsing for slightly lenient handling of real-world unescaped chars
                parseManual(trimmed, scheme)
            }
        }

        fun normalizeHost(host: String): String {
            val lower = host.trim().lowercase()
            return try {
                IDN.toASCII(lower)
            } catch (_: Exception) {
                lower
            }
        }

        private fun extractHostFallback(afterScheme: String): String? {
            val endHost = afterScheme.indexOfFirst { it == '/' || it == '?' || it == '#' || it == ':' }
            val hostPart = if (endHost == -1) afterScheme else afterScheme.substring(0, endHost)
            return hostPart.takeIf { it.isNotBlank() }
        }

        private fun parseQueryParams(rawQuery: String?): List<QueryParam> {
            if (rawQuery.isNullOrEmpty()) return emptyList()
            val result = mutableListOf<QueryParam>()
            val pairs = rawQuery.split("&")
            for (pair in pairs) {
                if (pair.isEmpty()) continue
                val eqIdx = pair.indexOf("=")
                if (eqIdx == -1) {
                    val key = decode(pair)
                    result.add(QueryParam(key, null))
                } else {
                    val key = decode(pair.substring(0, eqIdx))
                    val value = decode(pair.substring(eqIdx + 1))
                    result.add(QueryParam(key, value))
                }
            }
            return result
        }

        private fun decode(s: String): String {
            return try {
                URLDecoder.decode(s, StandardCharsets.UTF_8.name())
            } catch (_: Exception) {
                s
            }
        }

        private fun parseManual(url: String, scheme: String): ParsedUrl? {
            return try {
                val afterScheme = url.substring(scheme.length + 3)
                var hostPart = afterScheme
                var path = ""
                var query: String? = null
                var fragment: String? = null

                val hashIdx = hostPart.indexOf('#')
                if (hashIdx != -1) {
                    fragment = hostPart.substring(hashIdx + 1)
                    hostPart = hostPart.substring(0, hashIdx)
                }

                val qIdx = hostPart.indexOf('?')
                if (qIdx != -1) {
                    query = hostPart.substring(qIdx + 1)
                    hostPart = hostPart.substring(0, qIdx)
                }

                val slashIdx = hostPart.indexOf('/')
                if (slashIdx != -1) {
                    path = hostPart.substring(slashIdx)
                    hostPart = hostPart.substring(0, slashIdx)
                }

                var port = -1
                val colonIdx = hostPart.indexOf(':')
                val rawHost = if (colonIdx != -1) {
                    port = hostPart.substring(colonIdx + 1).toIntOrNull() ?: -1
                    hostPart.substring(0, colonIdx)
                } else {
                    hostPart
                }

                if (rawHost.isBlank()) return null
                val asciiHost = normalizeHost(rawHost)
                val params = parseQueryParams(query)

                ParsedUrl(
                    scheme = scheme,
                    rawHost = rawHost,
                    asciiHost = asciiHost,
                    port = port,
                    path = path,
                    queryParams = params,
                    fragment = fragment
                )
            } catch (_: Exception) {
                null
            }
        }
    }
}
