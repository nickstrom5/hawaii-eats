import Foundation

/// The app's web pages and support address, in one place.
/// The site is GitHub Pages at the project address until hawaii.eatsranked.com resolves (Nick adds a Cloudflare CNAME
/// hawaii -> nickstrom5.github.io, DNS only; then scripts/make-site.py sets CUSTOM_DOMAIN). GitHub forwards these github.io
/// links to the custom domain after the switch, so a shipped build keeps working; point them at the new domain in the next update.
enum Links {
    static let site = URL(string: "https://nickstrom5.github.io/hawaii-eats/")!
    /// The app's data updates: scripts/publish_app_data.py writes docs/data/app/ (OTA-DATA.md).
    static let appData = URL(string: site.absoluteString + "data/app/")!
    static let privacy = URL(string: "https://nickstrom5.github.io/hawaii-eats/privacy.html")!
    static let terms = URL(string: "https://nickstrom5.github.io/hawaii-eats/terms.html")!
    static let supportEmail = "nick@eatsranked.com"

    static var correctionEmail: URL {
        URL(string: "mailto:\(supportEmail)?subject=Hawaii%20Eats%20correction")!
    }
}
