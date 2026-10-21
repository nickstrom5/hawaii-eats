import SwiftUI
import MapKit

struct PlaceDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(LocationService.self) private var location
    let place: Place

    @State private var mapItem: MKMapItem?
    @State private var lookingUp = false
    @State private var notOnAppleMaps = false
    @State private var appleMapsFailed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                actions
                if let c = place.coordinate { mapSnippet(c) }
                if place.handChecked && (place.note != nil || place.dishes != nil || place.founded != nil || place.seasonal != nil) { checked }
                if place.hasHonors { honors }
                inspections
                if model.licenseCount > 0 { records }
                listing
            }
            .padding(16)
        }
        .background(Theme.surface)
        .inlineTitle(place.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { model.toggleSaved(place) } label: {
                    Label(model.isSaved(place) ? "Saved" : "Save", systemImage: model.isSaved(place) ? "heart.fill" : "heart")
                }
                ShareLink(item: shareText) { Label("Share", systemImage: "square.and.arrow.up") }
            }
        }
        .mapItemDetailSheet(item: $mapItem)
        .alert("Not on Apple Maps", isPresented: $notOnAppleMaps) {
            Button("Open Apple Maps anyway") { AppleMaps.openInMaps(place) }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Apple Maps doesn't have a listing for \(place.name) at this spot, so there are no ratings or hours to show here.")
        }
        .alert("Couldn't reach Apple Maps", isPresented: $appleMapsFailed) {
            Button("Try again") { lookUp() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Check your connection and try again.")
        }
    }

    /// Apple's place card for this place; "not on Apple Maps" only when Apple answered and had no listing here.
    private func lookUp() {
        lookingUp = true
        Task {
            let result = await AppleMaps.findItem(for: place)
            lookingUp = false
            switch result {
            case .found(let item): mapItem = item
            case .notListed: notOnAppleMaps = true
            case .failed: appleMapsFailed = true
            }
        }
    }

    // MARK: sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            // "HONOLULU · OʻAHU"
            Text((place.city ?? "Hawaii").uppercased() + (place.island.map { " · " + $0.uppercased() } ?? ""))
                .font(.caption.weight(.bold)).tracking(1.2).foregroundStyle(Theme.green2)
            Text(place.name.uppercased())
                .displayFont(38).foregroundStyle(Theme.green)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text([place.fullAddress, place.cuisine].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.subheadline).foregroundStyle(Theme.ink2)
                .textSelection(.enabled)
            if let here = model.screenshotLocation ?? location.location, let l = place.location {
                Text("\(here.milesText(to: l)) away").font(.subheadline).foregroundStyle(Theme.muted)
            }
            PlaceChips(place: place)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button { lookUp() } label: {
                HStack {
                    if lookingUp { ProgressView().tint(Theme.green) } else { Image(systemName: "star.bubble") }
                    Text("Ratings, hours & photos").fontWeight(.semibold)
                    Spacer()
                    Text("Apple Maps").font(.caption).foregroundStyle(Theme.green2)
                }
                .padding(14)
                .foregroundStyle(Theme.green)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.gold))
            }
            .disabled(place.coordinate == nil || lookingUp)
            .accessibilityHint("Opens the Apple Maps place card with current ratings and hours")

            HStack(spacing: 10) {
                actionButton("Directions", "arrow.triangle.turn.up.right.diamond") { AppleMaps.openInMaps(place, directions: true) }
                if let phone = place.phone, let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
                    actionButton("Call", "phone") { UIApplication.shared.open(url) }
                }
                if let web = place.website {
                    actionButton("Website", "safari") { UIApplication.shared.open(web) }
                }
            }
        }
    }

    private func actionButton(_ title: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(Theme.green)
            .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.rule2))
        }
    }

    private func mapSnippet(_ c: CLLocationCoordinate2D) -> some View {
        Map(initialPosition: .region(MKCoordinateRegion(center: c, latitudinalMeters: 900, longitudinalMeters: 900)), interactionModes: []) {
            Marker(place.name, systemImage: place.tags.contains(.poke) ? "fish.fill" : place.tags.contains(.shaveIce) ? "snowflake" : "fork.knife", coordinate: c).tint(Theme.green)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture { AppleMaps.openInMaps(place) }
        .accessibilityLabel("Map of \(place.name). Opens Apple Maps.")
        .accessibilityAddTraits(.isButton)
    }

    private var checked: some View {
        section("Hand-checked") {
            VStack(alignment: .leading, spacing: 8) {
                if let note = place.note { Text(note).font(.subheadline).foregroundStyle(Theme.ink2) }
                if let d = place.dishes { fact("On the menu", d.components(separatedBy: "; ").joined(separator: ", ")) }
                if let f = place.founded {
                    fact("Open here since", "\(f)")
                    // the note explains the year; without a year it only repeated the description above
                    if let fn = place.foundedNote { Text(fn).font(.caption).foregroundStyle(Theme.ink2) }
                }
                if let sea = place.seasonal { fact("Season", sea) }
                Text("Checked by hand against a 2025 or 2026 source: the place's own site or menu, or local news. Menus and seasons change, and resort-town places close between seasons, so check before you go.")
                    .font(.caption).foregroundStyle(Theme.ink2)
            }
        }
    }

    private var honors: some View {
        section("Honors") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(lines(place.jamesBeard, prefix: "James Beard: "), id: \.self) { l in
                    Label(l, systemImage: "rosette").font(.subheadline).foregroundStyle(Theme.ink)
                }
                Text("Honors are facts, not ratings. James Beard Foundation and James Beard Award are trademarks of the James Beard Foundation.")
                    .font(.caption).foregroundStyle(Theme.muted)
            }
        }
    }

    /// Hawaii's DOH posts a placard at every food business but publishes no results in bulk: explain the placard and point to DOH.
    private var inspections: some View {
        section("Health inspections") {
            VStack(alignment: .leading, spacing: 8) {
                Text("The Hawaii State Department of Health inspects this place and posts a color-coded placard at the door. DOH publishes results one search at a time, not in bulk, so this app has no inspection results.")
                    .font(.subheadline).foregroundStyle(Theme.ink2)
                ForEach(HealthInspections.placards, id: \.color) { p in kv(p.color, p.meaning) }
                Link("DOH Food Safety Branch: placards and inspection search", destination: HealthInspections.page).font(.subheadline.weight(.semibold))
            }
        }
    }

    private var records: some View {
        section("Official records") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(place.licenses, id: \.self) { l in
                    kv(l.src, [l.type, Self.unbroken(l.id), expires(l)].compactMap { $0 }.joined(separator: " · "))
                }
                kv("Serves alcohol", place.servesAlcohol)
                Text(recordsNote).font(.caption).foregroundStyle(Theme.muted)
            }
        }
    }

    private var listing: some View {
        section("How we know it's here") {
            VStack(alignment: .leading, spacing: 8) {
                kv("Listed as", place.tier.label)
                if place.tier == .licensed { kv("Official record", place.jurisdiction.listName) }
                if let i = place.island { kv("Island", i) }
                if place.chainCount >= 2 { kv("Locations in Hawaii", place.chainCount.formatted()) }
                if let h = place.dohHistoryText { kv("History", h) }
                Text(listingNote).font(.caption).foregroundStyle(Theme.muted)
            }
        }
    }

    /// A license on the state's active list stays valid while its renewal is pending, so only a date on or after the list's own
    /// date is shown (the pipeline already leaves the others out; an older data file had them).
    private func expires(_ l: LicenseRecord) -> String? {
        guard let exp = l.exp, let updated = model.liquorUpdated, exp >= updated, let text = DayFormat.text(exp) else { return nil }
        return "expires " + text
    }

    /// a license number with non-breaking hyphens, so it never wraps in the middle
    private static func unbroken(_ id: String) -> String { id.replacingOccurrences(of: "-", with: "\u{2011}") }

    /// Where the records above come from.
    private var recordsNote: String {
        if place.licenses.isEmpty {
            return "No county liquor license matched this place. A missing record means unknown, not unlicensed."
        }
        return "From a county liquor commission's licensee list" + (DayFormat.text(model.liquorUpdated).map { " (as of \($0))" } ?? "") + "."
    }

    private var listingNote: String {
        let checked = place.handChecked
        if place.source == "research" {
            return "On our hand-checked list (checked against a 2025 or 2026 source). The open map data didn't list it as a place to eat, so it's placed from its own map listing or street address."
        }
        switch place.tier {
        case .licensed:
            return place.source == "official"
                ? "From the \(place.jurisdiction.listName). The open map data didn't have it, so its location comes from the record's street address."
                : "Matched to the \(place.jurisdiction.listName)."
        case .confirmed, .listing:
            let rate = model.matchRate(for: place)
            let base = place.tier == .confirmed
                ? "A high-confidence listing in Overture's open map data."
                : "A single listing in Overture's open map data, so it may be closed or misfiled."
            let measured = rate.map { " In a test against Denver's full list of food licenses (Colorado, same map data), listings like this matched a licensed business \($0) of the time." } ?? ""
            return base + measured + (checked ? " It's also on our hand-checked list, checked against a 2025 or 2026 source." : "")
        }
    }

    // MARK: helpers

    private var shareText: String {
        [place.name, place.fullAddress, "via Hawaiʻi Eats", Links.site.absoluteString].filter { !$0.isEmpty }.joined(separator: "\n")
    }

    private func lines(_ s: String?, prefix: String) -> [String] {
        (s ?? "").components(separatedBy: "; ").filter { !$0.isEmpty }.map { prefix + $0 }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(.caption.weight(.bold)).tracking(1).foregroundStyle(Theme.ink2)
            Divider()
            content()
        }
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
            Text(value).font(.subheadline).foregroundStyle(Theme.ink2)
        }
    }

    @ViewBuilder
    private func kv(_ k: String, _ v: String?) -> some View {
        if let v {
            HStack(alignment: .firstTextBaseline) {
                Text(k).font(.subheadline).foregroundStyle(Theme.ink2)
                Spacer(minLength: 12)
                Text(v).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.trailing)
            }
        }
    }
}

extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
