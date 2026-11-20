// Renders every pet's frames to a PNG for checking pixel art.
// Usage: swiftc ../Sprites.swift main.swift -o preview && ./preview out.png

import AppKit

// Icon mode: ./preview --icon out.png renders a 1024px app icon of Mochi.
if CommandLine.arguments.count > 2 && CommandLine.arguments[1] == "--icon" {
    let size: CGFloat = 1024
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let inset: CGFloat = 100
    let bg = NSBezierPath(roundedRect: NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset),
                          xRadius: 185, yRadius: 185)
    rgb(255, 214, 165).setFill()
    bg.fill()
    let spec = mochiSpec
    let rows = spec.frame(.happy)
    let px: CGFloat = 40
    let ox = (size - CGFloat(spec.cols) * px) / 2
    let oy = (size - CGFloat(spec.rows) * px) / 2
    for (r, row) in rows.enumerated() {
        for (c, ch) in row.enumerated() {
            guard let color = spec.colors[ch] else { continue }
            color.setFill()
            NSRect(x: ox + CGFloat(c) * px, y: oy + CGFloat(rows.count - 1 - r) * px, width: px, height: px).fill()
        }
    }
    image.unlockFocus()
    let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
    exit(0)
}

let scale: CGFloat = 8
let gap: CGFloat = 16
let poses = Pose.allCases

var problems: [String] = []
for spec in allPetSpecs {
    for pose in poses {
        let rows = spec.frame(pose)
        if rows.count != spec.rows { problems.append("\(spec.name) \(pose): \(rows.count) rows, expected \(spec.rows)") }
        for (i, row) in rows.enumerated() where row.count != spec.cols {
            problems.append("\(spec.name) \(pose) row \(i): \(row.count) cols, expected \(spec.cols)")
        }
        for (i, row) in rows.enumerated() {
            for ch in row where ch != "." && spec.colors[ch] == nil {
                problems.append("\(spec.name) \(pose) row \(i): unknown char \(ch)")
            }
        }
    }
}
if !problems.isEmpty {
    problems.forEach { print($0) }
    exit(1)
}

let maxCols = allPetSpecs.map { $0.cols }.max()!
let maxRows = allPetSpecs.map { $0.rows }.max()!
let cellW = CGFloat(maxCols) * scale + gap
let cellH = CGFloat(maxRows) * scale + gap
let width = Int(cellW * CGFloat(poses.count) + gap)
let height = Int(cellH * CGFloat(allPetSpecs.count) + gap)

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()
rgb(200, 205, 210).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

for (petIndex, spec) in allPetSpecs.enumerated() {
    for (poseIndex, pose) in poses.enumerated() {
        let rows = spec.frame(pose)
        let ox = gap + CGFloat(poseIndex) * cellW
        let oy = CGFloat(height) - gap - CGFloat(petIndex + 1) * cellH + gap
        for (r, row) in rows.enumerated() {
            for (c, ch) in row.enumerated() {
                guard let color = spec.colors[ch] else { continue }
                color.setFill()
                NSRect(x: ox + CGFloat(c) * scale, y: oy + CGFloat(rows.count - 1 - r) * scale,
                       width: scale, height: scale).fill()
            }
        }
    }
}
image.unlockFocus()

let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("wrote \(CommandLine.arguments[1])")
