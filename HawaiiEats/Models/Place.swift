import Foundation
import CoreLocation
import SwiftUI

// MARK: - The bundled data file (Resources/places.json), written by pipeline/hawaii.py with HI_APP=1

struct DataFile: Decodable {
    let generated: String
    /// the Overture Maps release the listings come from ("2026-09-23.1"); optional so an older file still opens
    let overture_release: String?
    /// when a county liquor license list was saved; nil until one is in the data (none can be read automatically today)
    let liquor_updated: String?
    let licenses: Int?
    let cities: [String]
    let cuisines: [String]
    let brands: [String]
    let counties: [String]
    /// "Kauaʻi", "Niʻihau", "Oʻahu", "Molokaʻi", "Lānaʻi", "Maui", "Hawaiʻi"
    let islands: [String]?
    let srcs: [String]
    let count_restaurants: Int
    let calibration: Calibration?
    let places: [PlaceRecord]
}

/// What the app can say about how listings were checked (pipeline/calibrate.py). Nothing Google-derived: Hawaii's match rates against
/// DOH's end-of-2011 food permit list (and Oʻahu's 2013 list), BLS county counts, and Colorado's Denver test for reference.
struct Calibration: Decodable, Hashable {
    let groups: [String: CalibrationGroup]?
    let per_county: [String: CountyCount]?
    let reference_colorado_denver: Reference?
    let doh2011_found_in_listings: Double?

    struct Reference: Decodable, Hashable {
        let groups: [String: DenverGroup]?
    }
    struct DenverGroup: Decodable, Hashable {
        let n: Int
        let official: Double
    }
    struct CountyCount: Decodable, Hashable {
        let listings: Int
        let app_rule: Int
        let qcew_722: Int?
    }
}

struct CalibrationGroup: Decodable, Hashable {
    let n: Int
    /// share of listings of this kind that match DOH's 2011 statewide permit list (shows the place existed then, not that it's open)
    let doh2011: Double?
    let doh2013_oahu: Double?
}

/// An official record behind a place: a county liquor license (none are loaded today).
struct LicenseRecord: Decodable, Hashable {
    let src: String
    let id: String
    let type: String?
    let exp: String?
}

struct PlaceRecord: Decodable {
    let id: String
    let n: String
    let c: Int?
    let cu: Int
    let t: Int
    let s: Int
    let co: Int?
    let a: String?
    let z: String?
    let la: Double?
    let lo: Double?
    let b: Int?
    let ch: Int?
    let j: Int?
    let v: Int?
    let bar: Int?
    let g: Int?
    let hc: Int?
    let h: Int?
    let jbf: String?
    let ip: Double?
    let f: Int?
    let fn: String?
    let note: String?
    let dish: String?
    let seas: String?
    let liq: String?
    let w: String?
    let ph: String?
    let lic: [LicenseRecord]?
    /// index into DataFile.islands
    let island: Int?
    /// on DOH's old food permit lists: bit 1 = end of 2011 statewide, bit 2 = Oʻahu 2013 (history only)
    let dh: Int?

    enum CodingKeys: String, CodingKey {
        case id, n, c, cu, t, s, co, a, z, la, lo, b, ch, j, v, bar, g, hc, h, jbf, ip, f, fn, note, dish, seas, liq, w, ph, lic, dh
        case island = "is"
    }
}

// MARK: - The model the views use

struct PlaceTags: OptionSet, Hashable {
    let rawValue: Int
    // the guide tags are set only on hand-checked places (open, with a 2025–26 source); the order is pipeline/hawaii.py's TAGS
    static let plateLunch = PlaceTags(rawValue: 1)
    static let poke = PlaceTags(rawValue: 2)
    static let saimin = PlaceTags(rawValue: 4)
    static let shaveIce = PlaceTags(rawValue: 8)
    static let malasada = PlaceTags(rawValue: 16)     // malasadas and the old bakeries
    static let hawaiian = PlaceTags(rawValue: 32)     // laulau, kalua pig, poi
    static let okazuya = PlaceTags(rawValue: 64)
    static let locoMoco = PlaceTags(rawValue: 128)
    static let oldest = PlaceTags(rawValue: 256)      // open at this address since 1960 or earlier
    static let lahaina = PlaceTags(rawValue: 512)     // in Lahaina and open again after the Aug 8, 2023 fire
    static let musubi = PlaceTags(rawValue: 1024)     // its own guide since 2026-10-20 (appended, so the bits above keep their meaning)

    static let guides: PlaceTags = [.plateLunch, .poke, .saimin, .shaveIce, .malasada, .hawaiian, .okazuya, .locoMoco, .musubi, .oldest, .lahaina]
}

/// How a place got on the list. The share that matched an official record comes from calibration.
enum Tier: Int, Comparable {
    case listing = 0        // one map listing
    case confirmed = 1      // a high-confidence Meta listing, or a hand-checked place
    case licensed = 2       // on a current official record (a county liquor license; none are loaded today)

    static func < (a: Tier, b: Tier) -> Bool { a.rawValue < b.rawValue }

    var label: String {
        switch self {
        case .licensed: "On an official record"
        case .confirmed: "Confirmed listing"
        case .listing: "Listing only"
        }
    }
}

enum Jurisdiction: Int {
    case none = 0, abc = 1
    var listName: String {
        switch self {
        case .abc: "County liquor licenses"
        case .none: ""
        }
    }
}

struct Place: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String?
    let city: String?
    let county: String?
    let island: String?
    /// on DOH's 2011 statewide (bit 1) or 2013 Oʻahu (bit 2) food permit list: history, not proof it's open today
    let dohHistory: Int
    let zip: String?
    let coordinate: CLLocationCoordinate2D?
    let cuisine: String
    let brand: String?
    let chainCount: Int
    let tier: Tier
    let jurisdiction: Jurisdiction
    let source: String
    let isVenue: Bool
    let isBar: Bool
    let tags: PlaceTags
    /// On our hand-checked list (data/research): confirmed open with a 2025–26 source.
    let handChecked: Bool
    let honorFlags: Int
    let iconicPoints: Double?
    let jamesBeard: String?
    let founded: Int?
    let foundedNote: String?
    let note: String?
    let dishes: String?
    let seasonal: String?
    /// on-premises county liquor license type; nil means unknown, not "no"
    let liquor: String?
    let website: URL?
    let phone: String?
    let licenses: [LicenseRecord]
    /// normalized text for search: name, town, county, zip, cuisine, brand, dishes, then the address with street words abbreviated
    let searchText: String
    let nameText: String
    /// the A-to-Z key, worked out once at load: the normalized name ("por wine house" for "/pôr/ Wine House"), so case, accents
    /// and leading punctuation don't change the order, and a sort never runs a localized compare per comparison
    let sortKey: String
    /// made once at load: a new CLLocation per comparison made a Nearest sort of 16,000 places take seconds
    let location: CLLocation?

    static func == (a: Place, b: Place) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    /// James Beard or a verified founding year: what the map and Spotlight put first (Hawaii has no MICHELIN Guide)
    var isHonored: Bool { honorFlags != 0 }
    /// what the Honors section lists: a James Beard honor ("oldest" alone isn't an honor)
    var hasHonors: Bool { jamesBeard != nil }
    var isChain: Bool { chainCount >= 5 }
    var jamesBeardLabel: String? {
        if honorFlags & 1 != 0 { return "America's Classic" }
        if honorFlags & 2 != 0 { return "James Beard winner" }
        if honorFlags & 4 != 0 { return "James Beard nominee" }
        if honorFlags & 8 != 0 { return "James Beard semifinalist" }
        return nil
    }
    /// The chip for a James Beard line: the place's own honor, or a restaurateur (group) honor when that's the only one.
    var jamesBeardChip: String? { jamesBeardLabel ?? (jamesBeard != nil ? "James Beard (restaurateur)" : nil) }
    /// a hand-checked Hawaii pick: the hibiscus pins
    var isClassic: Bool { handChecked && !tags.isDisjoint(with: .guides) }
    var townLine: String { [city, cuisine].compactMap { $0 }.joined(separator: " · ") }
    var fullAddress: String {
        [address, [city, zip].compactMap { $0 }.joined(separator: " ")].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    /// "Serves alcohol": never a bare dash that reads as "no". Hawaii's liquor licenses are issued by four county commissions and
    /// none publishes a list the app can read, so today this is unknown for every place.
    var servesAlcohol: String {
        if let liquor { return "Yes · \(liquor)" }
        if !licenses.isEmpty { return "Retail license only" }
        return "Unknown (Hawaii's county liquor lists aren't in the app)"
    }
    /// "On DOH's 2011 food permit list" etc., or nil
    var dohHistoryText: String? {
        switch dohHistory {
        case 1: "On DOH's end-of-2011 food permit list"
        case 2: "On DOH's 2013 Oʻahu food permit list"
        case 3: "On DOH's 2011 and 2013 food permit lists"
        default: nil
        }
    }

    init(_ r: PlaceRecord, file: DataFile) {
        let city = r.c.flatMap { $0 < file.cities.count ? file.cities[$0] : nil }
        let cuisine = r.cu < file.cuisines.count ? file.cuisines[r.cu] : "American & Other"
        let brand = r.b.flatMap { $0 < file.brands.count ? file.brands[$0] : nil }
        let county = r.co.flatMap { $0 < file.counties.count ? file.counties[$0] : nil }
        let islands = file.islands ?? []
        let island = r.island.flatMap { $0 < islands.count ? islands[$0] : nil }
        id = r.id
        name = r.n
        address = r.a
        self.city = city
        self.county = county
        self.island = island
        dohHistory = r.dh ?? 0
        zip = r.z
        if let la = r.la, let lo = r.lo { coordinate = CLLocationCoordinate2D(latitude: la, longitude: lo) } else { coordinate = nil }
        self.cuisine = cuisine
        self.brand = brand
        chainCount = r.ch ?? 1
        tier = Tier(rawValue: r.t) ?? .listing
        jurisdiction = Jurisdiction(rawValue: r.j ?? 0) ?? .none
        source = r.s < file.srcs.count ? file.srcs[r.s] : "meta"
        isVenue = r.v == 1
        isBar = r.bar == 1
        tags = PlaceTags(rawValue: r.g ?? 0)
        handChecked = r.hc == 1
        honorFlags = r.h ?? 0
        iconicPoints = r.ip
        jamesBeard = r.jbf
        founded = r.f
        foundedNote = r.fn
        note = r.note
        dishes = r.dish
        seasonal = r.seas
        liquor = r.liq
        // web links only: a bare host gets https://, and any other scheme (javascript:, tel:, a custom app URL) is dropped
        website = r.w.flatMap { URL(string: $0.contains("://") ? $0 : "https://" + $0) }
            .flatMap { ["http", "https"].contains($0.scheme?.lowercased() ?? "") && $0.host != nil ? $0 : nil }
        phone = r.ph
        licenses = r.lic ?? []
        // the dishes a hand-checked place serves are searchable too: "laulau kaneohe", "dry mein"; the island too ("maui poke")
        searchText = " " + Search.normalize([r.n, city, island, county, r.z, cuisine, brand, r.dish].compactMap { $0 }.joined(separator: " ")) + " "
            + Search.normalizeAddress(r.a ?? "") + " "
        nameText = " " + Search.normalize([r.n, brand].compactMap { $0 }.joined(separator: " ")) + " "
        sortKey = Search.normalize(r.n)
        location = coordinate.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
    }
}

/// The data's dates are calendar days ("2026-06-16"), not moments: read and shown in UTC, so no time zone can move one a day.
enum DayFormat {
    private static let utc = TimeZone(identifier: "UTC")!

    static func date(_ s: String?) -> Date? {
        guard let s, s.count >= 10 else { return nil }
        let parts = s.prefix(10).split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...12).contains(parts[1]), (1...31).contains(parts[2]) else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        return cal.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// "Jun 16, 2026" (in the reader's language); anything that isn't a date is shown as it is
    static func text(_ s: String?) -> String? {
        guard let s else { return nil }
        guard let d = date(s) else { return s }
        return d.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: utc))
    }

    /// "Sep 2025"
    static func monthYear(_ s: String?) -> String? {
        guard let s else { return nil }
        guard let d = date(s) else { return s }
        return d.formatted(Date.FormatStyle(timeZone: utc).month(.abbreviated).year())
    }
}
