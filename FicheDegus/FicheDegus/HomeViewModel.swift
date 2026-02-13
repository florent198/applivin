import SwiftUI
import Combine

final class HomeViewModel: ObservableObject {
    @Published var savedCount: Int

    init(savedCount: Int = 0) {
        self.savedCount = savedCount
    }

    var savedSubtitle: String {
        if savedCount == 0 {
            return "Aucune fiche enregistrée"
        }
        if savedCount == 1 {
            return "1 fiche enregistrée"
        }
        return "\(savedCount) fiches enregistrées"
    }
}
