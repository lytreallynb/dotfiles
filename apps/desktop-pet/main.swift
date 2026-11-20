// Desktop pets for macOS: Mochi plus two pixel cats.
// Each pet walks along the bottom of the screen, talks when clicked, can be dragged,
// falls asleep when you are away, and has its own special move.
// Sprite data and per-pet settings live in Sprites.swift.

import AppKit

let groundPadding: CGFloat = 4
let bubbleAreaHeight: CGFloat = 90
let minWindowWidth: CGFloat = 260

func greetingForNow() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 0..<5: return "这么晚还不睡？"
    case 5..<12: return "早上好！"
    case 12..<18: return "下午好～"
    default: return "晚上好～"
    }
}

func secondsSinceLastInput() -> Double {
    guard let anyInput = CGEventType(rawValue: ~0) else { return 0 }
    return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
}

// MARK: - Pet logic

final class Pet: NSObject {
    enum State {
        case idle, walking, sleeping, held, falling, special
    }

    let spec: PetSpec
    let window: NSWindow
    let isLeader: Bool  // only one pet gives the stretch reminder
    var view: PetView!
    var onShowAll: (() -> Void)?
    var onQuit: (() -> Void)?

    var state: State = .idle
    var facingRight = true
    var targetX: CGFloat = 0
    var stateUntil = Date()
    var fallVelocity: CGFloat = 0
    var jumpHeight: CGFloat = 0
    var jumpVelocity: CGFloat = 0
    var tick = 0
    var blinkUntilTick = 0
    var happyUntil = Date.distantPast
    var bubbleText: String?
    var bubbleUntil = Date.distantPast
    var sleptByMenu = false
    var activeSeconds: Double = 0

    let ticksPerSecond: Double = 30
    let idleSleepSeconds: Double = 5 * 60
    let stretchReminderSeconds: Double = 50 * 60

    var windowWidth: CGFloat { max(minWindowWidth, spec.spriteWidth + 40) }
    var windowHeight: CGFloat { groundPadding + spec.spriteHeight + bubbleAreaHeight }

    init(spec: PetSpec, isLeader: Bool) {
        self.spec = spec
        self.isLeader = isLeader
        self.window = NSWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        super.init()
        window.setContentSize(NSSize(width: windowWidth, height: windowHeight))
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        view = PetView(pet: self)
        window.contentView = view
    }

    var screenFrame: NSRect {
        (window.screen ?? NSScreen.main ?? NSScreen.screens[0]).visibleFrame
    }

    // Window x range that keeps the sprite itself on screen.
    var minWindowX: CGFloat { screenFrame.minX - (windowWidth - spec.spriteWidth) / 2 }
    var maxWindowX: CGFloat { screenFrame.maxX - windowWidth + (windowWidth - spec.spriteWidth) / 2 }

    var pose: Pose {
        switch state {
        case .sleeping: return .sleep
        case .special: return .special
        case .held: return (tick / 3) % 2 == 0 ? .walkA : .walkB
        default: break
        }
        if Date() < happyUntil { return .happy }
        if state == .walking { return (tick / 6) % 2 == 0 ? .walkA : .walkB }
        if tick < blinkUntilTick { return .blink }
        return .stand
    }

    func start(atFraction fraction: CGFloat, greeting: String?) {
        let frame = screenFrame
        let x = frame.minX + frame.width * fraction - windowWidth / 2
        window.setFrameOrigin(NSPoint(x: min(max(x, minWindowX), maxWindowX), y: frame.minY))
        window.orderFrontRegardless()
        facingRight = Bool.random()
        if let greeting { say(greeting) }
        enterIdle()
        Timer.scheduledTimer(withTimeInterval: 1.0 / ticksPerSecond, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    // MARK: Speech and actions

    func say(_ text: String, seconds: Double = 4) {
        bubbleText = text
        bubbleUntil = Date().addingTimeInterval(seconds)
    }

    func jump() {
        guard jumpHeight == 0, state != .held, state != .falling, state != .sleeping else { return }
        if state == .special { enterIdle() }
        jumpVelocity = 8
        happyUntil = Date().addingTimeInterval(1)
    }

    func poke() {
        switch state {
        case .sleeping:
            wakeUp(line: "嗯...醒了")
        case .special:
            // Busy with its special move: talk, but stay put.
            say(LineStore.lines(for: spec).randomElement() ?? "...")
        default:
            if spec.specialChance > 0 && Double.random(in: 0..<1) < 0.3 {
                startSpecial(announce: true)
            } else {
                jump()
                say(LineStore.lines(for: spec).randomElement() ?? "...")
            }
        }
    }

    func startSpecial(announce: Bool) {
        guard spec.specialChance > 0 else { return }
        state = .special
        stateUntil = Date().addingTimeInterval(Double.random(in: 5...10))
        jumpHeight = 0
        jumpVelocity = 0
        if announce { say(spec.specialLine) }
    }

    func goToSleep(byMenu: Bool) {
        state = .sleeping
        sleptByMenu = byMenu
        jumpHeight = 0
        jumpVelocity = 0
    }

    func wakeUp(line: String) {
        sleptByMenu = false
        enterIdle()
        happyUntil = Date().addingTimeInterval(1.2)
        say(line)
    }

    func enterIdle() {
        state = .idle
        stateUntil = Date().addingTimeInterval(Double.random(in: 2...6))
    }

    func startWalking() {
        let range = minWindowX...maxWindowX
        var target = CGFloat.random(in: range)
        // Prefer walks that are long enough to look intentional.
        if abs(target - window.frame.origin.x) < 80 {
            target = window.frame.origin.x < screenFrame.midX ? range.upperBound - 40 : range.lowerBound + 40
        }
        targetX = target
        facingRight = targetX > window.frame.origin.x
        state = .walking
    }

    // MARK: Drag handling (called by the view)

    func beginHold() {
        state = .held
        jumpHeight = 0
        jumpVelocity = 0
    }

    func releaseHold() {
        state = .falling
        fallVelocity = 0
    }

    // MARK: Main loop

    func update() {
        guard window.isVisible else { return }
        tick += 1
        let now = Date()

        if bubbleText != nil && now > bubbleUntil {
            bubbleText = nil
        }

        if tick % Int(ticksPerSecond) == 0 {
            checkUserActivity()
        }

        if jumpHeight > 0 || jumpVelocity != 0 {
            jumpHeight += jumpVelocity
            jumpVelocity -= 1.0
            if jumpHeight <= 0 {
                jumpHeight = 0
                jumpVelocity = 0
            }
        }

        var origin = window.frame.origin

        switch state {
        case .idle:
            faceMouseIfNear()
            if tick >= blinkUntilTick && Int.random(in: 0..<120) == 0 {
                blinkUntilTick = tick + 4
            }
            if now > stateUntil {
                let roll = Double.random(in: 0..<1)
                if roll < spec.specialChance {
                    startSpecial(announce: Double.random(in: 0..<1) < 0.4)
                } else if roll < spec.specialChance + spec.walkChance {
                    startWalking()
                } else {
                    enterIdle()
                }
            }
        case .walking:
            let step = facingRight ? spec.walkSpeed : -spec.walkSpeed
            origin.x += step
            let arrived = facingRight ? origin.x >= targetX : origin.x <= targetX
            if arrived || origin.x < minWindowX || origin.x > maxWindowX {
                origin.x = min(max(origin.x, minWindowX), maxWindowX)
                enterIdle()
            }
            window.setFrameOrigin(origin)
        case .special:
            if now > stateUntil { enterIdle() }
        case .falling:
            fallVelocity -= 1.4
            origin.y += fallVelocity
            let ground = screenFrame.minY
            if origin.y <= ground {
                origin.y = ground
                origin.x = min(max(origin.x, minWindowX), maxWindowX)
                enterIdle()
                if Bool.random() { say("哎哟") }
            }
            window.setFrameOrigin(origin)
        case .sleeping, .held:
            break
        }

        view.needsDisplay = true
    }

    func faceMouseIfNear() {
        let mouse = NSEvent.mouseLocation
        let center = NSPoint(x: window.frame.midX, y: window.frame.minY + spec.spriteHeight / 2)
        let distance = hypot(mouse.x - center.x, mouse.y - center.y)
        if distance < 300 {
            facingRight = mouse.x > center.x
        }
    }

    func checkUserActivity() {
        let idle = secondsSinceLastInput()

        if state == .sleeping {
            if !sleptByMenu && idle < 2 {
                wakeUp(line: "欢迎回来！")
            }
            return
        }

        // Stagger naps a little so the pets do not all drop at the same second.
        let sleepAfter = idleSleepSeconds + (isLeader ? 0 : Double(spec.name.count) * 20)
        if idle > sleepAfter && state != .held && state != .falling {
            goToSleep(byMenu: false)
            return
        }

        guard isLeader else { return }
        if idle < 120 {
            activeSeconds += 1
        } else {
            activeSeconds = 0
        }
        if activeSeconds >= stretchReminderSeconds {
            activeSeconds = 0
            jump()
            say("已经连续用电脑 50 分钟啦，起来活动一下！", seconds: 10)
        }
    }

    // MARK: Menu

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "说句话", action: #selector(menuSay), keyEquivalent: "").target = self
        menu.addItem(withTitle: "跳一下", action: #selector(menuJump), keyEquivalent: "").target = self
        if spec.specialChance > 0 {
            menu.addItem(withTitle: spec.specialLine, action: #selector(menuSpecial), keyEquivalent: "").target = self
        }
        let sleepTitle = state == .sleeping ? "叫醒\(spec.name)" : "让\(spec.name)睡觉"
        menu.addItem(withTitle: sleepTitle, action: #selector(menuToggleSleep), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "让\(spec.name)回家", action: #selector(menuHide), keyEquivalent: "").target = self
        menu.addItem(withTitle: "叫大家回来", action: #selector(menuShowAll), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "全部退出", action: #selector(menuQuit), keyEquivalent: "").target = self
        return menu
    }

    @objc func menuSay() { poke() }
    @objc func menuJump() { jump() }
    @objc func menuSpecial() { startSpecial(announce: true) }
    @objc func menuHide() { window.orderOut(nil) }
    @objc func menuShowAll() { onShowAll?() }
    @objc func menuQuit() { onQuit?() }
    @objc func menuToggleSleep() {
        if state == .sleeping {
            wakeUp(line: "睡饱了！")
        } else {
            say("晚安...", seconds: 2)
            goToSleep(byMenu: true)
        }
    }

    func comeBack() {
        guard !window.isVisible else { return }
        var origin = window.frame.origin
        origin.y = screenFrame.minY
        origin.x = min(max(origin.x, minWindowX), maxWindowX)
        window.setFrameOrigin(origin)
        window.orderFrontRegardless()
        enterIdle()
        say("我回来啦")
    }
}

// MARK: - View

final class PetView: NSView {
    unowned let pet: Pet
    var dragStartMouse = NSPoint.zero
    var dragStartOrigin = NSPoint.zero
    var didDrag = false

    var spec: PetSpec { pet.spec }
    var outlineColor: NSColor { spec.colors["o"] ?? .black }

    init(pet: Pet) {
        self.pet = pet
        super.init(frame: NSRect(x: 0, y: 0, width: pet.windowWidth, height: pet.windowHeight))
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    var spriteOrigin: NSPoint {
        NSPoint(x: (bounds.width - spec.spriteWidth) / 2, y: groundPadding + pet.jumpHeight)
    }

    // Only the sprite catches clicks; the rest of the window passes them through.
    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        let spriteRect = NSRect(origin: spriteOrigin, size: NSSize(width: spec.spriteWidth, height: spec.spriteHeight))
        return spriteRect.contains(local) ? self : nil
    }

    override func draw(_ dirtyRect: NSRect) {
        drawShadow()
        drawSprite()
        if pet.state == .special && spec.specialOverlay == .box { drawBox() }
        if pet.state == .sleeping { drawSnores() }
        if let text = pet.bubbleText { drawBubble(text) }
    }

    func drawShadow() {
        guard pet.state != .held && pet.state != .falling else { return }
        let shrink = min(pet.jumpHeight / 40, 0.6)
        let width = spec.spriteWidth * 0.75 * (1 - shrink)
        let rect = NSRect(x: (bounds.width - width) / 2, y: 1, width: width, height: 6)
        NSColor.black.withAlphaComponent(0.18 * (1 - shrink)).setFill()
        NSBezierPath(ovalIn: rect).fill()
    }

    func pixelRect(col: Int, row: Int) -> NSRect {
        let s = spec.pixelScale
        let origin = spriteOrigin
        return NSRect(x: origin.x + CGFloat(col) * s,
                      y: origin.y + CGFloat(spec.rows - 1 - row) * s,
                      width: s, height: s)
    }

    func drawSprite() {
        let rows = spec.frame(pet.pose)
        let mirror = spec.mirrorsToFace && !pet.facingRight
        let nudgeEyes = !spec.mirrorsToFace
        let eyeShift = pet.facingRight ? 1 : -1

        func screenCol(_ col: Int) -> Int { mirror ? spec.cols - 1 - col : col }

        // Pass 1: everything; on front-view sprites, eyes and cheeks are painted as body first.
        for (rowIndex, row) in rows.enumerated() {
            for (colIndex, pixel) in row.enumerated() {
                let isFeature = nudgeEyes && (pixel == "e" || pixel == "p")
                guard let color = spec.colors[isFeature ? "w" : pixel] else { continue }
                color.setFill()
                pixelRect(col: screenCol(colIndex), row: rowIndex).fill()
            }
        }
        // Pass 2: front-view eyes and cheeks, nudged toward the facing direction.
        guard nudgeEyes else { return }
        for (rowIndex, row) in rows.enumerated() {
            for (colIndex, pixel) in row.enumerated() where pixel == "e" || pixel == "p" {
                guard let color = spec.colors[pixel] else { continue }
                color.setFill()
                pixelRect(col: colIndex + eyeShift, row: rowIndex).fill()
            }
        }
    }

    // Cardboard box in front of the lower body, like the one in the photo.
    func drawBox() {
        let s = spec.pixelScale
        let origin = spriteOrigin
        let boxRows = 6
        let rect = NSRect(x: origin.x + s, y: origin.y, width: spec.spriteWidth - 2 * s, height: CGFloat(boxRows) * s)
        rgb(196, 148, 96).setFill()
        rect.fill()
        rgb(214, 170, 118).setFill()
        NSRect(x: rect.minX, y: rect.maxY - s, width: rect.width, height: s).fill()
        rgb(120, 92, 170).setFill()
        var x = rect.minX + 2 * s
        var row = 0
        while x < rect.maxX - 2 * s {
            let y = rect.minY + (row % 2 == 0 ? 1.5 : 3) * s
            NSRect(x: x, y: y, width: s, height: s).fill()
            x += 4 * s
            row += 1
        }
        outlineColor.setStroke()
        let path = NSBezierPath(rect: rect.insetBy(dx: 1, dy: 1))
        path.lineWidth = 2
        path.stroke()
    }

    // Drawn as pixels instead of text: font fallback for this text crashed on some macOS builds.
    func drawSnores() {
        let phase = (pet.tick / 20) % 3
        let headOnRight = !spec.mirrorsToFace || pet.facingRight
        let direction: CGFloat = headOnRight ? 1 : -1
        let baseX = headOnRight ? spriteOrigin.x + spec.spriteWidth - 2 : spriteOrigin.x - 12
        let baseY = spriteOrigin.y + spec.spriteHeight - 12
        let zSmall = ["ooo", "..o", ".o.", "o..", "ooo"]
        let zBig = ["oooo", "...o", "..o.", ".o..", "oooo"]
        outlineColor.withAlphaComponent(0.7).setFill()
        for i in 0...phase {
            let glyph = i == 2 ? zBig : zSmall
            let px: CGFloat = 2
            let ox = baseX + direction * CGFloat(i) * 10
            let oy = baseY + CGFloat(i) * 12
            for (r, row) in glyph.enumerated() {
                for (c, ch) in row.enumerated() where ch == "o" {
                    NSRect(x: ox + CGFloat(c) * px, y: oy + CGFloat(glyph.count - 1 - r) * px, width: px, height: px).fill()
                }
            }
        }
    }

    func drawBubble(_ text: String) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: outlineColor,
        ]
        let string = NSAttributedString(string: text, attributes: attrs)
        let textBounds = string.boundingRect(with: NSSize(width: 210, height: 200), options: [.usesLineFragmentOrigin])
        let padding: CGFloat = 8
        let bubbleW = ceil(textBounds.width) + padding * 2
        let bubbleH = ceil(textBounds.height) + padding * 2
        let bubbleX = (bounds.width - bubbleW) / 2
        let bubbleY = groundPadding + spec.spriteHeight + 12
        let bubbleRect = NSRect(x: bubbleX, y: bubbleY, width: bubbleW, height: bubbleH)

        let path = NSBezierPath(roundedRect: bubbleRect, xRadius: 9, yRadius: 9)
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: bounds.midX - 6, y: bubbleY + 1))
        tail.line(to: NSPoint(x: bounds.midX, y: bubbleY - 8))
        tail.line(to: NSPoint(x: bounds.midX + 6, y: bubbleY + 1))
        tail.close()

        outlineColor.setStroke()
        rgb(252, 248, 242).setFill()
        path.lineWidth = 2
        tail.lineWidth = 2
        path.stroke()
        tail.stroke()
        path.fill()
        tail.fill()

        let textRect = NSRect(x: bubbleX + padding, y: bubbleY + padding,
                              width: ceil(textBounds.width) + 1, height: ceil(textBounds.height))
        string.draw(with: textRect, options: [.usesLineFragmentOrigin])
    }

    // MARK: Mouse

    override func mouseDown(with event: NSEvent) {
        dragStartMouse = NSEvent.mouseLocation
        dragStartOrigin = window?.frame.origin ?? .zero
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        let mouse = NSEvent.mouseLocation
        let dx = mouse.x - dragStartMouse.x
        let dy = mouse.y - dragStartMouse.y
        if !didDrag && hypot(dx, dy) < 3 { return }
        if !didDrag {
            didDrag = true
            pet.beginHold()
            pet.say("放我下来！", seconds: 60)
        }
        window?.setFrameOrigin(NSPoint(x: dragStartOrigin.x + dx, y: dragStartOrigin.y + dy))
    }

    override func mouseUp(with event: NSEvent) {
        if didDrag {
            pet.bubbleText = nil
            pet.releaseHold()
        } else {
            pet.poke()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        NSMenu.popUpContextMenu(pet.makeMenu(), with: event, for: self)
    }
}

// MARK: - Editable lines

enum LineStore {
    static func key(_ spec: PetSpec) -> String { "lines." + spec.name }

    static func lines(for spec: PetSpec) -> [String] {
        let saved = UserDefaults.standard.stringArray(forKey: key(spec)) ?? []
        return saved.isEmpty ? spec.clickLines : saved
    }

    static func save(_ lines: [String], for spec: PetSpec) {
        UserDefaults.standard.set(lines, forKey: key(spec))
    }

    static func reset(_ spec: PetSpec) {
        UserDefaults.standard.removeObject(forKey: key(spec))
    }
}

// MARK: - Settings window

final class SettingsController: NSObject {
    let window: NSWindow
    let picker = NSPopUpButton()
    let textView = NSTextView()
    let status = NSTextField(labelWithString: "")

    override init() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 440),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
        super.init()
        window.title = "Mochi 设置"
        window.isReleasedWhenClosed = false
        window.center()

        let content = NSView(frame: window.contentRect(forFrameRect: window.frame))
        window.contentView = content

        let label = NSTextField(labelWithString: "宠物：")
        label.frame = NSRect(x: 20, y: 396, width: 50, height: 22)
        content.addSubview(label)

        picker.frame = NSRect(x: 70, y: 392, width: 200, height: 28)
        picker.addItems(withTitles: allPetSpecs.map { $0.name })
        picker.target = self
        picker.action = #selector(petChanged)
        content.addSubview(picker)

        let hint = NSTextField(labelWithString: "点它时说的话，一行一句：")
        hint.frame = NSRect(x: 20, y: 364, width: 380, height: 20)
        hint.textColor = .secondaryLabelColor
        content.addSubview(hint)

        let scroll = NSScrollView(frame: NSRect(x: 20, y: 70, width: 380, height: 288))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        textView.frame = scroll.contentView.bounds
        textView.autoresizingMask = [.width]
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.isRichText = false
        textView.textContainerInset = NSSize(width: 6, height: 6)
        scroll.documentView = textView
        content.addSubview(scroll)

        let save = NSButton(title: "保存", target: self, action: #selector(saveLines))
        save.frame = NSRect(x: 300, y: 24, width: 100, height: 32)
        save.keyEquivalent = "\r"
        content.addSubview(save)

        let reset = NSButton(title: "恢复默认", target: self, action: #selector(resetLines))
        reset.frame = NSRect(x: 190, y: 24, width: 100, height: 32)
        content.addSubview(reset)

        status.frame = NSRect(x: 20, y: 30, width: 160, height: 20)
        status.textColor = .secondaryLabelColor
        content.addSubview(status)

        loadLines()
    }

    var currentSpec: PetSpec { allPetSpecs[max(picker.indexOfSelectedItem, 0)] }

    func show() {
        loadLines()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func loadLines() {
        textView.string = LineStore.lines(for: currentSpec).joined(separator: "\n")
        status.stringValue = ""
    }

    @objc func petChanged() { loadLines() }

    @objc func saveLines() {
        let lines = textView.string
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        LineStore.save(lines, for: currentSpec)
        status.stringValue = "已保存 \(lines.count) 句"
    }

    @objc func resetLines() {
        LineStore.reset(currentSpec)
        loadLines()
        status.stringValue = "已恢复默认"
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    var pets: [Pet] = []
    var statusItem: NSStatusItem!
    lazy var settings = SettingsController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let count = allPetSpecs.count
        for (index, spec) in allPetSpecs.enumerated() {
            let pet = Pet(spec: spec, isLeader: index == 0)
            pet.onShowAll = { [weak self] in self?.showAll() }
            pet.onQuit = { NSApp.terminate(nil) }
            let fraction = CGFloat(index + 1) / CGFloat(count + 1)
            pet.start(atFraction: fraction, greeting: index == 0 ? greetingForNow() : nil)
            pets.append(pet)
        }
        setUpStatusItem()
    }

    // Opening the app again (Spotlight, Finder) brings everyone back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showAll()
        return false
    }

    func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Mochi")
        let menu = NSMenu()
        menu.addItem(withTitle: "叫大家回来", action: #selector(showAll), keyEquivalent: "").target = self
        menu.addItem(withTitle: "全部藏起来", action: #selector(hideAll), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "设置台词…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
    }

    @objc func showAll() { pets.forEach { $0.comeBack() } }
    @objc func hideAll() { pets.forEach { $0.window.orderOut(nil) } }
    @objc func openSettings() { settings.show() }
    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
