import SwiftUI
import WebKit

struct WheelAromaCategory: Identifiable {
    let id: String
    let title: String
    let aromas: [String]
}

struct AromaWheelView: View {
    @State private var selectedCategory: WheelAromaCategory?

    private let categoriesById: [String: WheelAromaCategory] = {
        let data: [WheelAromaCategory] = [
            WheelAromaCategory(id: "fleur", title: "🌸 FLEUR", aromas: ["Iris", "Pivoine", "Fleur de sureau", "Acacia", "Lilas", "Jasmin", "Chèvrefeuille", "Violette", "Lavande", "Rose", "Pot-pourri", "Hibiscus"]),
            WheelAromaCategory(id: "fruit-pepins", title: "🍎 FRUITS À PÉPINS", aromas: ["Coing", "Pomme", "Poire", "Nectarine", "Pêche", "Abricot", "Kaki"]),
            WheelAromaCategory(id: "fruit-tropicaux", title: "🥭 FRUITS TROPICAUX", aromas: ["Ananas", "Mangue", "Goyave", "Kiwi", "Litchi", "Chewing-gum"]),
            WheelAromaCategory(id: "fruits-rouges", title: "🍓 FRUITS ROUGES", aromas: ["Cranberry", "Prune Rouge", "Grenade", "Cerise aigre", "Fraise", "Cerise", "Framboise"]),
            WheelAromaCategory(id: "fruits-noirs", title: "🍒 FRUITS NOIRS", aromas: ["Mûre de Boysen", "Cassis", "Cerise Noire", "Prune", "Mûre", "Myrtille", "Olive"]),
            WheelAromaCategory(id: "fruits-secs", title: "🌰 FRUITS SECS", aromas: ["Raisin", "Figue", "Datte", "Fruit confit"]),
            WheelAromaCategory(id: "pourriture", title: "🍯 POURRITURE NOBLE", aromas: ["Cire d’abeille", "Gingembre", "Miel"]),
            WheelAromaCategory(id: "epice", title: "🌶 ÉPICÉ", aromas: ["Poivre blanc", "Poivre rouge", "Poivre noir", "Cannelle", "Anis", "Les 5 parfums chinois", "Fenouil", "Eucalyptus", "Menthe", "Thym"]),
            WheelAromaCategory(id: "vegetal", title: "🌿 VÉGÉTAL", aromas: ["Thé Noir", "Tomate Séchée", "Tomate", "Amande verte", "Piment", "Poivron", "Groseille", "Feuilles de Tomate", "Herbe"]),
            WheelAromaCategory(id: "terreux", title: "🌍 TERREUX", aromas: ["Pétrole", "Roches volcaniques", "Betterave Rouge", "Terreau", "Gravier humide", "Ardoise", "Argile"]),
            WheelAromaCategory(id: "microbien", title: "🧫 MICROBIEN", aromas: ["Champignon", "Truffe", "Levure", "Levain", "Crème", "Beurre"]),
            WheelAromaCategory(id: "elevage-bois", title: "🪵 ÉLEVAGE BOIS", aromas: ["Aneth", "Fumée", "Boîte à cigares", "Épices de cuisson", "Noix de coco", "Vanille"]),
            WheelAromaCategory(id: "vieillissement-general", title: "⏳ VIEILLISSEMENT", aromas: ["Cuir", "Cacao", "Café", "Tabac", "Noix", "Fruits secs"]),
            WheelAromaCategory(id: "bouchonne", title: "🍄 BOUCHONNÉ", aromas: ["Chien Moisi", "Carton moisi"]),
            WheelAromaCategory(id: "soufre", title: "❌ SOUFRE", aromas: ["Urine de chat", "Oignon", "Ail", "Boîtes d’allumettes", "Caoutchouc brûlé", "Oeuf Pourri", "Viande Séchée"]),
            WheelAromaCategory(id: "brett", title: "❌ BRETT", aromas: ["Fumier de cheval", "Selle de cuir", "Pansement adhésif", "Cardamome noire"]),
            WheelAromaCategory(id: "cuit", title: "❌ CUIT", aromas: ["Fruit dénoyauté", "Caramel"]),
            WheelAromaCategory(id: "acidite", title: "🍋 ACIDITÉ", aromas: ["Balsamique", "Vinaigre"]),
            WheelAromaCategory(id: "agrumes", title: "🍋 AGRUMES", aromas: ["Citron vert", "Citron", "Pamplemousse", "Orange", "Marmelade"])
        ]
        return Dictionary(uniqueKeysWithValues: data.map { ($0.id, $0) })
    }()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Touchez une zone de la roue pour afficher les arômes associés. Vous pouvez zoomer avec deux doigts.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                InteractiveAromaWheelWebView { shapeId in
                    if let category = categoriesById[shapeId] {
                        selectedCategory = category
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Roue des Arômes")
            .sheet(item: $selectedCategory) { category in
                AromaCategorySheet(category: category)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

private struct AromaCategorySheet: View {
    let category: WheelAromaCategory

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(category.title)
                        .font(.headline)
                    ForEach(category.aromas, id: \.self) { aroma in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .accessibilityHidden(true)
                            Text(aroma)
                                .font(.body)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .navigationTitle("Arômes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct InteractiveAromaWheelWebView: UIViewRepresentable {
    let onShapeTap: (String) -> Void
    private static let shapeIDs: [String] = [
        "fleur",
        "fruit-pepins",
        "fruit-tropicaux",
        "fruits-rouges",
        "fruits-noirs",
        "fruits-secs",
        "pourriture",
        "epice",
        "vegetal",
        "terreux",
        "microbien",
        "elevage-bois",
        "vieillissement-general",
        "bouchonne",
        "soufre",
        "brett",
        "cuit",
        "acidite",
        "agrumes"
    ]

    func makeCoordinator() -> Coordinator {
        Coordinator(onShapeTap: onShapeTap)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.userContentController.add(context.coordinator, name: "shapeTapped")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bouncesZoom = true
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 6.0
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        webView.loadHTMLString(Self.buildHTML(), baseURL: Bundle.main.bundleURL)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private static func buildHTML() -> String {
        let svgContent = loadSVGContent()
        let idsJSON = shapeIDs
            .map { "\"\($0)\"" }
            .joined(separator: ",")
        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=6.0, user-scalable=yes" />
          <style>
            html, body { margin:0; padding:0; background:transparent; }
            #wrap { width:100%; height:100%; display:flex; align-items:flex-start; justify-content:center; }
            svg { width:100%; height:auto; display:block; }
            [id] { cursor:pointer; -webkit-tap-highlight-color: transparent; }
          </style>
        </head>
        <body>
          <div id="wrap">
            \(svgContent)
          </div>
          <script>
            (function() {
              const ids = [\(idsJSON)];
              const known = new Set(ids);

              function postShapeTap(id) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.shapeTapped) {
                  window.webkit.messageHandlers.shapeTapped.postMessage(id);
                }
              }

              function nearestKnownId(node) {
                let current = node;
                while (current) {
                  if (current.id && known.has(current.id)) { return current.id; }
                  current = current.parentElement;
                }
                return null;
              }

              function ensureHitArea(el) {
                if (!el) { return; }
                const tag = (el.tagName || "").toLowerCase();
                if (tag === "path" || tag === "polygon" || tag === "circle" || tag === "ellipse") {
                  el.style.pointerEvents = "all";
                  const fill = (el.getAttribute("fill") || "").trim().toLowerCase();
                  const style = (el.getAttribute("style") || "").toLowerCase();
                  if (fill === "none" || fill === "" || style.includes("fill:none")) {
                    el.style.fill = "rgba(0,0,0,0.001)";
                  }
                  const strokeOpacity = (el.getAttribute("stroke-opacity") || "").trim();
                  if (strokeOpacity === "0") {
                    el.style.strokeOpacity = "0.001";
                  }
                }
              }

              function bindElementTap(el, id) {
                if (!el || el.dataset.bound === "1") { return; }
                el.dataset.bound = "1";
                ensureHitArea(el);

                const handler = function(e) {
                  e.preventDefault();
                  e.stopPropagation();
                  postShapeTap(id);
                };

                el.addEventListener("pointerdown", handler, { passive: false });
                el.addEventListener("touchstart", handler, { passive: false });
                el.addEventListener("click", handler, { passive: false });
              }

              function bind() {
                ids.forEach(function(id) {
                  const root = document.getElementById(id);
                  if (!root) { return; }

                  bindElementTap(root, id);

                  const children = root.querySelectorAll("path, polygon, circle, ellipse");
                  children.forEach(function(child) {
                    bindElementTap(child, id);
                  });
                });
              }

              document.addEventListener("pointerdown", function(e) {
                const id = nearestKnownId(e.target);
                if (!id) { return; }
                e.preventDefault();
                postShapeTap(id);
              }, { passive: false });

              document.addEventListener("DOMContentLoaded", bind);
              window.addEventListener("load", bind);
              setTimeout(bind, 300);
            })();
          </script>
        </body>
        </html>
        """
    }

    private static func loadSVGContent() -> String {
        if let bundleURL = Bundle.main.url(forResource: "roue-des-aromes-2", withExtension: "svg"),
           let data = try? Data(contentsOf: bundleURL),
           let content = String(data: data, encoding: .utf8) {
            return content
        }

        let devURL = URL(fileURLWithPath: "/Users/flo/Pictures/roue-des-aromes-2.svg")
        if let data = try? Data(contentsOf: devURL),
           let content = String(data: data, encoding: .utf8) {
            return content
        }

        return """
        <svg viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'>
          <rect width='100' height='100' fill='#f5f5f7'/>
          <text x='50' y='52' text-anchor='middle' font-size='5' fill='#333'>SVG introuvable</text>
        </svg>
        """
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        private let onShapeTap: (String) -> Void

        init(onShapeTap: @escaping (String) -> Void) {
            self.onShapeTap = onShapeTap
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "shapeTapped", let id = message.body as? String else { return }
            onShapeTap(id)
        }
    }
}

#Preview("Roue interactive - Light") {
    AromaWheelView()
        .preferredColorScheme(.light)
}

#Preview("Roue interactive - Dark") {
    AromaWheelView()
        .preferredColorScheme(.dark)
}
