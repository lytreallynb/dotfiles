// Sprite data and per-pet configuration.
// Each sprite is a grid of characters; the palette maps characters to colors.

import AppKit

enum Pose: CaseIterable {
    case stand, walkA, walkB, blink, happy, sleep, special
}

enum SpecialOverlay {
    case none
    case box
}

struct PetSpec {
    let name: String
    let frames: [Pose: [String]]
    let colors: [Character: NSColor]
    let pixelScale: CGFloat
    // Side-view sprites mirror to face left; front-view sprites nudge their eyes instead.
    let mirrorsToFace: Bool
    let walkSpeed: CGFloat
    let walkChance: Double
    let specialChance: Double
    let specialOverlay: SpecialOverlay
    let specialLine: String
    let clickLines: [String]

    var cols: Int { frames[.stand]![0].count }
    var rows: Int { frames[.stand]!.count }
    var spriteWidth: CGFloat { CGFloat(cols) * pixelScale }
    var spriteHeight: CGFloat { CGFloat(rows) * pixelScale }

    func frame(_ pose: Pose) -> [String] {
        frames[pose] ?? frames[.stand]!
    }
}

func rgb(_ r: Int, _ g: Int, _ b: Int) -> NSColor {
    NSColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
}

func replacing(_ rows: [String], _ changes: [(row: Int, col: Int, char: Character)]) -> [String] {
    var grid = rows.map { Array($0) }
    for change in changes {
        grid[change.row][change.col] = change.char
    }
    return grid.map { String($0) }
}

func replacingRows(_ rows: [String], _ changes: [Int: String]) -> [String] {
    var result = rows
    for (index, row) in changes {
        result[index] = row
    }
    return result
}

// MARK: - Mochi (front view)

let mochiBase: [String] = [
    "....oo....oo....",
    "...owwo..owwo...",
    "...owwwoowwwo...",
    "..owwwwwwwwwwo..",
    ".owwwwwwwwwwwwo.",
    ".owwewwwwwwewwo.",
    ".owwewwwwwwewwo.",
    ".owpwwwwwwwwpwo.",
    ".owwwwwoowwwwwo.",
    ".owwwwwwwwwwwwo.",
    ".owwwwwwwwwwwwo.",
    "..owwwwwwwwwwo..",
    "...oooooooooo...",
    "...oo......oo...",
]

let mochiClosedEyes: [Int: String] = [
    5: ".owwwwwwwwwwwwo.",
    6: ".owoowwwwwwoowo.",
]

let mochiSpec = PetSpec(
    name: "Mochi",
    frames: [
        .stand: mochiBase,
        .walkA: replacingRows(mochiBase, [13: "..oo.......oo..."]),
        .walkB: replacingRows(mochiBase, [13: "....oo....oo...."]),
        .blink: replacingRows(mochiBase, mochiClosedEyes),
        .happy: replacingRows(mochiBase, [5: ".owwowwwwwwowwo.", 6: ".owowowwwwowowo."]),
        .sleep: replacingRows(replacingRows(mochiBase, mochiClosedEyes), [13: "................"]),
    ],
    colors: [
        "o": rgb(59, 51, 64),
        "w": rgb(252, 247, 240),
        "p": rgb(245, 163, 181),
        "e": rgb(38, 33, 46),
    ],
    pixelScale: 5,
    mirrorsToFace: false,
    walkSpeed: 1.6,
    walkChance: 0.65,
    specialChance: 0,
    specialOverlay: .none,
    specialLine: "",
    clickLines: [
        "今天也辛苦啦",
        "Ship it!",
        "喝口水吧",
        "你的代码今天没有 bug（大概）",
        "摸摸头",
        "Commit early, commit often",
        "我在巡逻你的屏幕",
        "要不要休息五分钟？",
        "Hi, Coldice",
        "It works on my machine",
        "深呼吸，慢慢来",
    ]
)

// MARK: - Cats (side view, facing right)
// Legend: o outline, b fur, s stripe, w white chest/belly, m muzzle, f feet,
//         t tail tip, p pink, e eye

let catStand: [String] = [
    "................o....o..",
    "...............opo..opo.",
    "...............obbbbbbbo",
    "..oo..........obsbbsbbbo",
    ".otto.........obebbbebbo",
    ".oto..........obbmmpmmbo",
    ".obo..ooooooooobbmmmmbo.",
    "..oboobbsbbsbbbbbwwwwo..",
    "...obbsbbsbbsbbbbwwwwo..",
    "...obbbbsbbsbbbbbwwwbo..",
    "...obbbbbbbbbbbbbbwbbo..",
    "...obbbbwwwwwwbbbbbbbo..",
    "....obbbwwwwwbbbbbbbo...",
    "....obbo.obbo..obbo.obo.",
    "....offo.offo..offo.ofo.",
    "....ooo..ooo...ooo..oo..",
]

let catWalkA = replacingRows(catStand, [
    13: "...obo..obbo...obbo.obo.",
    14: "..ofo...offo...offo..ofo",
    15: "..oo....ooo....ooo...oo.",
])

let catWalkB = replacingRows(catStand, [
    13: "....obbo.obo..obo..obbo.",
    14: "....offo..ofo.ofo..offo.",
    15: "....ooo...oo..oo...ooo..",
])

let catBlink = replacing(catStand, [(4, 16, "o"), (4, 20, "o")])

let catLoaf: [String] = [
    "........................",
    "........................",
    "................o....o..",
    "...............opo..opo.",
    "...............obbbbbbbo",
    "..............obsbbsbbbo",
    "..............obobbbobbo",
    "..............obbmmpmmbo",
    "........ooooooobbmmmmbo.",
    "......oobbsbbsbbbbwwwwo.",
    "....oobbsbbsbbsbbbwwwwo.",
    "...obbbbbbbbbbbbbbbwwbo.",
    "...obbbbbbbbbbbbbbbbbbo.",
    "..otobbbbbbbbbbbbbbbbbo.",
    "..ottttttooooooffooffo..",
    "...ooooooo.....oo..oo...",
]

// Heavy-lidded side-eye, for sitting in a box looking unimpressed.
let catLoafGrumpy = replacing(catLoaf, [(5, 16, "o"), (5, 20, "o"), (6, 16, "e"), (6, 20, "e")])

// Lying on its back, paws up, head upside down (ears pointing at the floor).
let catBellyUp: [String] = [
    "........................",
    "........................",
    "........................",
    "...opo.opo..opo..opo....",
    "...obo.obo..obo..obo....",
    "...obo.obo..obo..obo....",
    ".oooboooboooobooobooo...",
    "obbbwwwwwwwwwwbbbobbbbbo",
    "obsbwwwwwwwwwwwbbobmmmbo",
    "otbwwwwwwwwwwwwbbobmpmbo",
    "otbbwwwwwwwwwwbbbobebebo",
    ".obsbbwwwwwwbbsbbobsbsbo",
    "..obbsbbsbbsbbbbbobbbbbo",
    "...oooooooooooooooobbbbo",
    ".................opo.opo",
    "..................o...o.",
]


// Orange is a big boy: standing frames get an extra belly row, other frames get
// an empty row on top so every frame stays the same height.
func chubby(_ rows: [String], standing: Bool) -> [String] {
    var result = rows
    if standing {
        result.insert(rows[11], at: 11)
    } else {
        result.insert(String(repeating: ".", count: rows[0].count), at: 0)
    }
    return result
}

let grayCatSpec = PetSpec(
    name: "灰灰",
    frames: [
        .stand: catStand,
        .walkA: catWalkA,
        .walkB: catWalkB,
        .blink: catBlink,
        .happy: catBlink,
        .sleep: catLoaf,
        .special: catLoafGrumpy,
    ],
    colors: [
        "o": rgb(46, 42, 44),
        "b": rgb(140, 134, 130),
        "s": rgb(86, 80, 80),
        "w": rgb(248, 245, 240),
        "m": rgb(248, 245, 240),
        "f": rgb(248, 245, 240),
        "t": rgb(70, 64, 64),
        "p": rgb(240, 160, 175),
        "e": rgb(120, 115, 40),
    ],
    pixelScale: 4,
    mirrorsToFace: true,
    walkSpeed: 1.4,
    walkChance: 0.45,
    specialChance: 0.35,
    specialOverlay: .box,
    specialLine: "这个箱子是我的",
    clickLines: [
        "哼",
        "别碰我的箱子",
        "...你看什么看",
        "饭呢？",
        "我在思考猫生",
        "勉强让你摸一下",
        "橘子又在翻肚皮了",
        "人类，你今天很吵",
    ]
)

let orangeCatSpec = PetSpec(
    name: "橘子",
    frames: [
        .stand: chubby(catStand, standing: true),
        .walkA: chubby(catWalkA, standing: true),
        .walkB: chubby(catWalkB, standing: true),
        .blink: chubby(catBlink, standing: true),
        .happy: chubby(catBlink, standing: true),
        .sleep: chubby(catLoaf, standing: false),
        .special: chubby(catBellyUp, standing: false),
    ],
    colors: [
        "o": rgb(70, 40, 25),
        "b": rgb(236, 158, 78),
        "s": rgb(200, 112, 46),
        "w": rgb(252, 246, 232),
        "m": rgb(246, 192, 122),
        "f": rgb(244, 184, 116),
        "t": rgb(252, 246, 232),
        "p": rgb(240, 156, 168),
        "e": rgb(110, 85, 25),
    ],
    pixelScale: 4,
    mirrorsToFace: true,
    walkSpeed: 1.0,
    walkChance: 0.4,
    specialChance: 0.4,
    specialOverlay: .none,
    specialLine: "摸肚子！",
    clickLines: [
        "喵～",
        "摸摸我的肚子",
        "我不胖，我是毛多",
        "罐罐！罐罐！",
        "抱我",
        "灰灰不跟我玩",
        "今天也要翻肚皮",
        "呼噜呼噜",
    ]
)

let allPetSpecs: [PetSpec] = [mochiSpec, grayCatSpec, orangeCatSpec]
