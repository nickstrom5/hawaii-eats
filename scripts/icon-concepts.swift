// Hawaii Eats icon concepts for Nick's pick, in the shared Eats Ranked icon style (state-prompts/ICON-STYLE.md v1):
// one flat, level, centred food on a plain background; no scenery, tilt, texture, gloss or gradients.
// Usage (from hi-eats/): swift scripts/icon-concepts.swift   -> playbook/brand/concept-{a,b,c}-1024.png and -180, -60 copies
//   A  shave ice: a dome of ice in three syrup bands (hibiscus red, pineapple yellow, sky blue) in a sand paper cup
//   B  musubi: a block of rice with a seared slab of luncheon meat on top and a band of nori round the middle (no can, no brand)
//   C  plate lunch, seen from above: two scoops rice, a scoop of mac salad and teriyaki on a light blue plate
// Background: ocean #0A4D68 (the leaderboard's palette); food colours from it where they fit: hibiscus #C8102E, pineapple
// #FFC845, sand #FFF6E5, lava #1E1E1E. The few food-only tones (syrup blue, seared meat, plate blue, teriyaki) are new and
// listed per concept; the palette itself is Nick's call.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let OCEAN: UInt32 = 0x0A4D68

// MARK: A, shave ice (upright: vertical axis, front elevation)
func shaveIce(_ c: CGContext, _ s: CGFloat) {
    func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
    // Cup: a sand paper cup, wider at the top, 0.40 wide at the rim, 0.30 at the base, 0.30 tall; a lighter rim band would be a
    // second tone of sand, so the cup is one flat tone with its lower edge softly rounded.
    let cup = CGMutablePath()
    let cupTop: CGFloat = 0.43, cupBot: CGFloat = 0.14, rimW: CGFloat = 0.21, baseW: CGFloat = 0.155, r: CGFloat = 0.035
    cup.move(to: P(0.5 - rimW, cupTop)); cup.addLine(to: P(0.5 + rimW, cupTop))
    cup.addLine(to: P(0.5 + baseW + r * 0.25, cupBot + r))
    cup.addQuadCurve(to: P(0.5 + baseW - r, cupBot), control: P(0.5 + baseW, cupBot))
    cup.addLine(to: P(0.5 - baseW + r, cupBot))
    cup.addQuadCurve(to: P(0.5 - baseW - r * 0.25, cupBot + r), control: P(0.5 - baseW, cupBot))
    cup.closeSubpath()
    // Ice: a dome sitting on the cup, 0.62 wide, rising to y 0.86. Syrup in three vertical-free horizontal bands (blue at the top,
    // yellow, red at the bottom), hard edges; the cup overlaps the dome's lower edge.
    let dome = CGMutablePath()
    let dw: CGFloat = 0.31, dy: CGFloat = 0.40, top: CGFloat = 0.86
    dome.move(to: P(0.5 - dw, dy))
    dome.addCurve(to: P(0.5, top), control1: P(0.5 - dw, dy + 0.30), control2: P(0.5 - dw * 0.55, top))
    dome.addCurve(to: P(0.5 + dw, dy), control1: P(0.5 + dw * 0.55, top), control2: P(0.5 + dw, dy + 0.30))
    dome.closeSubpath()
    c.saveGState(); c.addPath(dome); c.clip()
    c.setFillColor(rgb(0xC8102E)); c.fill(CGRect(x: 0, y: 0, width: s, height: 0.555 * s))            // strawberry / li hing red
    c.setFillColor(rgb(0xFFC845)); c.fill(CGRect(x: 0, y: 0.555 * s, width: s, height: 0.13 * s))    // pineapple
    c.setFillColor(rgb(0x7FD1E8)); c.fill(CGRect(x: 0, y: 0.685 * s, width: s, height: s))           // blue Hawaii
    c.restoreGState()
    c.setFillColor(rgb(0xFFF6E5)); c.addPath(cup); c.fillPath()
}

// MARK: B, musubi (long food: side elevation)
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

// MARK: C, plate lunch (round: plan view)
func plateLunch(_ c: CGContext, _ s: CGFloat) {
    func E(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: (x - w / 2) * s, y: (y - h / 2) * s, width: w * s, height: h * s) }
    c.setFillColor(rgb(0x8FC3D6)); c.fillEllipse(in: E(0.5, 0.49, 0.71, 0.64))                    // the plate
    // laid out the way the plate comes: two scoops rice down the left, the main filling the right half, mac salad between them
    // at the front (a left-right split, so it never reads as a face)
    for (x, y) in [(0.335, 0.60), (0.335, 0.385)] as [(CGFloat, CGFloat)] {
        c.setFillColor(rgb(0xC9DCE2)); c.fillEllipse(in: E(x, y - 0.018, 0.21, 0.19))
        c.setFillColor(rgb(0xFFFFFF)); c.fillEllipse(in: E(x, y, 0.21, 0.19))
    }
    let meat = CGPath(roundedRect: E(0.65, 0.555, 0.26, 0.32), cornerWidth: 0.08 * s, cornerHeight: 0.08 * s, transform: nil)
    c.setFillColor(rgb(0x7A3B1E)); c.addPath(meat); c.fillPath()
    c.setFillColor(rgb(0xFFC845)); c.fillEllipse(in: E(0.615, 0.305, 0.20, 0.15))                   // mac salad
}

// MARK: - main
let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent().path
let out = root + "/playbook/brand"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
func canvas(_ n: Int) -> CGContext {
    let c = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.setAllowsAntialiasing(true); c.setShouldAntialias(true); c.interpolationQuality = .high
    return c
}
func save(_ img: CGImage, _ name: String) {
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out + "/" + name) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("could not write \(name)") }
}
for (key, draw) in [("a", shaveIce), ("b", musubi), ("c", plateLunch)] as [(String, (CGContext, CGFloat) -> Void)] {
    let c = canvas(1024)
    c.setFillColor(rgb(OCEAN)); c.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    draw(c, 1024)
    let full = c.makeImage()!
    save(full, "concept-\(key)-1024.png")
    for n in [512, 180, 60] {
        let sm = canvas(n); sm.draw(full, in: CGRect(x: 0, y: 0, width: n, height: n)); save(sm.makeImage()!, "concept-\(key)-\(n).png")
    }
    print("wrote concept-\(key)")
}
