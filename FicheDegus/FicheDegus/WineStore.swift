import SwiftUI
import UIKit
import ImageIO
import UniformTypeIdentifiers

private let wineStoreKey = "wine_store_cards_v1"

@Observable
final class WineStore {
    var cards: [WineCard] = [] {
        didSet { save() }
    }

    init() {
        load()
    }

    func add(_ card: WineCard) {
        cards.append(card)
    }

    func update(_ card: WineCard) {
        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx] = card
        } else {
            add(card)
        }
    }

    func delete(at offsets: IndexSet) {
        // Remove associated image files when deleting
        for idx in offsets {
            let c = cards[idx]
            if let filename = c.imageFilename {
                try? FileManager.default.removeItem(at: Self.imagesDirectoryURL().appendingPathComponent(filename))
            }
        }
        cards.remove(atOffsets: offsets)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: wineStoreKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([CodableWineCard].self, from: data)
            self.cards = decoded.map { $0.model }
        } catch {
            // Attempt migration from legacy format (where imageData was stored inline)
            print("Primary decode failed, attempting legacy migration: \(error)")
            do {
                let legacy = try JSONDecoder().decode([LegacyCodableWineCard].self, from: data)
                var migrated: [WineCard] = []
                for item in legacy {
                    var card = WineCard()
                    card.id = item.id
                    card.name = item.name
                    card.vintage = item.vintage
                    card.appellation = item.appellation
                    card.grapes = item.grapes
                    card.producer = item.producer
                    card.notes = item.notes
                    card.rating = item.rating
                    if let imageData = item.imageData, let img = UIImage(data: imageData) {
                        // Save to disk and create thumbnail
                        if let (filename, thumb) = saveImageToDisk(img) {
                            card.imageFilename = filename
                            card.thumbnailData = thumb
                            card.uiImage = UIImage(data: thumb)
                        }
                    }
                    migrated.append(card)
                }
                self.cards = migrated
                // Persist migrated format
                save()
            } catch {
                print("WineStore load (legacy) failed: \(error)")
            }
        }
    }

    private func save() {
        do {
            let encodable = cards.map { CodableWineCard(from: $0) }
            let data = try JSONEncoder().encode(encodable)
            UserDefaults.standard.set(data, forKey: wineStoreKey)
        } catch {
            print("WineStore save error: \(error)")
        }
    }

    // MARK: - Image storage helpers
    static func imagesDirectoryURL() -> URL {
        let fm = FileManager.default
        let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let base = appSupport ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("FicheDegus/Images", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }

    private func saveImageToDisk(_ image: UIImage) -> (filename: String, thumbnail: Data)? {
        // Render to preserve orientation and full resolution
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let rendered = renderer.image { _ in image.draw(at: .zero) }

        // Save full-res as JPEG (quality 0.95 to keep good quality but reasonable size)
        guard let fullData = rendered.jpegData(compressionQuality: 0.95) else { return nil }

        let filename = "img_\(UUID().uuidString).jpg"
        let fileURL = Self.imagesDirectoryURL().appendingPathComponent(filename)
        do {
            try fullData.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write full image to disk: \(error)")
            return nil
        }

        guard let thumbData = makeThumbnailData(from: rendered) else {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        return (filename, thumbData)
    }

    @discardableResult
    func save(card: WineCard, uiImage: UIImage?) -> WineCard {
        var updatedCard = card

        // If a new image is provided, save to disk and update the card's metadata
        if let img = uiImage {
            // Remove previous file if present
            if let oldFilename = updatedCard.imageFilename {
                try? FileManager.default.removeItem(at: Self.imagesDirectoryURL().appendingPathComponent(oldFilename))
            }
            if let (filename, thumbData) = saveImageToDisk(img) {
                updatedCard.imageFilename = filename
                updatedCard.thumbnailData = thumbData
                // For UI, use the thumbnail (fast) — full-res can be loaded on demand
                updatedCard.uiImage = UIImage(data: thumbData)
            }
        }
        update(updatedCard)
        return updatedCard
    }

    // Public helper to load the full-resolution image by filename
    static func loadFullImage(named filename: String) -> UIImage? {
        let url = imagesDirectoryURL().appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // Save original file bytes to disk (no recompression). Generates thumbnail and returns metadata.
    func saveOriginalFileToDisk(_ data: Data, suggestedFilename: String? = nil, uti: String? = nil) -> (filename: String, thumbnail: Data)? {
        // Determine extension from UTI if possible
        var ext = "jpg"
        if let uti = uti, let ut = UTType(uti) {
            if let preferred = ut.preferredFilenameExtension { ext = preferred }
            else if ut.conforms(to: .jpeg) { ext = "jpg" }
            else if ut.conforms(to: .png) { ext = "png" }
            else if ut.conforms(to: .heic) { ext = "heic" }
        }
        let filename = (suggestedFilename?.isEmpty == false ? suggestedFilename : nil) ?? "img_\(UUID().uuidString).\(ext)"
        let fileURL = Self.imagesDirectoryURL().appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write original file to disk: \(error)")
            return nil
        }

        // Try to create a thumbnail from data
        var thumbData: Data?
        if let img = UIImage(data: data) {
            thumbData = makeThumbnailData(from: img)
        } else {
            // Fallback: attempt to create CGImage from data via ImageIO
            if let source = CGImageSourceCreateWithData(data as CFData, nil), let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                let img = UIImage(cgImage: cg)
                thumbData = makeThumbnailData(from: img)
            }
        }

        guard let finalThumb = thumbData else {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
        return (filename, finalThumb)
    }

    private func makeThumbnailData(from image: UIImage, maxDimension: CGFloat = 800) -> Data? {
        let scale = min(1.0, maxDimension / max(image.size.width, image.size.height))
        let thumbSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let thumbRenderer = UIGraphicsImageRenderer(size: thumbSize)
        let thumb = thumbRenderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: thumbSize))
        }
        return thumb.jpegData(compressionQuality: 0.9)
    }
}

// A codable representation of WineCard (store image filename + thumbnail data)
struct CodableWineCard: Codable, Identifiable {
    let id: UUID
    let name: String
    let vintage: String
    let appellation: String
    let grapes: String
    let producer: String
    let notes: String
    let rating: Int
    let isRose: Bool
    let isBlanc: Bool
    let isRouge: Bool
    let longueurCourt: Bool
    let longueurMoyen: Bool
    let longueurLong: Bool
    let longueurExceptionnel: Bool
    let imageFilename: String?
    let thumbnailData: Data?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case vintage
        case appellation
        case grapes
        case producer
        case notes
        case rating
        case isRose
        case isBlanc
        case isRouge
        case longueurCourt
        case longueurMoyen
        case longueurLong
        case longueurExceptionnel
        case imageFilename
        case thumbnailData
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        vintage = try c.decode(String.self, forKey: .vintage)
        appellation = try c.decode(String.self, forKey: .appellation)
        grapes = try c.decode(String.self, forKey: .grapes)
        producer = try c.decode(String.self, forKey: .producer)
        notes = try c.decode(String.self, forKey: .notes)
        rating = try c.decode(Int.self, forKey: .rating)
        isRose = try c.decodeIfPresent(Bool.self, forKey: .isRose) ?? false
        isBlanc = try c.decodeIfPresent(Bool.self, forKey: .isBlanc) ?? false
        isRouge = try c.decodeIfPresent(Bool.self, forKey: .isRouge) ?? false
        longueurCourt = try c.decodeIfPresent(Bool.self, forKey: .longueurCourt) ?? false
        longueurMoyen = try c.decodeIfPresent(Bool.self, forKey: .longueurMoyen) ?? false
        longueurLong = try c.decodeIfPresent(Bool.self, forKey: .longueurLong) ?? false
        longueurExceptionnel = try c.decodeIfPresent(Bool.self, forKey: .longueurExceptionnel) ?? false
        imageFilename = try c.decodeIfPresent(String.self, forKey: .imageFilename)
        thumbnailData = try c.decodeIfPresent(Data.self, forKey: .thumbnailData)
    }

    init(from card: WineCard) {
        self.id = card.id
        self.name = card.name
        self.vintage = card.vintage
        self.appellation = card.appellation
        self.grapes = card.grapes
        self.producer = card.producer
        self.notes = card.notes
        self.rating = card.rating
        self.isRose = card.isRose
        self.isBlanc = card.isBlanc
        self.isRouge = card.isRouge
        self.longueurCourt = card.longueurCourt
        self.longueurMoyen = card.longueurMoyen
        self.longueurLong = card.longueurLong
        self.longueurExceptionnel = card.longueurExceptionnel
        self.imageFilename = card.imageFilename
        self.thumbnailData = card.thumbnailData
    }

    var model: WineCard {
        var card = WineCard()
        card.id = id
        card.name = name
        card.vintage = vintage
        card.appellation = appellation
        card.grapes = grapes
        card.producer = producer
        card.notes = notes
        card.rating = rating
        card.isRose = isRose
        card.isBlanc = isBlanc
        card.isRouge = isRouge
        card.longueurCourt = longueurCourt
        card.longueurMoyen = longueurMoyen
        card.longueurLong = longueurLong
        card.longueurExceptionnel = longueurExceptionnel
        card.imageFilename = imageFilename
        card.thumbnailData = thumbnailData
        if let data = thumbnailData, let img = UIImage(data: data) {
            card.uiImage = img
        }
        return card
    }
}

struct RGBAColor: Codable {
    let r: Double
    let g: Double
    let b: Double
    let a: Double

    init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    init(from color: Color) {
        #if canImport(UIKit)
        let ui = UIColor(color)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        self.r = Double(rr); self.g = Double(gg); self.b = Double(bb); self.a = Double(aa)
        #else
        self.r = 0; self.g = 0; self.b = 0; self.a = 1
        #endif
    }

    var color: Color { Color(red: r, green: g, blue: b).opacity(a) }
}

extension CodableWineCard {
    var thumbnail: UIImage? {
        guard let thumbnailData else { return nil }
        return UIImage(data: thumbnailData)
    }
}

// Legacy struct matching previous storage (imageData inline)
private struct LegacyCodableWineCard: Codable, Identifiable {
    let id: UUID
    let name: String
    let vintage: String
    let appellation: String
    let grapes: String
    let producer: String
    let notes: String
    let rating: Int
    let imageData: Data?
}
