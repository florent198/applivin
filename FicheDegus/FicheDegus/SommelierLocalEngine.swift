import Foundation

private enum WineStyle {
    case redLight
    case redFull
    case whiteDry
    case whiteRich
    case aromatic
    case rose
    case sparkling
    case sweet
    case unknown
}

enum SommelierLocalEngine {
    static func suggest(from card: WineCard) -> SommelierSuggestion {
        let sourceText = [card.name, card.appellation, card.grapes, card.notes]
            .joined(separator: " ")
            .lowercased()
        let style = detectStyle(from: sourceText, isRed: card.isRouge, isWhite: card.isBlanc, isRose: card.isRose)
        return buildSuggestion(name: card.name, style: style)
    }

    static func suggest(fromQuery query: String) -> SommelierSuggestion {
        let style = detectStyle(from: query.lowercased(), isRed: false, isWhite: false, isRose: false)
        return buildSuggestion(name: query, style: style)
    }

    private static func detectStyle(from text: String, isRed: Bool, isWhite: Bool, isRose: Bool) -> WineStyle {
        if isRose || text.contains("rosé") || text.contains("rose") { return .rose }
        if text.contains("champagne") || text.contains("crémant") || text.contains("prosecco") { return .sparkling }
        if text.contains("sauternes") || text.contains("moelleux") || text.contains("liquoreux") {
            return .sweet
        }

        if isRed {
            if text.contains("pinot noir") || text.contains("gamay") { return .redLight }
            return .redFull
        }
        if isWhite {
            if text.contains("chardonnay") || text.contains("viognier") || text.contains("meursault") {
                return .whiteRich
            }
            if text.contains("riesling") || text.contains("gewurztraminer") || text.contains("muscat") {
                return .aromatic
            }
            return .whiteDry
        }

        if text.contains("pinot noir") || text.contains("gamay") || text.contains("valpolicella") {
            return .redLight
        }
        if text.contains("cabernet") || text.contains("syrah") || text.contains("malbec") || text.contains("merlot") || text.contains("bordeaux") {
            return .redFull
        }
        if text.contains("chardonnay") || text.contains("viognier") || text.contains("bourgogne blanc") {
            return .whiteRich
        }
        if text.contains("sauvignon") || text.contains("chablis") || text.contains("muscadet") || text.contains("sancerre") {
            return .whiteDry
        }
        if text.contains("riesling") || text.contains("gewurztraminer") || text.contains("pinot gris") {
            return .aromatic
        }

        return .unknown
    }

    private static func buildSuggestion(name: String, style: WineStyle) -> SommelierSuggestion {
        switch style {
        case .redLight:
            return SommelierSuggestion(
                wineName: name,
                explanation: "Style rouge léger et fruité, idéal avec des plats délicats.",
                foodPairings: [
                    "Volaille rôtie et jus réduit",
                    "Saumon grillé ou thon mi-cuit",
                    "Tarte aux champignons",
                    "Fromages à pâte molle"
                ],
                serviceTip: "Service conseillé entre 14°C et 16°C."
            )
        case .redFull:
            return SommelierSuggestion(
                wineName: name,
                explanation: "Style rouge structuré, parfait sur des plats riches.",
                foodPairings: [
                    "Entrecôte grillée",
                    "Agneau rôti aux herbes",
                    "Boeuf bourguignon",
                    "Fromages affinés"
                ],
                serviceTip: "Service conseillé entre 16°C et 18°C."
            )
        case .whiteDry:
            return SommelierSuggestion(
                wineName: name,
                explanation: "Blanc sec et vif, excellent sur les plats iodés et frais.",
                foodPairings: [
                    "Huîtres et fruits de mer",
                    "Poisson vapeur citronné",
                    "Salade de chèvre chaud",
                    "Sushis et sashimis"
                ],
                serviceTip: "Service conseillé entre 8°C et 10°C."
            )
        case .whiteRich:
            return SommelierSuggestion(
                wineName: name,
                explanation: "Blanc ample et gourmand, adapté aux plats crémeux.",
                foodPairings: [
                    "Poulet à la crème",
                    "Risotto aux champignons",
                    "Saint-Jacques poêlées",
                    "Comté jeune"
                ],
                serviceTip: "Service conseillé entre 10°C et 12°C."
            )
        case .aromatic:
            return SommelierSuggestion(
                wineName: name,
                explanation: "Profil aromatique expressif, très intéressant avec les épices.",
                foodPairings: [
                    "Cuisine thaï douce",
                    "Curry de légumes",
                    "Poulet tandoori",
                    "Fromages persillés"
                ],
                serviceTip: "Service conseillé entre 9°C et 11°C."
            )
        case .rose:
            return SommelierSuggestion(
                wineName: name,
                explanation: "Rosé frais et polyvalent, parfait pour la cuisine d'été.",
                foodPairings: [
                    "Tapas et antipasti",
                    "Salade niçoise",
                    "Grillades de poisson",
                    "Cuisine méditerranéenne"
                ],
                serviceTip: "Service conseillé entre 8°C et 10°C."
            )
        case .sparkling:
            return SommelierSuggestion(
                wineName: name,
                explanation: "Bulles fines et tension, idéal de l'apéritif au dessert léger.",
                foodPairings: [
                    "Apéritif salin",
                    "Tempura de crevettes",
                    "Parmesan et gougères",
                    "Dessert aux fruits blancs"
                ],
                serviceTip: "Service conseillé entre 6°C et 8°C."
            )
        case .sweet:
            return SommelierSuggestion(
                wineName: name,
                explanation: "Vin doux, superbe contraste avec le salé et harmonie sur le sucré.",
                foodPairings: [
                    "Foie gras",
                    "Roquefort",
                    "Tarte aux fruits",
                    "Desserts à base d'abricot"
                ],
                serviceTip: "Service conseillé entre 8°C et 10°C."
            )
        case .unknown:
            return SommelierSuggestion(
                wineName: name,
                explanation: "Profil général: accords polyvalents quand le style n'est pas identifié.",
                foodPairings: [
                    "Poulet rôti",
                    "Pâtes aux légumes grillés",
                    "Planche de charcuterie douce",
                    "Fromages à pâte pressée"
                ],
                serviceTip: "Servez selon le type: blanc frais, rouge légèrement chambré."
            )
        }
    }
}
