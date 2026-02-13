import SwiftUI
import UIKit

struct ColorItem: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

struct VisualGuideView: View {
    private let intensites = ["Claire", "Moyenne", "Soutenue", "Foncée", "Profonde"]
    private let limpidites = ["Cristalline", "Brillante", "Scintillante", "Voilée"]
    private let textColumns = [
        GridItem(.flexible(minimum: 120), spacing: 12, alignment: .leading),
        GridItem(.flexible(minimum: 120), spacing: 12, alignment: .leading)
    ]

    // Progression claire -> évoluée
    private let whites: [ColorItem] = [
        ColorItem(name: "Jaune pâle", color: Color(.sRGB, red: 0.92, green: 0.88, blue: 0.67, opacity: 1)),
        ColorItem(name: "Jaune citron", color: Color(.sRGB, red: 0.96, green: 0.84, blue: 0.33, opacity: 1)),
        ColorItem(name: "Jaune paille", color: Color(.sRGB, red: 0.95, green: 0.82, blue: 0.25, opacity: 1)),
        ColorItem(name: "Or pâle", color: Color(.sRGB, red: 0.91, green: 0.77, blue: 0.29, opacity: 1)),
        ColorItem(name: "Or", color: Color(.sRGB, red: 0.87, green: 0.68, blue: 0.03, opacity: 1)),
        ColorItem(name: "Vieil or", color: Color(.sRGB, red: 0.84, green: 0.58, blue: 0.08, opacity: 1)),
        ColorItem(name: "Ambré", color: Color(.sRGB, red: 0.94, green: 0.56, blue: 0.07, opacity: 1))
    ]

    // Progression clair -> soutenu/orangé
    private let roses: [ColorItem] = [
        ColorItem(name: "Pâle", color: Color(.sRGB, red: 0.97, green: 0.88, blue: 0.84, opacity: 1)),
        ColorItem(name: "Pétale de rose", color: Color(.sRGB, red: 0.94, green: 0.77, blue: 0.79, opacity: 1)),
        ColorItem(name: "Pelure d’oignon", color: Color(.sRGB, red: 0.89, green: 0.68, blue: 0.56, opacity: 1)),
        ColorItem(name: "Orangé", color: Color(.sRGB, red: 0.94, green: 0.56, blue: 0.11, opacity: 1)),
        ColorItem(name: "Cuivré", color: Color(.sRGB, red: 0.82, green: 0.50, blue: 0.07, opacity: 1))
    ]

    // Progression jeune -> évolué
    private let reds: [ColorItem] = [
        ColorItem(name: "Pourpre", color: Color(.sRGB, red: 0.75, green: 0.00, blue: 0.34, opacity: 1)),
        ColorItem(name: "Violet", color: Color(.sRGB, red: 0.70, green: 0.00, blue: 0.50, opacity: 1)),
        ColorItem(name: "Grenat", color: Color(.sRGB, red: 0.54, green: 0.16, blue: 0.38, opacity: 1)),
        ColorItem(name: "Cerise", color: Color(.sRGB, red: 0.97, green: 0.00, blue: 0.19, opacity: 1)),
        ColorItem(name: "Rubis", color: Color(.sRGB, red: 0.86, green: 0.00, blue: 0.00, opacity: 1)),
        ColorItem(name: "Tuilé", color: Color(.sRGB, red: 0.67, green: 0.10, blue: 0.00, opacity: 1))
    ]

    var body: some View {
        ZoomableScrollView(minZoomScale: 1.0, maxZoomScale: 2.5) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🍷 L’examen visuel du vin")
                        .font(.headline)
                    Text("L’examen visuel est la première étape de la dégustation.")
                    Text("Avant même de sentir ou de goûter le vin, il permet de recueillir de précieuses informations sur son âge, son style et parfois son état.")
                    Text("Il se fait en observant le vin dans un verre, à la lumière, de préférence sur un fond clair.")
                }
                .font(.body)

                textSection(title: "Intensité", items: intensites)
                textSection(title: "Limpidité / Transparence", items: limpidites)

                ColorSwatchRow(
                    title: "Couleur — Blanc",
                    subtitle: "Progression du plus clair vers des teintes plus évoluées.",
                    items: whites
                )

                ColorSwatchRow(
                    title: "Couleur — Rouge",
                    subtitle: "Repères de jeunesse vers l’évolution du vin rouge.",
                    items: reds
                )

                ColorSwatchRow(
                    title: "Couleur — Rosé",
                    subtitle: "Du rose pâle vers des nuances plus soutenues et orangées.",
                    items: roses
                )

                Text("Astuce : comparez les nuances entre elles, pas avec un nuancier.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .navigationTitle("Visuel")
    }

    @ViewBuilder
    private func textSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))

            LazyVGrid(columns: textColumns, alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text(item)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let minZoomScale: CGFloat
    let maxZoomScale: CGFloat
    let content: Content

    init(minZoomScale: CGFloat = 1.0, maxZoomScale: CGFloat = 2.5, @ViewBuilder content: () -> Content) {
        self.minZoomScale = minZoomScale
        self.maxZoomScale = maxZoomScale
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(content: content)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minZoomScale
        scrollView.maximumZoomScale = maxZoomScale
        scrollView.zoomScale = 1.0
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false

        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear
        scrollView.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController: UIHostingController<Content>

        init(content: Content) {
            hostingController = UIHostingController(rootView: content)
            hostingController.view.backgroundColor = .clear
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }
    }
}

struct ColorSwatchRow: View {
    let title: String
    let subtitle: String?
    let items: [ColorItem]

    private var splitIndex: Int {
        Int(ceil(Double(items.count) / 2.0))
    }

    private var firstRowItems: [ColorItem] {
        Array(items.prefix(splitIndex))
    }

    private var secondRowItems: [ColorItem] {
        Array(items.dropFirst(splitIndex))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        ForEach(firstRowItems) { item in
                            ColorSwatchItemView(item: item)
                        }
                    }

                    if !secondRowItems.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(secondRowItems) { item in
                                ColorSwatchItemView(item: item)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ColorSwatchItemView: View {
    let item: ColorItem

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(item.color)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(.primary.opacity(0.15), lineWidth: 1)
                )

            Text(item.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 78, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), couleur")
    }
}

#Preview("Visual - Light") {
    NavigationStack {
        VisualGuideView()
    }
    .preferredColorScheme(.light)
}

#Preview("Visual - Dark") {
    NavigationStack {
        VisualGuideView()
    }
    .preferredColorScheme(.dark)
}
