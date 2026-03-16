//
//  AssistantPersonaResponder.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct AssistantPersonaResponder {
    let assistantName: String?

    func respond(to intent: AssistantSocialIntent) -> String? {
        let namePart = assistantName ?? "tu asistente"

        switch intent {
        case .greeting:
            if let assistantName {
                return "Hola. Soy \(assistantName). ¿Qué necesitas?"
            } else {
                return "Hola. Aún no me has puesto nombre, pero ya estoy listo para ayudarte."
            }

        case .whatAreYou:
            if let assistantName {
                return "Soy \(assistantName), tu asistente de desarrollo. Puedo conversar contigo y también ejecutar acciones como abrir apps, manejar memoria y correr workflows."
            } else {
                return "Soy tu asistente de desarrollo. Puedo conversar contigo y también ejecutar acciones como abrir apps, manejar memoria y correr workflows."
            }

        case .whoCreatedYou:
            return "Me estás construyendo tú dentro de esta app. Yo soy la parte que responde, organiza acciones y te ayuda a interactuar con el sistema."

        case .thanks:
            return "De nada. \(assistantName != nil ? "Aquí sigo." : "Aquí estoy por si quieres seguir.")"

        case .goodbye:
            return "Nos vemos. \(namePart.capitalized) se queda listo por si vuelves."

        case .howAreYou:
            return "Estoy bien y atento. ¿Qué quieres hacer ahora?"

        case .unknown:
            return nil
        }
    }

    func respondToNameQuestion() -> String {
        if let assistantName {
            return "Me llamo \(assistantName)."
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
}
