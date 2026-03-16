import Foundation

struct RuleBasedCommandParser {
    func parse(_ input: String) -> AssistantAction {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        guard !raw.isEmpty else { return .unknown }

        if let query = extractSearchQuery(from: raw, lower: lower), !query.isEmpty {
            return .searchGoogle(query: query)
        }

        if let url = extractWebsite(from: raw, lower: lower) {
            return .openWebsite(url: url)
        }

        if let appName = extractAppName(from: raw, lower: lower), !appName.isEmpty {
            return .openApp(name: appName)
        }

        return .unknown
    }

    private func extractSearchQuery(from raw: String, lower: String) -> String? {
        let triggers = [
            "buscar",
            "busca",
            "búscame",
            "buscame",
            "googlea",
            "necesito buscar",
            "quiero buscar",
            "quiero encontrar",
            "encuentra",
            "investiga",
            "abre google y busca",
            "abre google para buscar",
            "en google"
        ]

        guard triggers.contains(where: { lower.contains($0) }) else {
            return nil
        }

        var cleaned = raw
        for trigger in triggers {
            cleaned = cleaned.replacingOccurrences(
                of: trigger,
                with: "",
                options: .caseInsensitive
            )
        }

        cleaned = cleaned
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")

        return cleaned.isEmpty ? nil : cleaned
    }

    private func extractAppName(from raw: String, lower: String) -> String? {
        let prefixes = [
            "abre ",
            "abrir ",
            "open ",
            "inicia ",
            "ejecuta ",
            "lanza "
        ]

        let knownSites = [
            "youtube",
            "github",
            "google",
            "gmail",
            "reddit",
            "stackoverflow",
            "twitter",
            "facebook",
            "netflix",
            "amazon",
            "wikipedia",
            "google maps",
            "twitch",
            "linkedin",
            "duckduckgo",
            "yahoo",
            "bing",
            "apple developer",
            "chatgpt",
            "notion"
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let value = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !value.isEmpty else { return nil }

                if knownSites.contains(value.lowercased()) {
                    return nil
                }

                return value
            }
        }

        return nil
    }

    private func extractWebsite(from raw: String, lower: String) -> URL? {
        let knownSites: [String: String] = [
            "youtube": "https://www.youtube.com",
            "github": "https://www.github.com",
            "google": "https://www.google.com",
            "gmail": "https://mail.google.com",
            "reddit": "https://www.reddit.com",
            "stackoverflow": "https://stackoverflow.com",
            "twitter": "https://x.com",
            "facebook": "https://www.facebook.com",
            "netflix": "https://www.netflix.com",
            "amazon": "https://www.amazon.com",
            "wikipedia": "https://www.wikipedia.org",
            "google maps": "https://maps.google.com",
            "twitch": "https://www.twitch.tv",
            "linkedin": "https://www.linkedin.com",
            "duckduckgo": "https://duckduckgo.com",
            "yahoo": "https://www.yahoo.com",
            "bing": "https://www.bing.com",
            "apple developer": "https://developer.apple.com",
            "chatgpt": "https://chatgpt.com",
            "notion": "https://www.notion.so"
        ]

        for (key, value) in knownSites {
            if lower.contains(key) {
                return URL(string: value)
            }
        }

        return nil
    }
}
