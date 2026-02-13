import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

struct WineCard: Identifiable, Hashable {
    var id = UUID()
    var name: String = "Nom du vin"
    var vintage: String = "2020"
    var appellation: String = "Appellation / Région"
    var grapes: String = "Cépages"
    var producer: String = "Producteur"
    var notes: String = "Notes de dégustation"
    var rating: Int = 4
    var isRose: Bool = false
    var isBlanc: Bool = false
    var isRouge: Bool = false
    var longueurCourt: Bool = false
    var longueurMoyen: Bool = false
    var longueurLong: Bool = false
    var longueurExceptionnel: Bool = false
    var image: Image? = nil
    // transient: decoded thumbnail or loaded full image for UI
    var uiImage: UIImage? = nil
    // persisted: filename (in Application Support/Images) for full resolution image
    var imageFilename: String? = nil
    // persisted: thumbnail data for fast display (small size)
    var thumbnailData: Data? = nil

    static func == (lhs: WineCard, rhs: WineCard) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.vintage == rhs.vintage &&
        lhs.appellation == rhs.appellation &&
        lhs.grapes == rhs.grapes &&
        lhs.producer == rhs.producer &&
        lhs.notes == rhs.notes &&
        lhs.rating == rhs.rating &&
        lhs.isRose == rhs.isRose &&
        lhs.isBlanc == rhs.isBlanc &&
        lhs.isRouge == rhs.isRouge &&
        lhs.longueurCourt == rhs.longueurCourt &&
        lhs.longueurMoyen == rhs.longueurMoyen &&
        lhs.longueurLong == rhs.longueurLong &&
        lhs.longueurExceptionnel == rhs.longueurExceptionnel
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(vintage)
        hasher.combine(appellation)
        hasher.combine(grapes)
        hasher.combine(producer)
        hasher.combine(notes)
        hasher.combine(rating)
        hasher.combine(isRose)
        hasher.combine(isBlanc)
        hasher.combine(isRouge)
        hasher.combine(longueurCourt)
        hasher.combine(longueurMoyen)
        hasher.combine(longueurLong)
        hasher.combine(longueurExceptionnel)
    }
}

struct ContentView: View {
    var existingCard: WineCard? = nil

    @State private var card: WineCard
    @State private var uiImage: UIImage? = nil
    @State private var showCamera = false
    @State private var cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
    @State private var showPhotoChoice = false
    @State private var showCameraDeniedAlert = false
    @State private var showLibraryPickerSheet = false
    @Environment(WineStore.self) private var store

    @State private var showShareOptions = false

    @FocusState private var focusedField: FocusField?

    enum FocusField {
        case name, vintage, producer, appellation, grapes, notes
    }

    init(existingCard: WineCard? = nil) {
        self.existingCard = existingCard
        _card = State(initialValue: existingCard ?? WineCard())
        _uiImage = State(initialValue: existingCard?.uiImage)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    editor
                    Divider().padding(.horizontal)
                    cardPreview
                        .background(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 4)
                        .padding(.horizontal)
                        .overlay(alignment: .topTrailing) {
                            Button(action: { showShareOptions = true }) {
                                Image(systemName: "square.and.arrow.up")
                                    .padding(10)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .padding(16)
                        }
                        .confirmationDialog("Partager la fiche", isPresented: $showShareOptions, titleVisibility: .visible) {
                            Button("Partage PNG", systemImage: "photo") {
                                showShareOptions = false
                                Task {
                                    try? await Task.sleep(nanoseconds: 150_000_000)
                                    await shareAsPNG(size: CGSize(width: 1080, height: 1920))
                                }
                            }
                            Button("Partage PDF", systemImage: "doc.richtext") {
                                showShareOptions = false
                                Task {
                                    try? await Task.sleep(nanoseconds: 150_000_000)
                                    await shareAsPDF()
                                }
                            }
                            Button("Enregistrer", systemImage: "square.and.arrow.down") {
                                showShareOptions = false
                                store.save(card: card, uiImage: uiImage)
                            }
                            Button("Annuler", role: .cancel) {}
                        }
                }
                .padding(.vertical)
                .background(Color.white)
            }
            .background(Color.white)
            .navigationTitle("Fiche de vin")
            .task {
                if let filename = card.imageFilename {
                    if let full = WineStore.loadFullImage(named: filename) {
                        await MainActor.run {
                            self.uiImage = full
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.save(card: card, uiImage: uiImage)
                    } label: {
                        Label("Enregistrer", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Éditeur").font(.headline).padding(.horizontal)
            VStack(spacing: 12) {
                TextField("Nom du vin", text: $card.name)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .name)
                    .onChange(of: focusedField) { _, newValue in
                        if newValue == .name && card.name == "Nom du vin" {
                            card.name = ""
                        }
                    }
                HStack {
                    TextField("Millésime", text: $card.vintage)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .vintage)
                        .onChange(of: focusedField) { _, newValue in
                            if newValue == .vintage && card.vintage == "2020" {
                                card.vintage = ""
                            }
                        }
                    TextField("Producteur", text: $card.producer)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .producer)
                        .onChange(of: focusedField) { _, newValue in
                            if newValue == .producer && card.producer == "Producteur" {
                                card.producer = ""
                            }
                        }
                }
                TextField("Appellation / Région", text: $card.appellation)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .appellation)
                    .onChange(of: focusedField) { _, newValue in
                        if newValue == .appellation && card.appellation == "Appellation / Région" {
                            card.appellation = ""
                        }
                    }
                TextField("Cépages", text: $card.grapes)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .grapes)
                    .onChange(of: focusedField) { _, newValue in
                        if newValue == .grapes && card.grapes == "Cépages" {
                            card.grapes = ""
                        }
                    }
                HStack(spacing: 20) {
                    Toggle(isOn: $card.isRouge) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                            Text("Rouge")
                                .font(.caption)
                        }
                    }
                    Toggle(isOn: $card.isBlanc) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.yellow.opacity(0.7))
                                .frame(width: 16, height: 16)
                            Text("Blanc")
                                .font(.caption)
                        }
                    }
                    Toggle(isOn: $card.isRose) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.75, blue: 0.8))
                                .frame(width: 16, height: 16)
                            Text("Rosé")
                                .font(.caption)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)
                .onChange(of: card.isRouge) { _, isOn in
                    guard isOn else { return }
                    card.isBlanc = false
                    card.isRose = false
                }
                .onChange(of: card.isBlanc) { _, isOn in
                    guard isOn else { return }
                    card.isRouge = false
                    card.isRose = false
                }
                .onChange(of: card.isRose) { _, isOn in
                    guard isOn else { return }
                    card.isRouge = false
                    card.isBlanc = false
                }
                HStack {
                    Text("Note: ")
                    Stepper(value: $card.rating, in: 0...5) {
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: i < card.rating ? "star.fill" : "star")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
                
                // Longueur en bouche
                Text("Longueur en bouche")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 4)
                
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Court")
                            .font(.caption)
                        Toggle("", isOn: $card.longueurCourt)
                            .labelsHidden()
                    }
                    
                    VStack(spacing: 4) {
                        Text("Moyen")
                            .font(.caption)
                        Toggle("", isOn: $card.longueurMoyen)
                            .labelsHidden()
                    }
                    
                    VStack(spacing: 4) {
                        Text("Long")
                            .font(.caption)
                        Toggle("", isOn: $card.longueurLong)
                            .labelsHidden()
                    }
                    
                    VStack(spacing: 4) {
                        Text("Exceptionnel")
                            .font(.caption)
                        Toggle("", isOn: $card.longueurExceptionnel)
                            .labelsHidden()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .onChange(of: card.longueurCourt) { _, isOn in
                    guard isOn else { return }
                    card.longueurMoyen = false
                    card.longueurLong = false
                    card.longueurExceptionnel = false
                }
                .onChange(of: card.longueurMoyen) { _, isOn in
                    guard isOn else { return }
                    card.longueurCourt = false
                    card.longueurLong = false
                    card.longueurExceptionnel = false
                }
                .onChange(of: card.longueurLong) { _, isOn in
                    guard isOn else { return }
                    card.longueurCourt = false
                    card.longueurMoyen = false
                    card.longueurExceptionnel = false
                }
                .onChange(of: card.longueurExceptionnel) { _, isOn in
                    guard isOn else { return }
                    card.longueurCourt = false
                    card.longueurMoyen = false
                    card.longueurLong = false
                }
                
                Button(action: { showPhotoChoice = true }) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Choisir une photo")
                        Spacer()
                        if let uiImage { Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill).frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8)) }
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .confirmationDialog("Ajouter une photo", isPresented: $showPhotoChoice, titleVisibility: .visible) {
                    if cameraAvailable {
                        Button("Prendre une photo", systemImage: "camera") {
                            requestCameraPermissionAndShow()
                        }
                    }
                    Button("Choisir dans la photothèque", systemImage: "photo.on.rectangle") {
                        // Dismiss the confirmation dialog first, then present the PHPicker sheet
                        showPhotoChoice = false
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 150_000_000)
                            showLibraryPickerSheet = true
                        }
                    }
                    Button("Annuler", role: .cancel) {}
                }
                .sheet(isPresented: $showCamera) {
                    CameraView(image: $uiImage)
                        .ignoresSafeArea()
                }
                .sheet(isPresented: $showLibraryPickerSheet) {
                    PhotoPickerController { picked in
                        // handle the picked UIImage
                        showLibraryPickerSheet = false
                        guard let picked = picked else { return }
                        // try to save original bytes (encode as jpeg at high quality)
                        if let data = picked.jpegData(compressionQuality: 1.0) {
                            let uti = "public.jpeg"
                            if let (filename, thumb) = store.saveOriginalFileToDisk(data, suggestedFilename: nil, uti: uti) {
                                var updatedCard = card
                                if let old = updatedCard.imageFilename, old != filename {
                                    try? FileManager.default.removeItem(at: WineStore.imagesDirectoryURL().appendingPathComponent(old))
                                }
                                updatedCard.imageFilename = filename
                                updatedCard.thumbnailData = thumb
                                updatedCard.uiImage = UIImage(data: thumb)
                                Task { @MainActor in
                                    self.card = updatedCard
                                    self.uiImage = updatedCard.uiImage
                                    store.save(card: updatedCard, uiImage: nil)
                                }
                                return
                            }
                        }
                        // fallback to UI update
                        Task { @MainActor in
                            self.uiImage = picked
                        }
                    }
                }
                .alert("Accès caméra refusé", isPresented: $showCameraDeniedAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Autorisez l'accès à la caméra dans Réglages → FicheDegus pour pouvoir prendre une photo.")
                }

                TextField("Notes de dégustation", text: $card.notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .notes)
                    .onChange(of: focusedField) { _, newValue in
                        if newValue == .notes && card.notes == "Notes de dégustation" {
                            card.notes = ""
                        }
                    }
            }
            .padding()
        }
    }

    private var cardPreview: some View {
        WineCardView(card: card, uiImage: uiImage)
            .padding()
            .drawingGroup()  // Optimize rendering performance
    }

    private func slugify(_ string: String) -> String {
        // Remove diacritics (accents)
        let noDiacritics = string.folding(options: .diacriticInsensitive, locale: .current)
        // Replace spaces with hyphens and lowercased
        let replaced = noDiacritics.replacingOccurrences(of: " ", with: "-")
        // Keep only allowed characters (letters, numbers, hyphen, underscore)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let filteredScalars = replaced.unicodeScalars.filter { allowed.contains($0) }
        var result = String(String.UnicodeScalarView(filteredScalars))
        // Collapse multiple hyphens
        while result.contains("--") { result = result.replacingOccurrences(of: "--", with: "-") }
        // Trim hyphens
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return result
    }

    private func temporaryFileURL(filename: String, ext: String) -> URL {
        let safeName = slugify(filename)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeName).\(ext)")
        // Remove existing file if present
        try? FileManager.default.removeItem(at: url)
        return url
    }

    // Demande et gère la permission d'accès à la caméra puis affiche la caméra si autorisé
    private func requestCameraPermissionAndShow() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Déjà autorisé
            showCamera = true
        case .notDetermined:
            // Demande la permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showCamera = true
                    } else {
                        self.showCameraDeniedAlert = true
                    }
                }
            }
        default:
            // Denied / restricted
            showCameraDeniedAlert = true
        }
    }

    private func presentActivity(items: [Any]) {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first(where: { $0.isKeyWindow }),
                  let root = window.rootViewController else {
                return
            }

            // Find topmost presented view controller
            var top = root
            while let presented = top.presentedViewController {
                top = presented
            }

            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            ac.popoverPresentationController?.sourceView = window

            // If something is presented, dismiss it first then present the activity controller from the root
            if top !== root {
                top.dismiss(animated: true) {
                    root.present(ac, animated: true)
                }
            } else {
                root.present(ac, animated: true)
            }
        }
    }

    private func shareAsPNG(size: CGSize) async {
        // Prefer full image from disk if available
        var fullImage: UIImage? = uiImage
        if let filename = card.imageFilename, let loaded = WineStore.loadFullImage(named: filename) {
            fullImage = loaded
        }
        let normalizedPhoto = fullImage.map { normalizeImageOrientation($0) }

        // Create exported image for the requested size
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return }
        drawExportCard(in: CGRect(origin: .zero, size: size), canvasSize: size, context: context, photo: normalizedPhoto)

        guard let finalImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
        let fileName = "FicheVin-\(card.name)"
        let url = temporaryFileURL(filename: fileName, ext: "png")

        if let pngData = finalImage.pngData() {
            do {
                try pngData.write(to: url, options: .atomic)
                await MainActor.run { self.showShareOptions = false }
                try? await Task.sleep(nanoseconds: 200_000_000)
                presentActivity(items: [url])
                return
            } catch {
                // Fallback to sharing UIImage if file write fails.
            }
        }

        await MainActor.run { self.showShareOptions = false }
        try? await Task.sleep(nanoseconds: 200_000_000)
        presentActivity(items: [finalImage])
    }

    private func shareAsPDF() async {
        // Prefer full image from disk if available
        var fullImage: UIImage? = uiImage
        if let filename = card.imageFilename, let loaded = WineStore.loadFullImage(named: filename) {
            fullImage = loaded
        }
        let normalizedPhoto = fullImage.map { normalizeImageOrientation($0) }

        let pageSize = CGSize(width: 1080, height: 1920)
        let pageRect = CGRect(origin: .zero, size: pageSize)

        let pdfData = UIGraphicsPDFRenderer(bounds: pageRect).pdfData { ctx in
            ctx.beginPage()
            drawExportCard(in: pageRect, canvasSize: pageSize, context: ctx.cgContext, photo: normalizedPhoto)
        }

        let fileName = "FicheVin-\(card.name)"
        let url = temporaryFileURL(filename: fileName, ext: "pdf")
        do {
            try pdfData.write(to: url, options: Data.WritingOptions.atomic)
            await MainActor.run { self.showShareOptions = false }
            try? await Task.sleep(nanoseconds: 200_000_000)
            presentActivity(items: [url])
        } catch {
            await MainActor.run { self.showShareOptions = false }
            try? await Task.sleep(nanoseconds: 200_000_000)
            presentActivity(items: [pdfData])
        }
    }

    private func drawExportCard(in rect: CGRect, canvasSize: CGSize, context: CGContext, photo: UIImage?) {
        context.interpolationQuality = .high

        UIColor.white.setFill()
        context.fill(rect)

        let wineColor = exportWineColor()
        let outerInsetX = max(14, canvasSize.width * 0.015)
        let outerInsetY = max(18, canvasSize.height * 0.02)
        let cardRect = rect.insetBy(dx: outerInsetX, dy: outerInsetY)
        let cornerRadius = max(28, canvasSize.width * 0.038)

        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cornerRadius)
        context.saveGState()
        cardPath.addClip()
        if let backgroundImage = UIImage(named: "ExportBackground") {
            backgroundImage.draw(in: aspectFillRect(for: backgroundImage.size, in: cardRect))
            UIColor(white: 1.0, alpha: 0.58).setFill()
            context.fill(cardRect)
        } else {
            UIColor(white: 0.91, alpha: 1.0).setFill()
            context.fill(cardRect)
        }
        context.restoreGState()

        let horizontalPadding = cardRect.width * 0.05
        let titleRect = CGRect(
            x: cardRect.minX + horizontalPadding,
            y: cardRect.minY + cardRect.height * 0.146,
            width: cardRect.width - (horizontalPadding * 2),
            height: cardRect.height * 0.12
        )

        let contentTop = titleRect.maxY + cardRect.height * 0.03
        let contentBottom = cardRect.maxY - cardRect.height * 0.06
        let notesTopSpacing = cardRect.height * 0.02
        let notesHeight = max(cardRect.height * 0.14, canvasSize.height * 0.12)
        let upperContentBottom = contentBottom - notesTopSpacing - notesHeight
        let contentHeight = max(0, upperContentBottom - contentTop)

        let photoWidth = cardRect.width * 0.50
        let photoHeight = min(contentHeight * 0.84, photoWidth * 1.26)
        let photoY = contentTop + max(0, (contentHeight - photoHeight) * 0.12)
        let imageRect = CGRect(
            x: cardRect.minX + horizontalPadding,
            y: photoY,
            width: photoWidth,
            height: photoHeight
        )

        let detailsX = imageRect.maxX + cardRect.width * 0.045
        let detailsWidth = max(0, cardRect.maxX - horizontalPadding - detailsX)
        let textBlock = CGRect(
            x: detailsX,
            y: contentTop + cardRect.height * 0.01,
            width: detailsWidth,
            height: contentHeight
        )

        let titleFont = UIFont.systemFont(ofSize: max(46, canvasSize.width * 0.058), weight: .bold)
        let infoFont = UIFont.systemFont(ofSize: max(33, canvasSize.width * 0.039), weight: .semibold)
        let metaFont = UIFont.systemFont(ofSize: max(27, canvasSize.width * 0.031), weight: .medium)
        let longueurFont = UIFont.systemFont(ofSize: max(32, canvasSize.width * 0.037), weight: .medium)
        let starFont = UIFont.systemFont(ofSize: max(60, canvasSize.width * 0.057), weight: .bold)

        let centerPara = NSMutableParagraphStyle()
        centerPara.alignment = .center
        let leftPara = NSMutableParagraphStyle()
        leftPara.alignment = .left

        let titleText = (card.name.isEmpty ? "Nom du vin" : card.name).uppercased()
        (titleText as NSString).draw(
            in: CGRect(x: titleRect.minX, y: titleRect.minY, width: titleRect.width, height: titleRect.height),
            withAttributes: [
                .font: titleFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: centerPara
            ]
        )

        let wineTypeText = exportWineTypeText()
        let longueurText = exportLongueurText()
        let appellationRaw = card.appellation.trimmingCharacters(in: .whitespacesAndNewlines)
        let appellationText = appellationRaw.isEmpty ? nil : "Appellation \(appellationRaw)"
        let spacingAfterVintage = canvasSize.height * 0.022
        let spacingAfterAppellation = canvasSize.height * 0.018
        let spacingAfterType = canvasSize.height * 0.024
        let spacingAfterStars = canvasSize.height * 0.02

        var detailsHeight = infoFont.lineHeight + spacingAfterVintage
        if appellationText != nil {
            detailsHeight += metaFont.lineHeight + spacingAfterAppellation
        }
        if wineTypeText != nil {
            detailsHeight += infoFont.lineHeight + spacingAfterType
        }
        detailsHeight += starFont.lineHeight + spacingAfterStars
        if longueurText != nil {
            detailsHeight += longueurFont.lineHeight
        }

        let centeredStartY = imageRect.midY - detailsHeight / 2
        let minStartY = textBlock.minY
        let maxStartY = textBlock.maxY - detailsHeight
        var y = min(max(centeredStartY, minStartY), maxStartY)

        ("Millésime \(card.vintage)" as NSString).draw(
            in: CGRect(x: textBlock.minX, y: y, width: textBlock.width, height: infoFont.lineHeight * 1.2),
            withAttributes: [
                .font: infoFont,
                .foregroundColor: wineColor,
                .paragraphStyle: leftPara
            ]
        )

        y += infoFont.lineHeight + spacingAfterVintage
        if let appellationText {
            (appellationText as NSString).draw(
                in: CGRect(x: textBlock.minX, y: y, width: textBlock.width, height: metaFont.lineHeight * 1.25),
                withAttributes: [
                    .font: metaFont,
                    .foregroundColor: UIColor.black.withAlphaComponent(0.78),
                    .paragraphStyle: leftPara
                ]
            )
            y += metaFont.lineHeight + spacingAfterAppellation
        }

        if let wineTypeText {
            (wineTypeText as NSString).draw(
                in: CGRect(x: textBlock.minX, y: y, width: textBlock.width, height: infoFont.lineHeight * 1.2),
                withAttributes: [
                    .font: infoFont,
                    .foregroundColor: wineColor,
                    .paragraphStyle: leftPara
                ]
            )
            y += infoFont.lineHeight + spacingAfterType
        }

        let starSpacing = max(10, canvasSize.width * 0.0085)
        let starCharWidth = ("★" as NSString).size(withAttributes: [.font: starFont]).width
        var starX = textBlock.minX
        for i in 0..<5 {
            let star = i < max(0, min(5, card.rating)) ? "★" : "☆"
            let color = i < card.rating ? UIColor(red: 0.90, green: 0.73, blue: 0.25, alpha: 1) : UIColor(white: 0.70, alpha: 1.0)
            (star as NSString).draw(
                at: CGPoint(x: starX, y: y),
                withAttributes: [.font: starFont, .foregroundColor: color]
            )
            starX += starCharWidth + starSpacing
        }
        y += starFont.lineHeight + spacingAfterStars

        if let longueur = longueurText {
            ("Longueur: \(longueur)" as NSString).draw(
                in: CGRect(x: textBlock.minX, y: y, width: textBlock.width, height: longueurFont.lineHeight * 1.2),
                withAttributes: [
                    .font: longueurFont,
                    .foregroundColor: wineColor,
                    .paragraphStyle: leftPara
                ]
            )
        }

        let imagePath = UIBezierPath(roundedRect: imageRect, cornerRadius: max(14, canvasSize.width * 0.016))

        if let photo {
            UIColor(white: 0.95, alpha: 1).setFill()
            imagePath.fill()
            context.saveGState()
            imagePath.addClip()
            photo.draw(in: aspectFitRect(for: photo.size, in: imageRect))
            context.restoreGState()
        } else {
            UIColor(white: 0.86, alpha: 1).setFill()
            imagePath.fill()
            ("🍷" as NSString).draw(
                at: CGPoint(x: imageRect.midX - 38, y: imageRect.midY - 50),
                withAttributes: [.font: UIFont.systemFont(ofSize: max(64, canvasSize.width * 0.065))]
            )
        }

        wineColor.withAlphaComponent(0.25).setStroke()
        imagePath.lineWidth = max(2, canvasSize.width * 0.0022)
        imagePath.stroke()

        let notesRect = CGRect(
            x: cardRect.minX + horizontalPadding,
            y: upperContentBottom + notesTopSpacing,
            width: cardRect.width - (horizontalPadding * 2),
            height: notesHeight
        )

        let separatorY = notesRect.minY - cardRect.height * 0.008
        context.setStrokeColor(UIColor.black.withAlphaComponent(0.12).cgColor)
        context.setLineWidth(max(1, canvasSize.width * 0.0014))
        context.move(to: CGPoint(x: notesRect.minX, y: separatorY))
        context.addLine(to: CGPoint(x: notesRect.maxX, y: separatorY))
        context.strokePath()

        let notesTitleFont = UIFont.systemFont(ofSize: max(24, canvasSize.width * 0.024), weight: .semibold)
        let notesBodyFont = UIFont.systemFont(ofSize: max(22, canvasSize.width * 0.021), weight: .regular)
        let notesTitle = "Notes de dégustation"
        (notesTitle as NSString).draw(
            in: CGRect(
                x: notesRect.minX,
                y: notesRect.minY,
                width: notesRect.width,
                height: notesTitleFont.lineHeight * 1.25
            ),
            withAttributes: [
                .font: notesTitleFont,
                .foregroundColor: UIColor.black.withAlphaComponent(0.9)
            ]
        )

        let notesText = card.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Aucune note." : card.notes
        let notesParagraph = NSMutableParagraphStyle()
        notesParagraph.alignment = .left
        notesParagraph.lineBreakMode = .byWordWrapping
        (notesText as NSString).draw(
            in: CGRect(
                x: notesRect.minX,
                y: notesRect.minY + notesTitleFont.lineHeight + cardRect.height * 0.008,
                width: notesRect.width,
                height: notesRect.height - notesTitleFont.lineHeight - cardRect.height * 0.01
            ),
            withAttributes: [
                .font: notesBodyFont,
                .foregroundColor: UIColor.black.withAlphaComponent(0.82),
                .paragraphStyle: notesParagraph
            ]
        )
    }

    private func exportWineColor() -> UIColor {
        if card.isRouge { return UIColor(red: 0.57, green: 0.17, blue: 0.20, alpha: 1.0) }
        if card.isBlanc { return UIColor(red: 0.58, green: 0.47, blue: 0.17, alpha: 1.0) }
        if card.isRose { return UIColor(red: 0.69, green: 0.35, blue: 0.41, alpha: 1.0) }
        return UIColor(red: 0.57, green: 0.17, blue: 0.20, alpha: 1.0)
    }

    private func exportWineTypeText() -> String? {
        if card.isRouge { return "● Rouge" }
        if card.isBlanc { return "● Blanc" }
        if card.isRose { return "● Rosé" }
        return nil
    }

    private func exportLongueurText() -> String? {
        if card.longueurCourt { return "Court" }
        if card.longueurMoyen { return "Moyen" }
        if card.longueurLong { return "Long" }
        if card.longueurExceptionnel { return "Exceptionnel" }
        return nil
    }

    private func aspectFitRect(for imageSize: CGSize, in rect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return rect }
        let imageRatio = imageSize.width / imageSize.height
        let rectRatio = rect.width / rect.height

        if imageRatio > rectRatio {
            let width = rect.width
            let height = width / imageRatio
            let y = rect.midY - height / 2
            return CGRect(x: rect.minX, y: y, width: width, height: height)
        } else {
            let height = rect.height
            let width = height * imageRatio
            let x = rect.midX - width / 2
            return CGRect(x: x, y: rect.minY, width: width, height: height)
        }
    }

    private func aspectFillRect(for imageSize: CGSize, in rect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return rect }
        let imageRatio = imageSize.width / imageSize.height
        let rectRatio = rect.width / rect.height

        if imageRatio > rectRatio {
            let height = rect.height
            let width = height * imageRatio
            let x = rect.midX - width / 2
            return CGRect(x: x, y: rect.minY, width: width, height: height)
        } else {
            let width = rect.width
            let height = width / imageRatio
            let y = rect.midY - height / 2
            return CGRect(x: rect.minX, y: y, width: width, height: height)
        }
    }

    private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}

struct WineCardView: View {
    var card: WineCard
    var uiImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                // Image - optimized rendering
                Group {
                    if let uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 104, height: 144)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.6), lineWidth: 1))
                            .shadow(radius: 2)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue.opacity(0.15))
                            Image(systemName: "wineglass.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.blue)
                        }
                        .frame(width: 104, height: 144)
                    }
                }
                .drawingGroup()

                // Text content - simplified rendering
                VStack(alignment: .leading, spacing: 5) {
                    Text(card.name)
                        .font(.title2).bold()
                        .lineLimit(2)
                    Text("Millésime \(card.vintage)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(card.producer)
                        .font(.subheadline)
                        .lineLimit(1)
                    Text(card.appellation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(card.grapes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    // Wine types
                    HStack(spacing: 8) {
                        if card.isRouge {
                            HStack(spacing: 4) {
                                Circle().fill(Color.red).frame(width: 8, height: 8)
                                Text("Rouge").font(.caption)
                            }
                        }
                        if card.isBlanc {
                            HStack(spacing: 4) {
                                Circle().fill(Color.yellow.opacity(0.7)).frame(width: 8, height: 8)
                                Text("Blanc").font(.caption)
                            }
                        }
                        if card.isRose {
                            HStack(spacing: 4) {
                                Circle().fill(Color(red: 1.0, green: 0.75, blue: 0.8)).frame(width: 8, height: 8)
                                Text("Rosé").font(.caption)
                            }
                        }
                    }
                    .padding(.top, 2)
                    
                    // Longueur en bouche
                    if card.longueurCourt || card.longueurMoyen || card.longueurLong || card.longueurExceptionnel {
                        HStack(spacing: 4) {
                            Text("Longueur:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if card.longueurCourt {
                                Text("Court").font(.caption).foregroundStyle(.primary)
                            } else if card.longueurMoyen {
                                Text("Moyen").font(.caption).foregroundStyle(.primary)
                            } else if card.longueurLong {
                                Text("Long").font(.caption).foregroundStyle(.primary)
                            } else if card.longueurExceptionnel {
                                Text("Exceptionnel").font(.caption).foregroundStyle(.primary)
                            }
                        }
                        .padding(.top, 2)
                    }
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < card.rating ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                        }
                    }
                    .padding(.top, 3)
                }
                .drawingGroup()
                Spacer()
            }

            Divider()
            Text("Notes")
                .font(.headline)
            Text(card.notes)
                .font(.body)
                .lineLimit(3)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.blue.opacity(0.4), lineWidth: 2)
            }
        )
    }
}

// Extension to make WineCardView skip re-renders when nothing changed
extension WineCardView: Equatable {
    static func == (lhs: WineCardView, rhs: WineCardView) -> Bool {
        lhs.card == rhs.card && lhs.uiImage == rhs.uiImage
    }
}

struct WineCardViewForShare: View {
    var card: WineCard
    var uiImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.gray.opacity(0.3), lineWidth: 1))
                        .shadow(radius: 2)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue.opacity(0.15))
                        Image(systemName: "wineglass.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.blue)
                    }
                    .frame(width: 100, height: 140)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.title2).bold()
                        .foregroundColor(.black)
                    Text("Millésime \(card.vintage)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(card.producer)
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Text(card.appellation)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(card.grapes)
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    // Display wine types
                    HStack(spacing: 8) {
                        if card.isRouge {
                            HStack(spacing: 4) {
                                Circle().fill(Color.red).frame(width: 8, height: 8)
                                Text("Rouge").font(.caption).foregroundColor(.black)
                            }
                        }
                        if card.isBlanc {
                            HStack(spacing: 4) {
                                Circle().fill(Color.yellow.opacity(0.7)).frame(width: 8, height: 8)
                                Text("Blanc").font(.caption).foregroundColor(.black)
                            }
                        }
                        if card.isRose {
                            HStack(spacing: 4) {
                                Circle().fill(Color(red: 1.0, green: 0.75, blue: 0.8)).frame(width: 8, height: 8)
                                Text("Rosé").font(.caption).foregroundColor(.black)
                            }
                        }
                    }
                    .padding(.top, 1)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < card.rating ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Divider()
                .background(Color.black.opacity(0.2))
            Text("Notes")
                .font(.headline)
                .foregroundColor(.black)
            Text(card.notes)
                .font(.body)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.white)
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        init(parent: CameraView) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.image = img
                    picker.dismiss(animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    picker.dismiss(animated: true)
                }
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            DispatchQueue.main.async {
                picker.dismiss(animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// PHPicker wrapper to present system photo picker and return a UIImage

struct PhotoPickerController: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerController
        init(parent: PhotoPickerController) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first else {
                parent.completion(nil)
                return
            }
            let provider = item.itemProvider
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] obj, err in
                    DispatchQueue.main.async {
                        self?.parent.completion(obj as? UIImage)
                    }
                }
                return
            }
            // fallback to file representation
            let type = provider.registeredTypeIdentifiers.first ?? "public.image"
            provider.loadFileRepresentation(forTypeIdentifier: type) { [weak self] url, err in
                guard let url = url else {
                    DispatchQueue.main.async { self?.parent.completion(nil) }
                    return
                }
                // copy to temp and load UIImage
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: tmp)
                do {
                    try FileManager.default.copyItem(at: url, to: tmp)
                    if let data = try? Data(contentsOf: tmp), let img = UIImage(data: data) {
                        DispatchQueue.main.async { self?.parent.completion(img) }
                        return
                    }
                } catch {
                }
                DispatchQueue.main.async { self?.parent.completion(nil) }
            }
        }
    }
}

#Preview {
    ContentView()
}
