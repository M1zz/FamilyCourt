import AppKit
// SVG 한 장을 1024×1024 PNG 로 그린다 (→ make_app_icon.py).
// 쓰기: render in.svg out.png opaque|alpha
let a = CommandLine.arguments
let img = NSImage(contentsOf: URL(fileURLWithPath: a[1]))!
let opaque = a[3] == "opaque"
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let info = opaque ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue
let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: info)!
ctx.interpolationQuality = .high
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
img.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024))
let cg = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, cg, nil)
print(CGImageDestinationFinalize(dest))
