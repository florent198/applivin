import SwiftUI

struct GustativeGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("👄 Examen gustatif (Bouche)")
                    .font(.title2.weight(.bold))

                Text("L’examen gustatif permet d’évaluer les sensations en bouche et l’harmonie générale du vin.\nIl se concentre sur l’équilibre, la structure, la persistance aromatique et le stade d’évolution.")
                    .font(.body)

                GustativeSectionView(
                    title: "⚖️ Équilibre",
                    description: "Il décrit la relation entre les principaux composants du vin (alcool, acidité, sucres, tanins).",
                    bullets: [
                        "Déséquilibré : agressif, trop acide, trop sucré, mou",
                        "Vif ou structuré : sec, corsé, robuste",
                        "Harmonieux : équilibré, velouté, souple"
                    ],
                    keyMessage: "👉 Un bon vin donne une sensation d’harmonie sans qu’un élément ne domine."
                )

                GustativeSectionView(
                    title: "🧱 Structure",
                    description: "Elle correspond à la matière et à la densité du vin en bouche.",
                    bullets: [
                        "Légère : fluet, svelte",
                        "Moyenne : équilibré",
                        "Puissante : corpulent, massif, énorme"
                    ],
                    keyMessage: "👉 La structure influence la sensation de volume et la capacité de garde."
                )

                GustativeSectionView(
                    title: "⏳ Persistance aromatique (Longueur en bouche ou Caudalie)",
                    description: "Elle mesure la durée des arômes après avoir avalé ou recraché le vin.",
                    bullets: [
                        "Faible : 1 à 2 secondes",
                        "Moyenne : 3 à 5 secondes",
                        "Forte : 6 à 8 secondes",
                        "Très forte : 9 secondes et plus"
                    ],
                    keyMessage: "👉 Plus la persistance est longue, plus le vin est généralement qualitatif."
                )

                GustativeSectionView(
                    title: "🍷 Apogée",
                    description: "Elle indique le stade d’évolution du vin.",
                    bullets: [
                        "Trop jeune",
                        "À son apogée",
                        "En déclin"
                    ],
                    keyMessage: "👉 Aide à savoir si le vin peut encore évoluer ou s’il doit être bu rapidement."
                )

                GustativeFinalSectionView()
            }
            .padding(20)
        }
        .navigationTitle("Gustatif")
    }
}

private struct GustativeSectionView: View {
    let title: String
    let description: String
    let bullets: [String]
    let keyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            Text(description)
                .font(.footnote)
                .foregroundStyle(.secondary)

            BulletListView(items: bullets)

            Text(keyMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct GustativeFinalSectionView: View {
    private let recapItems = ["l’équilibre", "la puissance", "la longueur", "la maturité du vin"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🧠 À retenir")
                .font(.headline)

            BulletListView(items: recapItems)

            Text("👉 C’est l’étape clé pour apprécier réellement la qualité et le potentiel d’un vin.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct BulletListView: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.body)
                        .accessibilityHidden(true)
                    Text(item)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Gustatif - Light") {
    NavigationStack {
        GustativeGuideView()
    }
    .preferredColorScheme(.light)
}

#Preview("Gustatif - Dark") {
    NavigationStack {
        GustativeGuideView()
    }
    .preferredColorScheme(.dark)
}
