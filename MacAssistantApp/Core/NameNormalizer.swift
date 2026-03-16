//
//  NameNormalizer.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation

struct NameNormalizer {

    static func normalizeApp(_ name: String) -> String {
        let lower = name.lowercased()

        let map: [String: String] = [
            "xcode": "Xcode",

            "discord": "Discord",

            "terminal": "Terminal",
            "mac terminal": "Terminal",

            "safari": "Safari",

            "chrome": "Google Chrome",
            "google chrome": "Google Chrome",

            "vscode": "Visual Studio Code",
            "vs code": "Visual Studio Code",
            "visual studio code": "Visual Studio Code",
            "code": "Visual Studio Code",

            "steam": "Steam",

            "spotify": "Spotify",

            "telegram": "Telegram",

            "obs": "OBS",

            "finder": "Finder",

            "minecraft": "Minecraft Launcher",
            "minecraft launcher": "Minecraft Launcher"
        ]

        for (alias, normalized) in map {
            if lower.contains(alias) {
                return normalized
            }
        }

        return name
    }

    static func normalizeWebsite(_ name: String) -> URL? {
        let lower = name.lowercased()

        let map: [String: String] = [
            "youtube": "https://www.youtube.com",
            "yt": "https://www.youtube.com",

            "github": "https://www.github.com",

            "google": "https://www.google.com",

            "gmail": "https://mail.google.com",

            "reddit": "https://www.reddit.com",

            "stackoverflow": "https://stackoverflow.com",

            "twitter": "https://x.com",
            "x": "https://x.com",

            "facebook": "https://www.facebook.com",

            "netflix": "https://www.netflix.com",

            "amazon": "https://www.amazon.com",

            "wikipedia": "https://www.wikipedia.org",

            "twitch": "https://www.twitch.tv",

            "linkedin": "https://www.linkedin.com",

            "duckduckgo": "https://duckduckgo.com",

            "yahoo": "https://www.yahoo.com",

            "bing": "https://www.bing.com",

            "chatgpt": "https://chatgpt.com",

            "notion": "https://www.notion.so",

            "apple developer": "https://developer.apple.com"
        ]

        for (alias, url) in map {
            if lower.contains(alias) {
                return URL(string: url)
            }
        }

        return nil
    }
}
