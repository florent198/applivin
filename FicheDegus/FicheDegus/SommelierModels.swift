import Foundation

struct SommelierSuggestion: Identifiable, Equatable {
    let id = UUID()
    let wineName: String
    let explanation: String
    let foodPairings: [String]
    let serviceTip: String
}

struct SommelierSuggestionPayload: Decodable {
    let wineName: String
    let explanation: String
    let foodPairings: [String]
    let serviceTip: String

    func toSuggestion(defaultWineName: String) -> SommelierSuggestion {
        let normalizedName = wineName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = normalizedName.isEmpty ? defaultWineName : normalizedName
        let cleanedPairings = foodPairings
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return SommelierSuggestion(
            wineName: finalName,
            explanation: explanation.trimmingCharacters(in: .whitespacesAndNewlines),
            foodPairings: Array(cleanedPairings.prefix(6)),
            serviceTip: serviceTip.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
