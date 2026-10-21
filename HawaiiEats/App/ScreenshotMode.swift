import Foundation
import CoreLocation
import UIKit

/// `-screenshot <name>` opens one screen with fixed state for App Store screenshots (scripts/capture-screenshots.sh).
/// Names: home, plate, poke, shaveice, detail, map, honors, oldest, saved, about.
enum ScreenshotMode {
    /// Debug builds only: an App Store build ignores the launch argument, so no one can reach seeded screens or fake locations.
    static var name: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return args[i + 1]
        #else
        return nil
        #endif
    }
    static var isActive: Bool { name != nil }

    /// hand-checked places with a clean, current source (no App Store image shows anything negative)
    static let savedNames = ["Leonard's Bakery", "Rainbow Drive-In", "Matsumoto Shave Ice", "Liliha Bakery"]
    static let detailName = "Rainbow Drive-In"

    @MainActor
    static func apply(to model: AppModel) {
        guard let name, model.isLoaded else { return }
        model.filters = Filters()
        // downtown Honolulu (King and Bishop), so "nearest" lists have distances without a permission prompt
        model.screenshotLocation = CLLocation(latitude: 21.3087, longitude: -157.8610)
        // by name, ignoring case: a rebuild that takes the research spelling still finds the place
        let pick = { (n: String) in model.places.first { $0.name.caseInsensitiveCompare(n) == .orderedSame } }
        for n in Self.savedNames {
            if let p = pick(n), !model.isSaved(p) { model.toggleSaved(p) }
        }
        let open = { (g: Guide) in model.tab = .guides; model.selectedGuide = g; model.guidesPath = [.guide(g)] }
        switch name {
        case "plate": open(.plateLunch)
        case "poke": open(.poke)
        case "shaveice": open(.shaveIce)
        case "honors": open(.honors)
        case "oldest": open(.oldest)
        case "detail":
            open(.oldest)
            if let p = pick(Self.detailName) ?? model.places.first { model.selectedPlace = p; model.guidesPath.append(.place(p)) }
        case "map": model.tab = .map
        case "saved": model.tab = .saved
        case "about": model.tab = .about
        default: model.tab = .guides; model.selectedGuide = nil
        }
        // iPad shows the place column next to every list, so give each shot a place instead of "Pick a place".
        guard UIDevice.current.userInterfaceIdiom == .pad, model.selectedPlace == nil else { return }
        let place: Place? = switch name {
        case "plate": model.list(.plateLunch, sort: .featured, search: "", here: nil).first
        case "poke": model.list(.poke, sort: .featured, search: "", here: nil).first
        case "shaveice": model.list(.shaveIce, sort: .featured, search: "", here: nil).first
        case "honors": model.list(.honors, sort: .iconic, search: "", here: nil).first
        case "saved": pick(Self.savedNames[0])
        case "about": nil
        default: pick(Self.detailName)
        }
        model.selectedPlace = place
    }
}
