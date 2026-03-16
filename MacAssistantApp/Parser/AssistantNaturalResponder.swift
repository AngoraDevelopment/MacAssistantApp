//
//  AssistantNaturalResponder.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct AssistantNaturalResponder {
    let style: AssistantResponseStyle

    private var assistantName: String? {
        style.assistantName
    }

    private var namePrefix: String {
        guard style.wasInvokedByName, let assistantName else { return "" }
        return "\(assistantName) aquí. "
    }

    private var nameLabel: String {
        assistantName ?? "tu asistente"
    }

    func respond(to intent: AssistantSocialIntent) -> String? {
        switch intent {
        case .greeting:
            return greetingResponse()

        case .whatAreYou:
            return whatAreYouResponse()

        case .whoCreatedYou:
            return whoCreatedYouResponse()

        case .thanks:
            return thanksResponse()

        case .goodbye:
            return goodbyeResponse()

        case .howAreYou:
            return howAreYouResponse()

        case .unknown:
            return nil
        }
    }

    func respondToNameQuestion() -> String {
        if let assistantName {
            return "\(namePrefix)Me llamo \(assistantName)."
        } else {
            return "Todavía no me has puesto nombre. Cuando quieras, puedes asignarme uno una sola vez."
        }
    }

    func respondToNameSetSuccess(_ name: String) -> String {
        return "Perfecto. Desde ahora me llamaré \(name), y ese nombre quedará fijo."
    }

    func respondToNameSetRejected(currentName: String?) -> String {
        if let currentName {
            return "No puedo cambiar de nombre. Ya me llamo \(currentName) y ese nombre quedó bloqueado."
        } else {
            return "No pude guardar ese nombre."
        }
    }

    func personalizeExecutionMessage(_ text: String) -> String {
        guard style.wasInvokedByName, let assistantName else { return text }
        return "\(assistantName): \(text)"
    }

    func capabilitiesResponse() -> String {
        let base = "Puedo abrir apps, abrir carpetas, buscar en Google, recordar aliases, gestionar memoria, ejecutar workflows y responder preguntas sobre mis funciones."
        return namePrefix + base
    }

    func memoryHelpResponse() -> String {
        let base = "Puedes guardar aliases escribiendo algo como: recuerda que proyecto = ~/Desktop/ProyectoIA. También puedes hacerlo desde el panel de memoria."
        return namePrefix + base
    }

    func workflowHelpResponse() -> String {
        let base = "Puedes crear workflows desde la interfaz visual. Un workflow es una rutina con varios comandos que ejecuto en orden."
        return namePrefix + base
    }

    func commandsHelpResponse() -> String {
        let base = "Entiendo comandos como abrir apps, abrir carpetas, crear carpetas, guardar aliases, listar memoria, crear workflows y ejecutarlos."
        return namePrefix + base
    }

    func responseForOnlyNameInvocation() -> String {
        if let assistantName {
            return "Sí, aquí estoy. Soy \(assistantName)."
        } else {
            return "Aquí estoy."
        }
    }

    private func greetingResponse() -> String {
        if let assistantName {
            if style.wasInvokedByName {
                return "\(assistantName) aquí. ¿Qué necesitas?"
            } else {
                return "Hola. Soy \(assistantName). ¿Qué necesitas?"
            }
        } else {
            return "Hola. Aún no me has puesto nombre, pero ya estoy listo para ayudarte."
        }
    }

    private func whatAreYouResponse() -> String {
        let base = "Soy \(nameLabel), tu asistente para Mac. Puedo conversar contigo y también ejecutar acciones como abrir apps, manejar memoria y correr workflows."
        return namePrefix + base
    }

    private func whoCreatedYouResponse() -> String {
        let variants = [
            "Me estás construyendo tú dentro de esta app. Yo soy la parte que responde, organiza acciones y te ayuda a interactuar con el sistema.",
            "Tú me estás armando dentro de tu app. Yo soy el asistente que conversa contigo y conecta el chat con las funciones del sistema.",
            "Me estás creando tú como parte de este proyecto. Mi trabajo es responderte y ayudarte a controlar funciones del asistente."
        ]

        return namePrefix + pick(variants)
    }

    private func thanksResponse() -> String {
        let variants: [String]

        if let assistantName {
            variants = [
                "De nada. \(assistantName) sigue atento.",
                "Con gusto. Aquí sigo.",
                "Listo. Avísame si quieres hacer otra cosa."
            ]
        } else {
            variants = [
                "De nada. Aquí estoy por si quieres seguir.",
                "Con gusto. Seguimos cuando quieras.",
                "Listo. Dime qué más necesitas."
            ]
        }

        return namePrefix + pick(variants)
    }

    private func goodbyeResponse() -> String {
        let variants = [
            "Nos vemos. \(nameLabel.capitalized) se queda listo por si vuelves.",
            "Hasta luego. Aquí me quedo por si me necesitas después.",
            "Nos vemos. Cuando quieras seguimos."
        ]

        return namePrefix + pick(variants)
    }

    private func howAreYouResponse() -> String {
        let variants = [
            "Estoy bien y atento. ¿Qué quieres hacer ahora?",
            "Todo en orden. Dime qué necesitas.",
            "Estoy listo. ¿Con qué seguimos?"
        ]

        return namePrefix + pick(variants)
    }

    private func pick(_ items: [String]) -> String {
        guard !items.isEmpty else { return "" }
        let index = Int.random(in: 0..<items.count)
        return items[index]
    }
}
