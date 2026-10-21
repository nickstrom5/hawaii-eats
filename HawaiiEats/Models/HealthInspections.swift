import Foundation

/// Hawaii's Department of Health (Food Safety Branch, Environmental Health Services Division) inspects every food business on every
/// island; counties don't. It posts a color-coded placard at the door (Hawaii Administrative Rules 11-50, since Feb 24, 2014):
/// green = pass, yellow = conditional pass with a follow-up inspection, red = closed. There is no numeric score, and DOH publishes
/// results one search at a time with no bulk file, so the app shows no inspection results and computes no grade of its own.
/// The link is DOH's Food Safety Branch page (health.hawaii.gov/san/, fetched 2026-10-19 and rendering), which links to DOH's own
/// inspection search; the search site keeps automated agents out, so the app doesn't link it directly.
enum HealthInspections {
    static let agency = "Hawaii State Department of Health, Food Safety Branch"
    static let page = URL(string: "https://health.hawaii.gov/san/")!
    static let placards: [(color: String, meaning: String)] = [
        ("Green", "Pass: at most one critical violation, corrected during the inspection"),
        ("Yellow", "Conditional pass: a critical violation left uncorrected, or two or more; a follow-up inspection follows"),
        ("Red", "Closed: an imminent health hazard, until a follow-up inspection clears it"),
    ]
}
