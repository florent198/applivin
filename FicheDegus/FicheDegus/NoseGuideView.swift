import SwiftUI

struct AromaFamily: Identifiable {
    let id = UUID()
    let name: String
    let items: [String]
}

struct AromaCategory: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let families: [AromaFamily]
}

struct NoseGuideView: View {
    private let categories: [AromaCategory] = [
        AromaCategory(
            title: "Arômes primaires",
            description: "Issus directement du raisin, ils expriment le cépage et le terroir.",
            families: [
                AromaFamily(name: "Floral", items: ["acacia", "aubépine", "œillet", "jasmin", "fleur d’oranger", "rose", "lilas", "genêt", "tilleul", "violette", "pivoine", "camomille", "bruyère"]),
                AromaFamily(name: "Fruits", items: ["citron", "orange", "pamplemousse", "ananas", "banane", "litchi", "melon", "muscat", "pomme", "poire", "coing", "fraise", "framboise", "groseille", "cassis", "myrtille", "mûre", "cerise", "abricot", "pêche"]),
                AromaFamily(name: "Végétal", items: ["foin coupé", "poivron", "bourgeon de cassis", "fougère"]),
                AromaFamily(name: "Minéral (perçu)", items: ["pierre à fusil", "craie", "iodé", "silex"])
            ]
        ),
        AromaCategory(
            title: "Arômes secondaires",
            description: "Nés pendant la fermentation et l’élevage sur lies.",
            families: [
                AromaFamily(name: "Lacté & fermentaire", items: ["levure", "mie de pain", "brioche", "beurre", "lait", "cake", "biscuit", "lie de vin"]),
                AromaFamily(name: "Fruit fermentaire", items: ["banane (si très marquée)"])
            ]
        ),
        AromaCategory(
            title: "Arômes tertiaires",
            description: "Arômes d’évolution liés au vieillissement et/ou à l’élevage.",
            families: [
                AromaFamily(name: "Épices", items: ["poivre", "vanille", "cannelle", "clou de girofle", "safran"]),
                AromaFamily(name: "Empyreumatique", items: ["cacao", "café", "caramel", "tabac", "fumé", "pain grillé", "amande grillée"]),
                AromaFamily(name: "Animal", items: ["cuir", "musc", "gibier", "fourrure"]),
                AromaFamily(name: "Végétal évolué", items: ["champignon", "truffe", "thym", "laurier", "pin", "cèdre", "réglisse"]),
                AromaFamily(name: "Fruits évolués / secs", items: ["amande", "pruneau", "noix"]),
                AromaFamily(name: "Minéral évolué", items: ["graphite", "tourbe", "soufre"]),
                AromaFamily(name: "Floral évolué", items: ["miel"])
            ]
        )
    ]

    private let appreciationItems: [(title: String, values: String)] = [
        ("Style oxydatif", "Oui / Non"),
        ("Finesse aromatique", "Ordinaire / Fin / Élégant / Raffiné"),
        ("Expression aromatique", "Faible / Discret / Expressif / Intense")
    ]

    private let chipColumns = [
        GridItem(.adaptive(minimum: 92), spacing: 8, alignment: .leading)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(categories) { category in
                    AromaCategoryCard(category: category, chipColumns: chipColumns)
                }

                appreciationSection
            }
            .padding(20)
        }
        .navigationTitle("Nez")
    }

    private var appreciationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appréciation du nez")
                .font(.headline)
            Text("Ces critères décrivent la perception globale du nez. Ils ne correspondent pas à des familles d’arômes.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(appreciationItems, id: \.title) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                    Text(item.values)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AromaCategoryCard: View {
    let category: AromaCategory
    let chipColumns: [GridItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(category.title)
                .font(.headline)
            Text(category.description)
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(category.families) { family in
                VStack(alignment: .leading, spacing: 8) {
                    Text(family.name)
                        .font(.subheadline.weight(.semibold))
                    LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                        ForEach(family.items, id: \.self) { item in
                            AromaChip(text: item)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AromaChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

#Preview("Nez - Light") {
    NavigationStack {
        NoseGuideView()
    }
    .preferredColorScheme(.light)
}

#Preview("Nez - Dark") {
    NavigationStack {
        NoseGuideView()
    }
    .preferredColorScheme(.dark)
}
