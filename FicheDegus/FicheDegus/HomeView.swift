import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(WineStore.self) private var store
    @StateObject private var viewModel: HomeViewModel
    @State private var showCreate = false
    @State private var showSaved = false
    @State private var showVisual = false
    @State private var showNose = false
    @State private var showGustative = false

    let onCreateTapped: (() -> Void)?
    let onSavedTapped: (() -> Void)?

    init(
        viewModel: HomeViewModel = HomeViewModel(),
        onCreateTapped: (() -> Void)? = nil,
        onSavedTapped: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onCreateTapped = onCreateTapped
        self.onSavedTapped = onSavedTapped
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                cardsSection
                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationDestination(isPresented: $showCreate) { ContentView() }
            .navigationDestination(isPresented: $showSaved) { SavedCardsView() }
            .navigationDestination(isPresented: $showVisual) { VisualGuideView() }
            .navigationDestination(isPresented: $showNose) { NoseGuideView() }
            .navigationDestination(isPresented: $showGustative) { GustativeGuideView() }
            .onAppear {
                syncSavedCount()
            }
            .onChange(of: store.cards) { _, _ in
                syncSavedCount()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("Bienvenue")
                    .font(.largeTitle.bold())
                Image(systemName: "wineglass.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
            }

            Text("Que souhaitez-vous faire aujourd’hui ?")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var cardsSection: some View {
        VStack(spacing: 16) {
            ActionCard(
                iconName: "plus.circle.fill",
                title: "Créer une fiche",
                subtitle: "Créer une nouvelle fiche en quelques secondes",
                isPrimary: true
            ) {
                if let onCreateTapped {
                    onCreateTapped()
                } else {
                    showCreate = true
                }
            }

            ActionCard(
                iconName: "folder.fill",
                title: "Reprendre une fiche",
                subtitle: viewModel.savedSubtitle,
                isPrimary: false
            ) {
                if let onSavedTapped {
                    onSavedTapped()
                } else {
                    showSaved = true
                }
            }
            
            tastingMethodSection
        }
    }

    private var tastingMethodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Méthode de dégustation")
                    .font(.title3.bold())
                Text("Observer, sentir, goûter")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ActionCard(
                iconName: "eye.fill",
                title: "Visuel",
                subtitle: "Repères couleur & intensité",
                isPrimary: false
            ) {
                showVisual = true
            }
            .padding(.leading, 0)

            ActionCard(
                iconName: noseIconName,
                title: "Nez",
                subtitle: "Arômes primaires, secondaires, tertiaires",
                isPrimary: false
            ) {
                showNose = true
            }
            .padding(.leading, 16)

            ActionCard(
                iconName: gustativeIconName,
                title: "Gustatif",
                subtitle: "Examen en bouche du vin",
                isPrimary: false
            ) {
                showGustative = true
            }
            .padding(.leading, 32)
        }
    }

    private var noseIconName: String {
        if UIImage(systemName: "nose") != nil {
            return "nose"
        }
        if UIImage(systemName: "nose.fill") != nil {
            return "nose.fill"
        }
        return "face.smiling"
    }

    private var gustativeIconName: String {
        if UIImage(systemName: "mouth.fill") != nil {
            return "mouth.fill"
        }
        if UIImage(systemName: "mouth") != nil {
            return "mouth"
        }
        if UIImage(systemName: "lips") != nil {
            return "lips"
        }
        return "face.smiling"
    }

    private func syncSavedCount() {
        viewModel.savedCount = store.cards.count
    }
}

#Preview("savedCount = 0") {
    HomeView(viewModel: HomeViewModel(savedCount: 0))
        .environment(WineStore())
        .preferredColorScheme(.light)
}

#Preview("savedCount = 1") {
    let store = WineStore()
    store.cards = [WineCard(name: "Vin test", vintage: "2022", appellation: "Bordeaux")]
    return HomeView(viewModel: HomeViewModel(savedCount: 1))
        .environment(store)
        .preferredColorScheme(.dark)
}

#Preview("savedCount = 2") {
    let store = WineStore()
    store.cards = [
        WineCard(name: "Vin test 1", vintage: "2022", appellation: "Bordeaux"),
        WineCard(name: "Vin test 2", vintage: "2021", appellation: "Sancerre")
    ]
    return HomeView(viewModel: HomeViewModel(savedCount: 2))
        .environment(store)
        .preferredColorScheme(.dark)
}
