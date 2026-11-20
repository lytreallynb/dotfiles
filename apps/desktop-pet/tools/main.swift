// Renders every pet's frames to a PNG for checking pixel art.
// Usage: swiftc ../Sprites.swift main.swift -o preview && ./preview out.png

import AppKit

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
