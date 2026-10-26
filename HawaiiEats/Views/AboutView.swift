import SwiftUI

struct AboutView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("HAWAIʻI EATS").displayFont(30).foregroundStyle(Theme.green)
                    Text("A free guide to \(model.restaurantCount.formatted()) restaurants on Oʻahu, Maui, Hawaiʻi Island, Kauaʻi, Molokaʻi and Lānaʻi, with hand-checked lists of plate lunch counters, poke, saimin, shave ice, malasadas and bakeries, Hawaiian food and okazuya, musubi, loco moco, Lahaina's reopened places and the oldest places, plus Hawaii's James Beard honorees. No account, no ads, no tracking.")
                        .font(.subheadline).foregroundStyle(Theme.ink2)
                    Text("Hawaiʻi Eats is an independent app by Nicholas Soderstrom. It is not affiliated with, endorsed by or operated by the State of Hawaii, the Hawaii State Department of Health, the Hawaii Statewide GIS Program, any county or county liquor commission, the Hawaiʻi Tourism Authority, the U.S. Geological Survey, the James Beard Foundation, Apple, or any restaurant, university or chain.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                .padding(.vertical, 4)
            }
            Section("How the lists are built") {
                Text("Every guide on the home screen is hand-checked: each place was checked against a 2025 or 2026 source (the place's own website or menu, or local news), with the address checked. Founding years mean the year it opened at this address. The Aug 8, 2023 fire destroyed most of Lahaina: places there are listed only when a 2025 or 2026 source shows them open.")
                Text("Honors are James Beard Foundation awards, nominations and semifinalists, plus America's Classics. Hawaii has no MICHELIN Guide.")
                Text(listingsText)
                Text("The Hawaii State Department of Health inspects every food business on every island and posts a color-coded placard at the door: green (pass), yellow (conditional pass, with a follow-up inspection) or red (closed). It publishes results one search at a time, not in bulk, so this app shows no inspection results and gives no grade of its own. Each place links to DOH's food safety page.")
                Text("Ratings, reviews, hours and photos are Apple Maps' own, shown live in Apple's place card. This app doesn't store or rank by them.")
            }
            .font(.subheadline).foregroundStyle(Theme.ink2)
            Section("Sources") {
                source("Overture Maps Foundation", "Restaurant listings and websites come from Overture Maps Foundation places data (overturemaps.org)\(model.overtureRelease.map { ", release \($0)" } ?? ""), filtered and reformatted for this app.\n• Data from Meta, Microsoft, DAC and BrightQuery. Available under CDLA Permissive 2.0.\n• Data from Foursquare. \(foursquareCopyright) Available under Apache 2.0. Foursquare data was transformed to the Overture schema; this app further filtered and reformatted it. See the NOTICE below.\n• Data from AllThePlaces. Available under CC0 1.0.", "https://overturemaps.org")
                source("Hawaii Statewide GIS Program", "Island coastlines (from U.S. Geological Survey line graphs) and 2020 Census places and county lines, used to put each place on its island and in its town. The State does not endorse this app.", "https://planning.hawaii.gov/gis/")
                source("U.S. Geological Survey, Geographic Names", "The official spelling of each town, with the ʻokina and kahakō (as approved by the Hawaii Board on Geographic Names). Public domain.", "https://www.usgs.gov/us-board-on-geographic-names")
                source("Hawaii State Department of Health", "Its food permit lists from 2011 (statewide) and 2013 (Oʻahu), published on the State's open data portal, show that a place has history here; they can't show it's open today. Permit holders' names and phone numbers are never shown.", "https://health.hawaii.gov/san/")
                source("U.S. Census Bureau Geocoder", "Puts researched addresses on the map. Public domain.", "https://geocoding.geo.census.gov")
                source("Honors", "James Beard Foundation awards, nominees, semifinalists and America's Classics are reported as facts and checked by hand against the Foundation's announcements. James Beard Foundation and James Beard Award are trademarks of the James Beard Foundation. Other names belong to their owners.", "https://www.jamesbeard.org/awards")
                source("Maps", "Maps, place cards and directions by Apple Maps.", nil)
            }
            Section("Licenses") {
                NavigationLink("Community Data License Agreement – Permissive 2.0") { LicenseText(file: "CDLA-Permissive-2.0", title: "CDLA Permissive 2.0") }
                NavigationLink("Apache License 2.0") { LicenseText(file: "Apache-2.0", title: "Apache License 2.0") }
                NavigationLink("Foursquare OS Places NOTICE") { LicenseText(file: "Foursquare-NOTICE", title: "Foursquare NOTICE") }
            }
            Section("Privacy") {
                Text("The app collects nothing. Your location, if you allow it, only sorts lists by distance and shows where you are on the map, on this device. Saved places stay on this device.")
                    .font(.subheadline).foregroundStyle(Theme.ink2)
                DataUpdatesNote()
                    .font(.footnote).foregroundStyle(Theme.muted)
                Link("Privacy policy", destination: Links.privacy)
                Link("Terms of use", destination: Links.terms)
            }
            Section("Help") {
                Link("Report a missing or closed place", destination: Links.correctionEmail)
                Link("Email \(Links.supportEmail)", destination: URL(string: "mailto:\(Links.supportEmail)")!)
                Link("Website", destination: Links.site)
                Text("Data as of \(DayFormat.text(model.generated) ?? model.generated). Places open and close; check before you go. Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
        }
        .navigationTitle("About")
        .tint(Theme.green)
    }

    /// the copyright line exactly as the bundled Foursquare NOTICE has it, so the two can't disagree
    private var foursquareCopyright: String {
        guard let url = Bundle.main.url(forResource: "Foursquare-NOTICE", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8),
              let line = text.split(separator: "\n").first(where: { $0.hasPrefix("©") }) else { return "© Foursquare Labs, Inc. All rights reserved." }
        return line.trimmingCharacters(in: .whitespaces)
    }

    private var listingsText: String {
        let rate = model.calibration?.reference_colorado_denver?.groups?["meta_high"].map { "\(Int(($0.official * 100).rounded()))%" }
        let tested = rate.map { " Tested against Denver's full list of food licenses (the same map data, in Colorado), high-confidence listings matched a licensed business \($0) of the time." } ?? ""
        return "The rest come from Overture Maps' open place data. High-confidence map listings are kept; single listings are marked Listing only.\(tested) Website links are checked, and any that no longer belong to the place are left out."
    }

    @ViewBuilder
    private func source(_ name: String, _ detail: String, _ url: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let url, let u = URL(string: url) { Link(name, destination: u).font(.subheadline.weight(.semibold)) }
            else { Text(name).font(.subheadline.weight(.semibold)) }
            Text(detail).font(.caption).foregroundStyle(Theme.muted)
        }
    }
}

/// A bundled license text (Resources/Licenses), reflowed rather than shown as raw 80-column lines.
struct LicenseText: View {
    let file: String
    let title: String

    var body: some View {
        ScrollView {
            Text(text).font(.footnote).foregroundStyle(Theme.ink).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .inlineTitle(title)
    }

    private var text: String {
        guard let url = Bundle.main.url(forResource: file, withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return "License text missing." }
        // join hard-wrapped lines into paragraphs; keep blank lines and list items as breaks
        var out: [String] = []
        for para in raw.components(separatedBy: "\n\n") {
            let lines = para.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            var joined = ""
            for l in lines where !l.isEmpty {
                let startsItem = l.hasPrefix("–") || l.hasPrefix("-") || l.range(of: #"^\(?[a-z0-9]{1,3}[.)]\s"#, options: .regularExpression) != nil
                joined += joined.isEmpty ? l : (startsItem ? "\n" + l : " " + l)
            }
            if !joined.isEmpty { out.append(joined) }
        }
        return out.joined(separator: "\n\n")
    }
}
