//
//  AssistantSocialParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

enum AssistantSocialIntent {
    case greeting
    case whatAreYou
    case whoCreatedYou
    case thanks
    case goodbye
    case howAreYou
    case unknown
}

struct AssistantSocialParser {
    func parse(_ input: String) -> AssistantSocialIntent {
        let lower = input.lowercased()

        if ["hola", "hola asistente", "buenas", "buenos días", "buenos dias", "hey", "que tal"].contains(where: { lower.contains($0) }) {
            return .greeting
        }

        if ["qué eres", "que eres", "qué tipo de asistente eres", "eres una ia", "eres un asistente"].contains(where: { lower.contains($0) }) {
            return .whatAreYou
        }

        if ["quién te creó", "quien te creo", "quién te hizo", "quien te hizo"].contains(where: { lower.contains($0) }) {
            return .whoCreatedYou
        }

        if ["gracias", "muchas gracias", "thanks"].contains(where: { lower.contains($0) }) {
            return .thanks
        }

        if ["adiós", "adios", "nos vemos", "bye", "hasta luego"].contains(where: { lower.contains($0) }) {
            return .goodbye
        }

        if ["cómo estás", "como estas", "qué tal estás", "que tal estas"].contains(where: { lower.contains($0) }) {
            return .howAreYou
        }

        return .unknown
    }
}
