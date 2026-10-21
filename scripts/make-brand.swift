// Regenerates the brand images: the app icon (a musubi: rice block, seared slab and nori band on ocean #0A4D68; Nick's pick 2026-10-20,
// concept B of scripts/icon-concepts.swift, replacing his first pick, the shave ice; drawn in the shared Eats Ranked icon style:
// ../state-prompts/ICON-STYLE.md, passes ../state-prompts/icon-style/check.swift), playbook/brand/, and the site's og.png, favicons and
// manifest icons. Flat and matte: no gloss, gradients, tilt or scenery.
// Usage: swift scripts/make-brand.swift [count]   (run from hi-eats/)
import AppKit
import CoreGraphics

let root = FileManager.default.currentDirectoryPath
func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: a)
}
let ocean = rgb(0x0A4D68), hibiscus = rgb(0xC8102E), sand = rgb(0xFFF6E5), pineapple = rgb(0xFFC845)

func canvas(_ w: Int, _ h: Int, _ draw: (CGContext) -> Void) -> CGImage {
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setShouldAntialias(true); ctx.interpolationQuality = .high
    draw(ctx)
    return ctx.makeImage()!
}
func save(_ img: CGImage, _ path: String) {
    let url = URL(fileURLWithPath: root + "/" + path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try! NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:])!.write(to: url)
    print("wrote", path)
}

/// The food alone (no ground), in an s x s box, CoreGraphics y-up: Nick's pick 2026-10-20 (he switched from shave ice), concept B of
/// scripts/icon-concepts.swift. Side elevation: a sand block of rice, a seared slab of luncheon meat on top with its lighter top plane,
/// and a lava-black nori band round the middle. No can and no brand (SPAM is Hormel's mark). 5 colours with the ocean.
func musubi(_ c: CGContext, _ s: CGFloat) {
    func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x * s, y: (y + 0.045) * s, width: w * s, height: h * s) }   // +0.045: centred like the references
    let x0: CGFloat = 0.14, w: CGFloat = 0.72
    // Rice block: sand, soft corners (radius 48 px), 0.72 x 0.24; its top is hidden under the meat.
    let rice = CGPath(roundedRect: R(x0, 0.27, w, 0.25), cornerWidth: 0.047 * s, cornerHeight: 0.047 * s, transform: nil)
    c.setFillColor(rgb(0xFFF6E5)); c.addPath(rice); c.fillPath()
    // Meat: a seared slab the width of the rice, 0.12 thick, with its lighter top plane 0.04 deep.
    let slab = CGPath(roundedRect: R(x0 + 0.005, 0.50, w - 0.01, 0.125), cornerWidth: 0.035 * s, cornerHeight: 0.035 * s, transform: nil)
    c.saveGState(); c.addPath(slab); c.clip()
    c.setFillColor(rgb(0xB4573A)); c.fill(R(0, -0.05, 1, 1.1))           // seared front
    c.setFillColor(rgb(0xD7764F)); c.fill(R(0, 0.585, 1, 1))            // lighter top plane
    c.restoreGState()
    // Nori: one lava-black band round the middle, 0.20 wide, from under the rice to just over the slab's front edge.
    let nori = CGPath(roundedRect: R(0.40, 0.255, 0.20, 0.33), cornerWidth: 0.02 * s, cornerHeight: 0.02 * s, transform: nil)
    c.setFillColor(rgb(0x1E1E1E)); c.addPath(nori); c.fillPath()
}

/// The app icon: one flat ocean ground, edge to edge, then the food. og.png draws it whole in a rounded tile (icon(380)).
func icon(_ size: Int) -> CGImage {
    canvas(size, size) { c in
        c.setFillColor(ocean); c.fill(CGRect(x: 0, y: 0, width: size, height: size))
        musubi(c, CGFloat(size))
    }
}

func text(_ c: CGContext, _ str: String, font: NSFont, color: CGColor, at p: CGPoint) {
    let attr = NSAttributedString(string: str, attributes: [.font: font, .foregroundColor: NSColor(cgColor: color)!])
    c.textPosition = p
    CTLineDraw(CTLineCreateWithAttributedString(attr), c)
}
func heavy(_ size: CGFloat) -> NSFont {
    NSFont(name: "HelveticaNeue-CondensedBlack", size: size) ?? NSFont.systemFont(ofSize: size, weight: .black)
}

let appIcon = icon(1024)
save(appIcon, "HawaiiEats/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
save(appIcon, "playbook/brand/icon-1024.png")
save(icon(512), "docs/icon-512.png")
save(icon(192), "docs/icon-192.png")
save(icon(180), "docs/apple-touch-icon.png")
save(icon(32), "docs/favicon-32.png")

let count = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "3,800+"
let og = canvas(1200, 630) { c in
    c.setFillColor(ocean); c.fill(CGRect(x: 0, y: 0, width: 1200, height: 630))
    c.setFillColor(pineapple); c.fill(CGRect(x: 72, y: 470, width: 90, height: 12))
    text(c, "HAWAIʻI", font: heavy(128), color: sand, at: CGPoint(x: 66, y: 322))
    text(c, "EATS", font: heavy(128), color: pineapple, at: CGPoint(x: 66, y: 204))
    text(c, "Plate lunch, poke & shave ice guide", font: NSFont.systemFont(ofSize: 32, weight: .semibold), color: sand, at: CGPoint(x: 70, y: 150))
    text(c, "\(count) restaurants on six islands", font: NSFont.systemFont(ofSize: 30, weight: .regular), color: sand, at: CGPoint(x: 70, y: 104))
    text(c, "Free for iPhone and iPad", font: NSFont.systemFont(ofSize: 30, weight: .regular), color: pineapple, at: CGPoint(x: 70, y: 58))
    let mask = CGPath(roundedRect: CGRect(x: 760, y: 130, width: 380, height: 380), cornerWidth: 86, cornerHeight: 86, transform: nil)
    c.saveGState(); c.addPath(mask); c.clip(); c.draw(icon(380), in: CGRect(x: 760, y: 130, width: 380, height: 380)); c.restoreGState()
    c.setFillColor(hibiscus); c.fill(CGRect(x: 0, y: 0, width: 1200, height: 10))
}
save(og, "docs/og.png")
