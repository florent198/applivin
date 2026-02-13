import SwiftUI

struct SavedCardsView: View {
    @Environment(WineStore.self) private var store

    var body: some View {
        Group {
            if store.cards.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Aucune fiche sauvegardée")
                        .font(.headline)
                    Text("Lorsque vous enregistrerez des fiches, elles apparaîtront ici.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    NavigationLink("Créer une fiche") {
                        ContentView()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                    Spacer()
                }
                .padding()
            } else {
                List {
                    ForEach(store.cards) { card in
                        NavigationLink {
                            ContentView(existingCard: card)
                        } label: {
                            HStack(spacing: 12) {
                                // Use the in-memory uiImage if available, otherwise try the stored thumbnailData
                                if let img = card.uiImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else if let data = card.thumbnailData, let thumb = UIImage(data: data) {
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.blue.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay { Image(systemName: "wineglass.fill").foregroundStyle(.blue) }
                                }
                                VStack(alignment: .leading) {
                                    Text(card.name).font(.headline)
                                    Text("\(card.vintage) • \(card.appellation)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                HStack(spacing: 2) {
                                    ForEach(0..<min(5, max(0, card.rating)), id: \.self) { _ in
                                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                                    }
                                }
                            }
                        }
                    }
                    .onDelete(perform: store.delete)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Mes fiches")
    }
}

#Preview {
    NavigationStack { SavedCardsView() }
}
