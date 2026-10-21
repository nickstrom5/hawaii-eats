import XCTest
import CoreLocation
@testable import HawaiiEats

@MainActor
final class HawaiiEatsTests: XCTestCase {

    /// A tiny data file with the same shape as Resources/places.json. The places are fictional; the real ones are checked in
    /// testBundledData.
    private func sampleModel() async throws -> AppModel {
        let json = """
        {"v":1,"generated":"2026-10-19","liquor_updated":null,"licenses":0,
         "cities":["Honolulu","Kāneʻohe","Hilo","Haleʻiwa","Kailua","Kailua-Kona","Līhuʻe","Lahaina","Kīhei","Waipahu"],
         "cuisines":["Hawaiian & Local","Poke","Bakery & Sweets","Coffee & Café","American & Other","Japanese & Sushi","Bar & Pub"],
         "brands":["Starbucks"],"counties":["Honolulu County","Hawaiʻi County","Kauaʻi County","Maui County"],
         "islands":["Kauaʻi","Niʻihau","Oʻahu","Molokaʻi","Lānaʻi","Maui","Hawaiʻi"],
         "srcs":["official","meta","AllThePlaces","DAC","research"],"count":12,"count_restaurants":11,
         "calibration":{"groups":{"meta >= 0.95":{"n":3215,"doh2011":0.323}},
                        "reference_colorado_denver":{"groups":{"meta_high":{"n":1885,"official":0.759},"meta_mid":{"n":342,"official":0.319}}}},
         "places":[
          {"id":"a","n":"Kapahulu Plate Lunch","c":0,"co":0,"is":2,"cu":0,"t":1,"s":1,"hc":1,"a":"3100 Kapahulu Ave","z":"96815","la":21.2780,"lo":-157.8130,"g":1,
           "dish":"loco moco; teriyaki beef","dh":1},
          {"id":"b","n":"Windward Poke Counter","c":1,"co":0,"is":2,"cu":1,"t":1,"s":1,"hc":1,"a":"45-1000 Kamehameha Hwy","la":21.4100,"lo":-157.8000,"g":2,"dish":"shoyu ahi"},
          {"id":"c","n":"Starbucks","c":0,"co":0,"is":2,"cu":3,"t":1,"s":2,"b":0,"ch":75,"la":21.29,"lo":-157.84},
          {"id":"d","n":"Poke Shack Hilo","c":2,"co":1,"is":6,"cu":1,"t":0,"s":1,"a":"100 Kamehameha Ave","la":19.72,"lo":-155.08},
          {"id":"e","n":"Foodland","c":0,"co":0,"is":2,"cu":4,"t":1,"s":1,"v":1,"la":21.30,"lo":-157.85},
          {"id":"f","n":"North Shore Shave Ice","c":3,"co":0,"is":2,"cu":2,"t":1,"s":1,"hc":1,"a":"66-100 Kamehameha Hwy","la":21.5930,"lo":-158.1030,"g":8},
          {"id":"g","n":"Old Hilo Saimin","c":2,"co":1,"is":6,"cu":0,"t":1,"s":1,"hc":1,"a":"10 Haili St","la":19.722,"lo":-155.088,"g":260,"h":17,"ip":56,"f":1950,
           "jbf":"America's Classics 2025","dish":"saimin; dry mein"},
          {"id":"h","n":"Kona Malasada","c":5,"co":1,"is":6,"cu":2,"t":1,"s":1,"hc":1,"a":"75-5700 Aliʻi Dr","la":19.64,"lo":-155.99,"g":16},
          {"id":"i","n":"Līhuʻe Sushi","c":6,"co":2,"is":0,"cu":5,"t":1,"s":1,"hc":1,"a":"4300 Rice St","la":21.975,"lo":-159.37,"h":2,"ip":40,
           "jbf":"Best Chef: Northwest and Pacific winner 2025 (A. Chef)"},
          {"id":"j","n":"Front Street Grill","c":7,"co":3,"is":5,"cu":4,"t":1,"s":1,"hc":1,"a":"600 Front St","la":20.871,"lo":-156.678,"g":512},
          {"id":"k","n":"Kailua Beach Pub","c":4,"co":0,"is":2,"cu":6,"t":1,"s":1,"a":"130 Kailua Rd","la":21.397,"lo":-157.74},
          {"id":"l","n":"Kakaʻako Musubi Bar","c":0,"co":0,"is":2,"cu":5,"t":1,"s":1,"hc":1,"a":"600 Cooke St","la":21.297,"lo":-157.858,"g":1152,"dish":"ume musubi"}
         ]}
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("places-test.json")
        try json.data(using: .utf8)!.write(to: url)
        let model = AppModel(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        await model.load(from: url)
        XCTAssertTrue(model.isLoaded, model.loadError ?? "")
        return model
    }

    func testDecodesAndHidesNonRestaurantsByDefault() async throws {
        let m = try await sampleModel()
        XCTAssertEqual(m.places.count, 12)
        XCTAssertNil(m.liquorUpdated)
        XCTAssertEqual(m.place(id: "a")!.island, "Oʻahu")
        XCTAssertEqual(m.place(id: "a")!.dohHistoryText, "On DOH's end-of-2011 food permit list")
        let all = m.list(.all, sort: .name, search: "", here: nil)
        XCTAssertFalse(all.contains { $0.name == "Foodland" }, "grocery counters are hidden unless asked for")
        m.filters.includeNonRestaurants = true
        XCTAssertTrue(m.list(.all, sort: .name, search: "", here: nil).contains { $0.name == "Foodland" })
    }

    func testGuidesListOnlyWhatTheyPromise() async throws {
        let m = try await sampleModel()
        func ids(_ g: Guide, _ sort: HawaiiEats.SortOrder = .name) -> [String] { m.list(g, sort: sort, search: "", here: nil).map(\.id) }
        XCTAssertEqual(ids(.poke), ["b"], "a listing merely named \u{201C}Poke Shack\u{201D} isn't hand-checked, so it stays out of the guide")
        XCTAssertEqual(m.list(.all, sort: .name, search: "poke shack", here: nil).map(\.id), ["d"], "but it's still in the directory")
        XCTAssertEqual(ids(.plateLunch), ["a"])
        XCTAssertEqual(ids(.shaveIce), ["f"])
        XCTAssertEqual(ids(.saimin), ["g"])
        XCTAssertEqual(ids(.malasadas), ["h"])
        XCTAssertEqual(ids(.lahaina), ["j"])
        XCTAssertEqual(ids(.musubi), ["l"], "musubi is its own guide")
        XCTAssertEqual(ids(.locoMoco), ["l"], "a place tagged both (bits 128 and 1024) is in both guides")
        XCTAssertEqual(ids(.honors, .iconic), ["g", "i"], "an America's Classic comes before a winner: an order anyone can check")
        XCTAssertEqual(ids(.oldest, .oldest), ["g"])
        XCTAssertEqual(m.list(.nearMe, sort: .nearest, search: "", here: nil), [], "near me needs a location")
    }

    /// Hawaii publishes no inspection results in bulk: no guide claims any, and the placard explainer covers the three colors.
    func testNoInspectionsAndThePlacardIsExplained() {
        XCTAssertFalse(Guide.allCases.contains { $0.title.localizedCaseInsensitiveContains("inspection") })
        XCTAssertEqual(HealthInspections.placards.map(\.color), ["Green", "Yellow", "Red"])
        XCTAssertEqual(HealthInspections.page.host, "health.hawaii.gov", "DOH's own page, not the search site that keeps automated agents out")
    }

    /// Calendar days stay the same day in every time zone, and read as dates, not ISO strings.
    func testDatesAreCalendarDays() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let d = DayFormat.date("2026-06-16")!
        XCTAssertEqual(utc.dateComponents([.year, .month, .day], from: d), DateComponents(year: 2026, month: 6, day: 16))
        let text = DayFormat.text("2026-06-16")!
        XCTAssertTrue(text.contains("16") && text.contains("2026") && !text.contains("2026-06"), text)
        XCTAssertTrue(DayFormat.monthYear("2025-09-04")!.contains("2025"))
        XCTAssertNil(DayFormat.text(nil))
        XCTAssertEqual(DayFormat.text("soon"), "soon", "a value that isn't a date is shown as it is")
        XCTAssertNil(DayFormat.date("2026-13-01"))
        let boston = CLLocation(latitude: 42.3601, longitude: -71.0589), honolulu = CLLocation(latitude: 21.3087, longitude: -157.8610)
        let mi = Int((boston.distance(from: honolulu) / 1609.344).rounded())
        XCTAssertEqual(boston.milesText(to: honolulu), mi.formatted() + " mi", "miles are grouped for the reader's locale (\u{201C}5,090 mi\u{201D})")
        XCTAssertEqual(honolulu.milesText(to: honolulu), 0.0.formatted(.number.precision(.fractionLength(1))) + " mi")
    }

    /// The in-state test uses each island's outline: the ocean between the islands is outside.
    func testOutsideHawaii() {
        func inside(_ la: Double, _ lo: Double) -> Bool { LocationService.inHawaii(CLLocationCoordinate2D(latitude: la, longitude: lo)) }
        XCTAssertTrue(inside(21.3087, -157.8610), "downtown Honolulu")
        XCTAssertTrue(inside(19.7241, -155.0868), "Hilo")
        XCTAssertTrue(inside(21.9811, -159.3711), "Līhuʻe")
        XCTAssertTrue(inside(20.7984, -156.3319), "Kīhei")
        XCTAssertTrue(inside(21.0905, -157.0226), "Kaunakakai")
        XCTAssertTrue(inside(20.8275, -156.9200), "Lānaʻi City")
        XCTAssertTrue(inside(21.2614, -157.8227), "Waikīkī Beach, on the shore")
        XCTAssertFalse(inside(21.10, -157.40), "the Kaiwi Channel between Oʻahu and Molokaʻi")
        XCTAssertFalse(inside(37.33, -122.01), "Cupertino, where App Review usually is")
        XCTAssertFalse(inside(28.20, -177.37), "Midway, a Northwestern island with no restaurants in the app")
    }

    /// "Serves alcohol" never reads as "no": Hawaii's county liquor lists aren't in the app, so it's unknown.
    func testServesAlcohol() async throws {
        let m = try await sampleModel()
        XCTAssertEqual(m.place(id: "k")!.servesAlcohol, "Unknown (Hawaii's county liquor lists aren't in the app)")
        XCTAssertFalse(m.places.contains { $0.servesAlcohol.hasPrefix("—") })
    }

    func testHonorsAreFactsWithTheirOwnLabels() async throws {
        let m = try await sampleModel()
        XCTAssertEqual(m.place(id: "g")!.jamesBeardLabel, "America's Classic")
        XCTAssertEqual(m.place(id: "i")!.jamesBeardLabel, "James Beard winner")
        XCTAssertTrue(m.place(id: "i")!.isHonored)
        XCTAssertFalse(m.place(id: "b")!.hasHonors, "a hand-checked place isn't an honoree")
        XCTAssertNil(m.place(id: "d")!.liquor, "no license matched means unknown, never \u{201C}no\u{201D}")
    }

    func testNearestSort() async throws {
        let m = try await sampleModel()
        let waikiki = CLLocation(latitude: 21.2770, longitude: -157.8260)
        let near = m.list(.nearMe, sort: .nearest, search: "", here: waikiki)
        XCTAssertEqual(near.first?.id, "a", "Kapahulu is closest to Waikīkī")
        let ids = near.map(\.id)
        XCTAssertLessThan(ids.firstIndex(of: "f")!, ids.firstIndex(of: "g")!, "Haleʻiwa comes before Hilo")
    }

    func testSearchWordStartsTownsGuidesAndDishes() async throws {
        let m = try await sampleModel()
        func ids(_ q: String) -> [String] { m.list(.all, sort: .name, search: q, here: nil).map(\.id) }
        XCTAssertEqual(ids("kapahulu"), ["a"])
        XCTAssertTrue(ids("pahulu").isEmpty, "matches the start of words only")
        XCTAssertEqual(ids("kaneohe"), ["b"], "Kāneʻohe without the kahakō or ʻokina")
        XCTAssertEqual(ids("kāneʻohe"), ["b"])
        XCTAssertEqual(ids("kane'ohe"), ["b"], "an apostrophe typed for the ʻokina")
        XCTAssertEqual(ids("lihue"), ["i"])
        XCTAssertEqual(ids("ali'i dr"), ["h"], "the street with an apostrophe for the ʻokina")
        XCTAssertEqual(ids("poke"), ["b", "d"], "the guide's place, and a place named that way")
        XCTAssertEqual(ids("hilo poke"), ["d"], "a town in the query narrows to it")
        XCTAssertEqual(ids("shoyu ahi"), ["b"], "a hand-checked dish is searchable")
        XCTAssertNil(Search.parse("shoyu ahi", towns: [:]).tag, "\u{201C}shoyu ahi\u{201D} is a dish, not a whole guide")
        XCTAssertEqual(ids("malasadas"), ["h"], "plural to singular: the malasada guide")
        XCTAssertEqual(ids("kauai"), ["i"], "the island is searchable")
        XCTAssertEqual(ids("kailua"), ["k"], "Kailua (Oʻahu) isn't Kailua-Kona")
        XCTAssertEqual(ids("kailua kona"), ["h"])
        XCTAssertEqual(ids("🍕"), [], "nothing searchable typed means no results, not everything")
        XCTAssertEqual(ids("!!! ?"), [])
    }

    func testFiltersSavedPlacesAndMatchRates() async throws {
        let m = try await sampleModel()
        m.filters.hideChains = true
        XCTAssertFalse(m.list(.all, sort: .name, search: "", here: nil).contains { $0.name == "Starbucks" })
        m.filters = Filters(confirmedOnly: true)
        XCTAssertFalse(m.list(.all, sort: .name, search: "", here: nil).contains { $0.id == "d" }, "single listings drop out")
        m.filters = Filters(town: "Hilo")
        XCTAssertEqual(Set(m.list(.all, sort: .name, search: "", here: nil).map(\.id)), ["d", "g"])
        m.filters = Filters(island: "Hawaiʻi")
        XCTAssertEqual(Set(m.list(.all, sort: .name, search: "", here: nil).map(\.id)), ["d", "g", "h"])
        m.filters = Filters()
        let p = m.place(id: "b")!
        m.toggleSaved(p)
        XCTAssertEqual(m.savedPlaces.map(\.id), ["b"])
        m.toggleSaved(p)
        XCTAssertTrue(m.savedPlaces.isEmpty)
        XCTAssertEqual(m.matchRate(for: m.place(id: "b")!), "76%", "Colorado's Denver test of the same map data")
        XCTAssertFalse(m.places.contains { $0.tier == .licensed }, "no current official list is loaded in Hawaii")
    }

    func testListCacheFollowsFiltersSearchAndLocation() async throws {
        let m = try await sampleModel()
        let all = m.list(.all, sort: .name, search: "", here: nil)
        XCTAssertTrue(all.contains { $0.name == "Starbucks" })
        m.filters.hideChains = true
        XCTAssertFalse(m.list(.all, sort: .name, search: "", here: nil).contains { $0.name == "Starbucks" }, "a filter change isn't served from the cache")
        m.filters = Filters()
        XCTAssertEqual(m.list(.all, sort: .name, search: "", here: nil).map(\.id), all.map(\.id))
        XCTAssertEqual(m.list(.all, sort: .name, search: "kapahulu", here: nil).map(\.id), ["a"])
        XCTAssertEqual(m.list(.all, sort: .name, search: "", here: nil).map(\.id), all.map(\.id))
        let waikiki = CLLocation(latitude: 21.2770, longitude: -157.8260), hilo = CLLocation(latitude: 19.7230, longitude: -155.0880)
        XCTAssertEqual(m.list(.nearMe, sort: .nearest, search: "", here: waikiki).first?.id, "a")
        XCTAssertEqual(m.list(.nearMe, sort: .nearest, search: "", here: hilo).first?.id, "g", "a new location isn't served from the cache")
    }

    func testNearMeIsntASearchWord() {
        let q = Search.parse("poke near me", towns: ["mililani": "Mililani"])
        XCTAssertEqual(q.tag, .poke)
        XCTAssertNil(q.town)
        XCTAssertTrue(q.tokens.isEmpty, "\"me\" mustn't match Mililani or Mexican places")
    }

    /// The one-pass normalize must agree with the regex version it replaced, on tricky strings and every bundled name and address.
    func testNormalizeMatchesTheRegexVersion() async throws {
        func reference(_ s: String) -> String {
            var t = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .init(identifier: "en_US")).lowercased()
            t = t.replacingOccurrences(of: #"\b([a-z0-9])\s*&\s*([a-z0-9])\b"#, with: "$1$2", options: .regularExpression)
            t = t.replacingOccurrences(of: "&", with: " and ")
            t = t.replacingOccurrences(of: #"['’‘`ʻ]"#, with: "", options: .regularExpression)
            t = t.replacingOccurrences(of: #"[^\p{L}\p{N}]+"#, with: " ", options: .regularExpression)
            return t.trimmingCharacters(in: .whitespaces)
        }
        for s in ["Big Jud's", "B&B Cafe", "Rock & Roll Café", "  Phở 88!! ", "Jud’s", "Joe`s", "A&W", "½ Price", "/pôr/ Wine House",
                  "#vybe", "Kāneʻohe", "Ka‘ana Kitchen", "75-5770 Ali‘i Dr #2-3", "1600 W State St #100", "🍕 Pizza", "Ⅻ Club", "Taquería", "", "---"] {
            XCTAssertEqual(Search.normalize(s), reference(s), s)
        }
        let m = AppModel(defaults: UserDefaults(suiteName: "norm-\(UUID().uuidString)")!)
        await m.load()
        for p in m.places {
            XCTAssertEqual(Search.normalize(p.name), reference(p.name), p.name)
            XCTAssertEqual(Search.normalize(p.fullAddress), reference(p.fullAddress), p.fullAddress)
        }
    }

    /// The real bundled file decodes and holds the guides the app promises.
    func testBundledData() async throws {
        let m = AppModel(defaults: UserDefaults(suiteName: "bundle-\(UUID().uuidString)")!)
        await m.load()
        XCTAssertTrue(m.isLoaded, m.loadError ?? "")
        XCTAssertGreaterThan(m.restaurantCount, 3_500)
        XCTAssertEqual(Set(m.islands.map(\.name)), ["Oʻahu", "Maui", "Hawaiʻi", "Kauaʻi", "Molokaʻi", "Lānaʻi"], "all six inhabited islands")
        for g in HomeView.cards where g.isLocal {
            XCTAssertTrue(m.places.filter(g.includes).allSatisfy(\.handChecked), "\(g.title) lists only hand-checked places")
        }
        XCTAssertEqual(Set(m.places.map(\.id)).count, m.places.count, "ids are unique")
        XCTAssertTrue(m.places.contains { $0.name == "Hamura Saimin" && $0.city == "Līhuʻe" && $0.island == "Kauaʻi" })
        XCTAssertTrue(m.places.contains { $0.name == "Rainbow Drive-In" && $0.city == "Honolulu" })
        // the Aug 8, 2023 fire: a Lahaina place ships only when a 2025-26 source shows it open
        XCTAssertTrue(m.places.filter { $0.city == "Lahaina" }.allSatisfy(\.handChecked), "Lahaina places are hand-checked")
        // Kailua (Oʻahu) and Kailua-Kona are two towns on two islands; Waimea is told apart by island
        XCTAssertTrue(m.places.filter { $0.city == "Kailua" }.allSatisfy { $0.island == "Oʻahu" })
        XCTAssertTrue(m.places.filter { $0.city == "Kailua-Kona" }.allSatisfy { $0.island == "Hawaiʻi" })
        XCTAssertFalse(m.places.contains { $0.city == "Waimea" }, "Waimea is shown with its island")
        // the screenshot script opens these by name
        for n in ScreenshotMode.savedNames + [ScreenshotMode.detailName] {
            XCTAssertTrue(m.places.contains { $0.name.caseInsensitiveCompare(n) == .orderedSame }, "screenshot place \(n) is in the data")
        }
        // no Google-derived data and no inspection results: the data file has none of these fields at all
        let raw = try String(contentsOf: Bundle.main.url(forResource: "places", withExtension: "json")!, encoding: .utf8)
        for key in ["\"rating\"", "\"reviews\"", "\"price\"", "\"gmap_id\"", "\"google21_open\"", "\"in\":", "google"] {
            XCTAssertFalse(raw.lowercased().contains(key.lowercased()), "\(key) must not ship")
        }
    }

    /// The bundled data against the data-hygiene findings of earlier states: adult clubs, directory and news links, mangled towns
    /// and names, lapsed-looking license dates, non-restaurants and places outside the state line.
    func testBundledDataGuards() async throws {
        let m = AppModel(defaults: UserDefaults(suiteName: "guards-\(UUID().uuidString)")!)
        await m.load()
        XCTAssertTrue(m.isLoaded, m.loadError ?? "")
        XCTAssertEqual(DataGuards.adultVenues(m.places), [], "no place at a known strip club's address or under its name")
        XCTAssertEqual(DataGuards.badWebsites(m.places), [], "no directory, Google or news page as a restaurant's website")
        XCTAssertEqual(DataGuards.badTowns(m.places), [], "one official spelling per town (Kāneʻohe, Līhuʻe), none cut short")
        XCTAssertEqual(DataGuards.badNames(m.places), [], "no visible name ending in \u{201C} the\u{201D} or \u{201C} of\u{201D}, or just \u{201C}The\u{201D}")
        XCTAssertEqual(DataGuards.lapsedExpiries(m.places, listDate: m.liquorUpdated), [], "no license expiry before the list's own date")
        XCTAssertEqual(DataGuards.nonRestaurants(m.places), [], "no nail salon, senior home, gun store or gas station among the restaurants")
        XCTAssertEqual(DataGuards.outsideHawaii(m.places), [], "every place on an island")
        XCTAssertEqual(DataGuards.militaryBases(m.places), [], "no on-base food court the public can't reach")
    }

    /// Each guard above fires on a copy of the bundled data broken the way QA found it elsewhere: a guard that can't fail guards
    /// nothing (Colorado's first website check had double backslashes in a raw string and matched nothing).
    func testGuardsCatchABrokenCopy() async throws {
        let raw = try Data(contentsOf: Bundle.main.url(forResource: "places", withExtension: "json")!)
        var file = try XCTUnwrap(JSONSerialization.jsonObject(with: raw) as? [String: Any])
        var places = try XCTUnwrap(file["places"] as? [[String: Any]])
        var cities = try XCTUnwrap(file["cities"] as? [String])
        cities.append("Kaneohe")
        // ordinary visible places, each broken one way
        let idx = places.indices.filter { places[$0]["v"] == nil }.prefix(8).map { $0 }
        places[idx[0]]["w"] = "https://www.yelp.com/biz/some-place"
        places[idx[1]]["w"] = "https://www.staradvertiser.com/2026/01/01/hawaii-news/some-story/"
        places[idx[2]]["a"] = "1673 Kapiolani Boulevard"
        places[idx[2]]["n"] = "Club Femme Nu"
        places[idx[2]]["c"] = try XCTUnwrap(cities.firstIndex(of: "Honolulu"))
        places[idx[3]]["c"] = cities.count - 1
        places[idx[4]]["n"] = "Kitchen the"
        places[idx[5]]["lic"] = [["src": "County liquor license", "id": "0000", "type": "Dispenser", "exp": "2014-05-16"]]
        places[idx[6]]["la"] = 21.10
        places[idx[6]]["lo"] = -157.40
        places[idx[7]]["n"] = "Tipsy Nails & Spa"
        file["places"] = places
        file["cities"] = cities
        if file["liquor_updated"] == nil || file["liquor_updated"] is NSNull { file["liquor_updated"] = "2026-10-08" }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("places-broken.json")
        try JSONSerialization.data(withJSONObject: file).write(to: url)
        let m = AppModel(defaults: UserDefaults(suiteName: "broken-\(UUID().uuidString)")!)
        await m.load(from: url)
        XCTAssertTrue(m.isLoaded, m.loadError ?? "")
        let id = idx.map { places[$0]["id"] as? String }
        func caught(_ found: [String], _ i: Int, _ what: String) {
            XCTAssertTrue(found.contains { $0.contains("[\(id[i] ?? "?")]") }, "the guard missed \(what)")
        }
        caught(DataGuards.badWebsites(m.places), 0, "a Yelp page")
        caught(DataGuards.badWebsites(m.places), 1, "a Star-Advertiser story")
        caught(DataGuards.adultVenues(m.places), 2, "Club Femme Nu at 1673 Kapiolani Boulevard (= Blvd)")
        XCTAssertTrue(DataGuards.badTowns(m.places).contains("Kaneohe"), "the guard missed \u{201C}Kaneohe\u{201D} without its ʻokina")
        caught(DataGuards.badNames(m.places), 4, "\u{201C}Kitchen the\u{201D}")
        caught(DataGuards.lapsedExpiries(m.places, listDate: m.liquorUpdated), 5, "a 2014 expiry")
        caught(DataGuards.outsideHawaii(m.places), 6, "a place in the Kaiwi Channel")
        caught(DataGuards.nonRestaurants(m.places), 7, "a nail salon shown as a restaurant")
    }
}

/// Checks on the bundled data, written as functions so testGuardsCatchABrokenCopy can prove each one fires.
enum DataGuards {
    /// directories, Google and news sites: matched on the link's host, so "smart.com" isn't "rt.com"
    static let badHosts = #"^https?://([^/?#]*\.)?(yelp\.com|business\.site|google\.com|groupon\.com|yellowpages\.com|staradvertiser\.com|civilbeat\.org|hawaiinewsnow\.com|kitv\.com|khon2\.com|mauinews\.com|westhawaiitoday\.com|hawaiitribune-herald\.com|thegardenisland\.com|tripadvisor\.com|rt\.com)([:/?#]|$)"#

    static func badWebsites(_ places: [Place]) -> [String] {
        places.compactMap { p in
            guard let w = p.website?.absoluteString, w.range(of: badHosts, options: [.regularExpression, .caseInsensitive]) != nil else { return nil }
            return "\(p.name) [\(p.id)]: \(w)"
        }
    }

    /// Adult clubs Overture lists in Hawaii (data/research/adult_venues.json): their street address in their town together with
    /// their name (the clubs sit in plazas whose address real restaurants share), and gentlemen's-club names anywhere.
    static let adultAddresses: [(address: String, town: String, name: String)] = [
        ("939 Keeaumoku St", "Honolulu", "Club 939"), ("550 California Ave", "Wahiawā", "Club 550"), ("2266 Kuhio Ave", "Honolulu", "Club Alley Cat"),
        ("1673 Kapiolani Blvd", "Honolulu", "Club Femme Nu"), ("803 Kamehameha Hwy", "Pearl City", "Club 21"),
        ("94-867 Waipahu St", "Waipahu", "Club Blossom"), ("593 Kamehameha Hwy", "Pearl City", "Club Hot Ash"),
        ("1661 Kapiolani Blvd", "Honolulu", "Diamonds"), ("1888 Kalakaua Ave", "Honolulu", "Island Playgirls"),
        ("1770 Kapiolani Blvd", "Honolulu", "Club Rock-Za"), ("1724 Kalauokalani Way", "Honolulu", "Ballarrinas"),
        ("815 Keeaumoku St", "Honolulu", "Club Vegas Star"),
    ]
    static let adultNames = #"gentlem[ae]n['’]?s club|strip club|exotic dancer|femme nu|playgirls|ballarrinas"#

    static func adultVenues(_ places: [Place]) -> [String] {
        // "1673 Kapiolani Boulevard" and "1673 Kapiolani Blvd" are the same address: street words abbreviated, case and punctuation gone
        let wanted = adultAddresses.map { (Search.normalizeAddress($0.address), $0.town, Search.normalize($0.name)) }
        return places.compactMap { p in
            let a = Search.normalizeAddress(p.address ?? ""), n = Search.normalize(p.name)
            let atAddress = !a.isEmpty && wanted.contains { $0.0 == a && $0.1 == p.city && (n.contains($0.2) || $0.2.contains(n)) }
            let named = p.name.range(of: adultNames, options: [.regularExpression, .caseInsensitive]) != nil
            return atAddress || named ? "\(p.name) [\(p.id)], \(p.address ?? "")" : nil
        }
    }

    /// one official spelling per town (Kāneʻohe, never Kaneohe), and every town at least three letters
    static func badTowns(_ places: [Place]) -> [String] {
        let variants: Set = ["Kaneohe", "Kihei", "Lihue", "Haleiwa", "Aiea", "Ewa Beach", "Kapaa", "Paia", "Kailua Kona", "Kamuela",
                             "Waianae", "Koloa", "Lanai City", "Waimea", "Urban Honolulu", "Mililani Town"]
        return Set(places.compactMap(\.city)).filter { t in variants.contains(t) || t.filter(\.isLetter).count < 3 }.sorted()
    }

    /// a name cut off after "the" or "of" ("Kitchen the", "Taste of") or nothing but "The", among the places shown by default
    static func badNames(_ places: [Place]) -> [String] {
        places.filter { p in
            let n = p.name.trimmingCharacters(in: .whitespaces).lowercased()
            return !p.isVenue && (n.hasSuffix(" the") || n.hasSuffix(" of") || n == "the")
        }.map { "\($0.name) [\($0.id)]" }
    }

    /// a license expiry before the list's own date reads as lapsed
    static func lapsedExpiries(_ places: [Place], listDate: String?) -> [String] {
        places.flatMap { p in
            p.licenses.compactMap { l in l.exp.flatMap { e in listDate.map { e < $0 } ?? true ? "\(p.name) [\(p.id)]: \(l.id) \(e)" : nil } }
        }
    }

    /// businesses that aren't places to eat (Colorado's QA: nail bars, senior homes, a gun store, gas stations), among the places
    /// shown by default
    static let nonRestaurantNames = #"\bnails?\b|\bsenior\b|assisted living|firearms|gun (?:shop|store|range)|petroleum|\bcar wash\b"#

    static func nonRestaurants(_ places: [Place]) -> [String] {
        places.filter { !$0.isVenue && $0.name.range(of: nonRestaurantNames, options: [.regularExpression, .caseInsensitive]) != nil }
            .map { "\($0.name) [\($0.id)]" }
    }

    /// every place on an island (a listing geocoded into the sea mustn't ship)
    static func outsideHawaii(_ places: [Place]) -> [String] {
        places.filter { p in p.coordinate.map { !LocationService.inHawaii($0) } ?? false }.map { "\($0.name) [\($0.id)], \($0.city ?? "")" }
    }

    /// on-base food courts (Schofield, Hickam, Pearl Harbor) aren't open to the public
    static func militaryBases(_ places: [Place]) -> [String] {
        places.filter { ["Schofield Barracks", "Hickam", "Pearl Harbor"].contains($0.city ?? "") }.map { "\($0.name) [\($0.id)], \($0.city ?? "")" }
    }
}
