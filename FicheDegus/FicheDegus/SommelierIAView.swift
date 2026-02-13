import SwiftUI

struct SommelierIAView: View {
    @Environment(WineStore.self) private var store
    @AppStorage("openai_api_key") private var openAIKey = ""

    @State private var savedSuggestions: [SommelierSuggestion] = []
    @State private var query = ""
    @State private var searchedSuggestion: SommelierSuggestion? = nil
    @State private var hasSearched = false
    @State private var isAnalyzing = false
    @State private var isSearching = false
    @State private var infoMessage: String? = nil

    private var normalizedAPIKey: String {
        openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasAPIKey: Bool {
        !normalizedAPIKey.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configuration IA")
                        .font(.title2).bold()
                    SecureField("Clé API OpenAI (sk-...)", text: $openAIKey)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    Text("La clé est stockée localement sur cet appareil.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let infoMessage {
                    Text(infoMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Text("Analyse de vos fiches")
                    .font(.title2).bold()

                if store.cards.isEmpty {
                    ContentUnavailableView(
                        "Aucune fiche sauvegardée",
                        systemImage: "tray",
                        description: Text("Créez une fiche pour obtenir des suggestions d'accords mets et vins.")
                    )
                } else {
                    Button {
                        analyzeSavedCards()
                    } label: {
                        Label("Analyser mes fiches", systemImage: "wand.and.stars")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAnalyzing)

                    if isAnalyzing {
                        ProgressView("Analyse IA en cours...")
                    }

                    ForEach(savedSuggestions) { suggestion in
                        SommelierSuggestionCard(suggestion: suggestion)
                    }
                }

                Divider()

                Text("Recherche de vin")
                    .font(.title2).bold()

                Text("Tapez un vin, une appellation ou un cépage pour obtenir des accords.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    TextField("Ex: Chablis, Pinot Noir, Sancerre", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            searchWine()
                        }

                    Button("Trouver") {
                        searchWine()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSearching)
                }

                if isSearching {
                    ProgressView("Recherche IA en cours...")
                }

                if hasSearched {
                    if let searchedSuggestion {
                        SommelierSuggestionCard(suggestion: searchedSuggestion)
                    } else {
                        ContentUnavailableView(
                            "Aucun résultat",
                            systemImage: "magnifyingglass",
                            description: Text("Essayez avec un autre nom de vin, une appellation ou un cépage.")
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Sommelier IA")
        .onAppear {
            analyzeSavedCards()
        }
        .onChange(of: store.cards) { _, _ in
            analyzeSavedCards()
        }
    }

    private func analyzeSavedCards() {
        Task {
            await analyzeSavedCardsAsync()
        }
    }

    @MainActor
    private func analyzeSavedCardsAsync() async {
        let cards = Array(
            store.cards
                .sorted { $0.rating > $1.rating }
                .prefix(8)
        )

        guard !cards.isEmpty else {
            savedSuggestions = []
            return
        }

        isAnalyzing = true
        infoMessage = nil

        var results: [SommelierSuggestion] = []
        var hadAPIError = false

        if hasAPIKey {
            for card in cards {
                let context = """
                Vin: \(card.name)
                Millésime: \(card.vintage)
                Appellation: \(card.appellation)
                Cépages: \(card.grapes)
                Notes de dégustation: \(card.notes)
                Type: \(card.isRouge ? "Rouge" : card.isBlanc ? "Blanc" : card.isRose ? "Rosé" : "Non précisé")

                Propose un accord mets-vins pertinent.
                """

                do {
                    let suggestion = try await OpenAISommelierService.shared.suggest(
                        for: context,
                        fallbackWineName: card.name,
                        apiKey: normalizedAPIKey
                    )
                    results.append(suggestion)
                } catch {
                    hadAPIError = true
                    results.append(SommelierLocalEngine.suggest(from: card))
                }
            }
        } else {
            results = cards.map { SommelierLocalEngine.suggest(from: $0) }
        }

        savedSuggestions = results
        isAnalyzing = false

        if !hasAPIKey {
            infoMessage = "Ajoutez votre clé API OpenAI pour activer la vraie IA. Fallback local utilisé."
        } else if hadAPIError {
            infoMessage = "Certaines réponses IA ont échoué. Fallback local appliqué sur les fiches concernées."
        }
    }

    private func searchWine() {
        Task {
            await searchWineAsync()
        }
    }

    @MainActor
    private func searchWineAsync() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        hasSearched = true
        infoMessage = nil

        guard !trimmed.isEmpty else {
            searchedSuggestion = nil
            return
        }

        isSearching = true

        if hasAPIKey {
            let context = "Trouve un accord mets-vins pour: \(trimmed)"
            do {
                let result = try await OpenAISommelierService.shared.suggest(
                    for: context,
                    fallbackWineName: trimmed,
                    apiKey: normalizedAPIKey
                )
                searchedSuggestion = result
            } catch {
                searchedSuggestion = SommelierLocalEngine.suggest(fromQuery: trimmed)
                infoMessage = "Erreur IA sur la recherche. Fallback local utilisé."
            }
        } else {
            searchedSuggestion = SommelierLocalEngine.suggest(fromQuery: trimmed)
            infoMessage = "Ajoutez votre clé API OpenAI pour activer la vraie IA. Fallback local utilisé."
        }

        isSearching = false
    }
}

private struct SommelierSuggestionCard: View {
    let suggestion: SommelierSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(suggestion.wineName)
                .font(.headline)

            Text(suggestion.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(suggestion.foodPairings, id: \.self) { pairing in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.green)
                    Text(pairing)
                }
            }

            if !suggestion.serviceTip.isEmpty {
                Label(suggestion.serviceTip, systemImage: "thermometer.medium")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        SommelierIAView()
            .environment(WineStore())
    }
}
