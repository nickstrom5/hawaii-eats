import SwiftUI

struct FiltersSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var townSearch = ""

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section("Island") {
                    Picker("Island", selection: $model.filters.island) {
                        Text("Every island").tag(String?.none)
                        ForEach(model.islands, id: \.name) { i in Text("\(i.name) (\(i.count.formatted()))").tag(String?.some(i.name)) }
                    }
                }
                Section("Town") {
                    NavigationLink {
                        townPicker
                    } label: {
                        HStack {
                            Text("Town"); Spacer()
                            Text(model.filters.town ?? "All of Hawaii").foregroundStyle(Theme.muted)
                        }
                    }
                }
                Section("Cuisine") {
                    Picker("Cuisine", selection: $model.filters.cuisine) {
                        Text("All cuisines").tag(String?.none)
                        ForEach(model.cuisines, id: \.name) { c in Text("\(c.name) (\(c.count.formatted()))").tag(String?.some(c.name)) }
                    }
                }
                Section {
                    Toggle("Hide chains (5+ locations)", isOn: $model.filters.hideChains)
                    Toggle("Only confirmed places", isOn: $model.filters.confirmedOnly)
                    Toggle("Include non-restaurants", isOn: $model.filters.includeNonRestaurants)
                } footer: {
                    Text("Confirmed = a high-confidence map listing or hand-checked by us (Hawaii publishes no current list of food or liquor licenses the app can use). Non-restaurants are grocery and gas-station counters, airport stands, corporate cafeterias, candy and chocolate shops and delivery-only brands.")
                }
                if model.filters.activeCount > 0 {
                    Section { Button("Clear all filters", role: .destructive) { model.filters = Filters() } }
                }
            }
            .inlineTitle("Filters")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }

    private var townPicker: some View {
        let q = Search.normalize(townSearch)
        let towns = model.towns.filter { q.isEmpty || (" " + Search.normalizeAddress($0.name)).contains(" " + Search.normalizeAddress(q)) }
        return List {
            Button { model.filters.town = nil } label: {
                HStack { Text("All of Hawaii"); Spacer(); if model.filters.town == nil { Image(systemName: "checkmark") } }
            }
            ForEach(towns, id: \.name) { t in
                Button { model.filters.town = t.name } label: {
                    HStack {
                        Text(t.name).foregroundStyle(Theme.ink)
                        Spacer()
                        Text(t.count.formatted()).foregroundStyle(Theme.muted).monospacedDigit()
                        if model.filters.town == t.name { Image(systemName: "checkmark").foregroundStyle(Theme.green) }
                    }
                }
            }
        }
        .searchable(text: $townSearch, prompt: "Find a town")
        .navigationTitle("Town")
    }
}
