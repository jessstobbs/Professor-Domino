import AppKit
import CoreText
import Foundation

struct Quote: Codable {
    let text: String
    let author: String?
}

final class QuoteCompanion: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let quoteItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let nextQuoteItem = NSMenuItem(title: "Say Something Now", action: #selector(showQuoteNow), keyEquivalent: "s")
    private let addQuoteItem = NSMenuItem(title: "Add Quote", action: #selector(addQuote), keyEquivalent: "a")
    private let toggleCompanionItem = NSMenuItem(title: "Hide Companion", action: #selector(toggleCompanion), keyEquivalent: "h")
    private let intervalMenu = NSMenu()
    private var companionWindow: NSWindow?
    private var speechWindow: NSWindow?
    private var speechTextField: NSTextField?
    private var speechPawImageView: NSImageView?
    private var speechHideWorkItem: DispatchWorkItem?
    private var companionImageView: NSImageView?
    private var normalCompanionImage: NSImage?
    private var hoverCompanionImage: NSImage?
    private var timer: Timer?
    private var quotes: [Quote] = []
    private var recentQuoteIndexes: [Int] = []
    private var intervalMinutes = 180
    private var companionVisible = true
    private let speechFontName = "Zen Loop"

    private var quotesURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        return documents
            .appendingPathComponent("Professor Domino", isDirectory: true)
            .appendingPathComponent("quotes.json")
    }

    private var bundledQuotesURL: URL {
        if let resourceURL = Bundle.main.resourceURL {
            return resourceURL.appendingPathComponent("quotes.json")
        }

        return URL(fileURLWithPath: CommandLine.arguments.first ?? "")
            .deletingLastPathComponent()
            .appendingPathComponent("quotes.json")
    }

    private var companionImageURL: URL {
        if let resourceURL = Bundle.main.resourceURL {
            return resourceURL
                .appendingPathComponent("assets")
                .appendingPathComponent("cat_companion.png")
        }

        return URL(fileURLWithPath: CommandLine.arguments.first ?? "")
            .deletingLastPathComponent()
            .appendingPathComponent("assets")
            .appendingPathComponent("cat_companion.png")
    }

    private var hoverCompanionImageURL: URL {
        if let resourceURL = Bundle.main.resourceURL {
            return resourceURL
                .appendingPathComponent("assets")
                .appendingPathComponent("cat_companion_hover.png")
        }

        return URL(fileURLWithPath: CommandLine.arguments.first ?? "")
            .deletingLastPathComponent()
            .appendingPathComponent("assets")
            .appendingPathComponent("cat_companion_hover.png")
    }

    private var zenLoopFontURL: URL {
        if let resourceURL = Bundle.main.resourceURL {
            return resourceURL
                .appendingPathComponent("assets")
                .appendingPathComponent("fonts")
                .appendingPathComponent("ZenLoop-Regular.ttf")
        }

        return URL(fileURLWithPath: CommandLine.arguments.first ?? "")
            .deletingLastPathComponent()
            .appendingPathComponent("assets")
            .appendingPathComponent("fonts")
            .appendingPathComponent("ZenLoop-Regular.ttf")
    }

    private var pawprintURL: URL {
        if let resourceURL = Bundle.main.resourceURL {
            return resourceURL
                .appendingPathComponent("assets")
                .appendingPathComponent("pawprint.svg")
        }

        return URL(fileURLWithPath: CommandLine.arguments.first ?? "")
            .deletingLastPathComponent()
            .appendingPathComponent("assets")
            .appendingPathComponent("pawprint.svg")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registerSpeechFont()
        loadQuotes()
        configureMenu()
        configureCompanionWindow()
        scheduleTimer()
        showQuoteInMenu(randomQuote())
    }

    private func configureMenu() {
        configureStatusIcon()

        quoteItem.isEnabled = false
        quoteItem.title = "Warming up..."
        menu.addItem(quoteItem)
        menu.addItem(NSMenuItem.separator())

        nextQuoteItem.target = self
        menu.addItem(nextQuoteItem)

        addQuoteItem.target = self
        menu.addItem(addQuoteItem)

        toggleCompanionItem.target = self
        menu.addItem(toggleCompanionItem)

        let intervalParent = NSMenuItem(title: "Every", action: nil, keyEquivalent: "")
        intervalParent.submenu = intervalMenu
        menu.addItem(intervalParent)
        addIntervalItem(title: "30 Minutes", minutes: 30)
        addIntervalItem(title: "1 Hour", minutes: 60)
        addIntervalItem(title: "3 Hours", minutes: 180)
        addIntervalItem(title: "6 Hours", minutes: 360)
        updateIntervalChecks()

        menu.addItem(NSMenuItem.separator())
        let openQuotesItem = NSMenuItem(title: "Edit Quotes", action: #selector(openQuotes), keyEquivalent: "e")
        openQuotesItem.target = self
        menu.addItem(openQuotesItem)

        let reloadItem = NSMenuItem(title: "Reload Quotes", action: #selector(reloadQuotes), keyEquivalent: "r")
        reloadItem.target = self
        menu.addItem(reloadItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func configureStatusIcon() {
        guard let button = statusItem.button else { return }
        button.toolTip = "Quote Companion"

        if let image = NSImage(contentsOf: companionImageURL) {
            image.size = NSSize(width: 22, height: 22)
            image.isTemplate = false
            button.image = image
            button.title = " Quote"
            button.imagePosition = .imageLeft
        } else {
            button.title = "Quote"
        }
    }

    private func registerSpeechFont() {
        CTFontManagerRegisterFontsForURL(zenLoopFontURL as CFURL, .process, nil)
    }

    private func configureCompanionWindow() {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let sideLength: CGFloat = min(420, max(300, screenFrame.height * 0.42))
        let origin = NSPoint(
            x: screenFrame.maxX - sideLength - 36,
            y: screenFrame.minY + 48
        )
        let frame = NSRect(origin: origin, size: NSSize(width: sideLength, height: sideLength))
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false

        normalCompanionImage = NSImage(contentsOf: companionImageURL)
        hoverCompanionImage = NSImage(contentsOf: hoverCompanionImageURL)

        let imageView = HoverImageView(frame: NSRect(origin: .zero, size: frame.size))
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.image = normalCompanionImage
        imageView.wantsLayer = true
        imageView.layer?.shadowColor = NSColor.black.cgColor
        imageView.layer?.shadowOpacity = 0.22
        imageView.layer?.shadowRadius = 22
        imageView.layer?.shadowOffset = NSSize(width: 0, height: -6)
        imageView.onHoverChanged = { [weak self] isHovering in
            self?.companionImageView?.image = isHovering ? self?.hoverCompanionImage : self?.normalCompanionImage
            if !isHovering {
                self?.hideSpeechBubble()
            }
        }

        let click = NSClickGestureRecognizer(target: self, action: #selector(showQuoteNow))
        imageView.addGestureRecognizer(click)

        window.contentView = imageView
        window.orderFrontRegardless()

        companionWindow = window
        companionImageView = imageView
        configureSpeechWindow(relativeTo: frame)
        startIdleAnimation()
    }

    private func configureSpeechWindow(relativeTo companionFrame: NSRect) {
        let bubbleSize = NSSize(width: 560, height: 222)
        let origin = NSPoint(
            x: max(24, companionFrame.minX - bubbleSize.width + 88),
            y: companionFrame.maxY - bubbleSize.height + 28
        )
        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: bubbleSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = true
        window.alphaValue = 0

        let bubbleView = SpeechBubbleView(frame: NSRect(origin: .zero, size: bubbleSize))
        let textField = NSTextField(labelWithString: "")
        textField.frame = speechTextFrame(for: bubbleSize)
        textField.font = speechFont(size: 34)
        textField.textColor = NSColor(calibratedRed: 0.15, green: 0.12, blue: 0.10, alpha: 1)
        let textShadow = NSShadow()
        textShadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.18)
        textShadow.shadowBlurRadius = 0
        textShadow.shadowOffset = NSSize(width: 0.45, height: -0.45)
        textField.shadow = textShadow
        textField.maximumNumberOfLines = 5
        textField.lineBreakMode = .byWordWrapping
        textField.cell?.wraps = true
        textField.cell?.usesSingleLineMode = false
        bubbleView.addSubview(textField)

        let pawSize = NSSize(width: 34, height: 34)
        let pawImageView = NSImageView(frame: NSRect(
            x: textField.frame.maxX + 6,
            y: textField.frame.minY + 2,
            width: pawSize.width,
            height: pawSize.height
        ))
        pawImageView.imageScaling = .scaleProportionallyUpOrDown
        pawImageView.image = NSImage(contentsOf: pawprintURL)
        bubbleView.addSubview(pawImageView)

        window.contentView = bubbleView
        speechWindow = window
        speechTextField = textField
        speechPawImageView = pawImageView
    }

    private func speechTextFrame(for bubbleSize: NSSize) -> NSRect {
        NSRect(
            x: bubbleSize.width * 0.11,
            y: bubbleSize.height * 0.33,
            width: bubbleSize.width * 0.69,
            height: bubbleSize.height * 0.43
        )
    }

    private func speechFont(size: CGFloat) -> NSFont {
        let base = NSFont(name: speechFontName, size: size) ?? NSFont.systemFont(ofSize: size, weight: .semibold)
        return NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask)
    }

    private func startIdleAnimation() {
        guard let layer = companionImageView?.layer else { return }
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.fromValue = -8
        animation.toValue = 8
        animation.duration = 1.9
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "idleBob")
    }

    private func addIntervalItem(title: String, minutes: Int) {
        let item = NSMenuItem(title: title, action: #selector(setInterval(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = minutes
        intervalMenu.addItem(item)
    }

    private func loadQuotes() {
        ensureEditableQuotesFile()
        do {
            let data = try Data(contentsOf: quotesURL)
            quotes = try JSONDecoder().decode([Quote].self, from: data)
        } catch {
            quotes = [
                Quote(text: "Begin anywhere.", author: "John Cage"),
                Quote(text: "The work teaches you how to do it.", author: nil),
                Quote(text: "Small steps still move the whole day.", author: nil)
            ]
        }
    }

    private func ensureEditableQuotesFile() {
        guard !FileManager.default.fileExists(atPath: quotesURL.path) else { return }

        do {
            try FileManager.default.createDirectory(
                at: quotesURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: bundledQuotesURL.path) {
                try FileManager.default.copyItem(at: bundledQuotesURL, to: quotesURL)
            } else {
                let fallbackQuotes = [
                    Quote(text: "Begin anywhere.", author: "John Cage"),
                    Quote(text: "The work teaches you how to do it.", author: nil),
                    Quote(text: "Small steps still move the whole day.", author: nil)
                ]
                let data = try JSONEncoder.prettyPrinted.encode(fallbackQuotes)
                try data.write(to: quotesURL)
            }
        } catch {
            print("Could not create editable quotes file: \(error)")
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalMinutes * 60), repeats: true) { [weak self] _ in
            self?.showQuoteNow()
        }
    }

    private func randomQuote() -> Quote {
        guard !quotes.isEmpty else {
            return Quote(text: "Add a few quotes and I will keep you company.", author: nil)
        }

        let availableIndexes = quotes.indices.filter { !recentQuoteIndexes.contains($0) }
        let index = (availableIndexes.randomElement() ?? quotes.indices.randomElement()) ?? 0
        recentQuoteIndexes.append(index)
        if recentQuoteIndexes.count > min(5, max(1, quotes.count - 1)) {
            recentQuoteIndexes.removeFirst()
        }
        return quotes[index]
    }

    private func showQuoteInMenu(_ quote: Quote) {
        let author = quote.author.map { " — \($0)" } ?? ""
        quoteItem.title = "“\(quote.text)”\(author)"
    }

    private func notify(_ quote: Quote) {
        showSpeechBubble(quote)
    }

    private func showSpeechBubble(_ quote: Quote) {
        let author = quote.author.map { "\n- \($0)" } ?? ""
        let body = "\(quote.text)\(author)"
        speechTextField?.stringValue = body
        let fontSize: CGFloat
        if body.count > 90 {
            fontSize = 25
        } else if body.count > 58 {
            fontSize = 28
        } else if body.count > 36 {
            fontSize = 31
        } else {
            fontSize = 34
        }
        speechTextField?.font = speechFont(size: fontSize)
        speechPawImageView?.isHidden = body.count > 110
        speechHideWorkItem?.cancel()
        speechWindow?.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            speechWindow?.animator().alphaValue = 1
        }

        let hideWorkItem = DispatchWorkItem { [weak self] in
            self?.hideSpeechBubble()
        }
        speechHideWorkItem = hideWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 7, execute: hideWorkItem)
    }

    private func hideSpeechBubble() {
        speechHideWorkItem?.cancel()
        speechHideWorkItem = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            speechWindow?.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.speechWindow?.orderOut(nil)
        }
    }

    @objc private func showQuoteNow() {
        let quote = randomQuote()
        showQuoteInMenu(quote)
        notify(quote)
    }

    @objc private func addQuote() {
        ensureEditableQuotesFile()
        NSWorkspace.shared.open(quotesURL)
    }

    @objc private func toggleCompanion() {
        companionVisible.toggle()
        if companionVisible {
            companionWindow?.orderFrontRegardless()
            toggleCompanionItem.title = "Hide Companion"
        } else {
            companionWindow?.orderOut(nil)
            speechWindow?.orderOut(nil)
            toggleCompanionItem.title = "Show Companion"
        }
    }

    @objc private func setInterval(_ sender: NSMenuItem) {
        guard let minutes = sender.representedObject as? Int else { return }
        intervalMinutes = minutes
        updateIntervalChecks()
        scheduleTimer()
    }

    private func updateIntervalChecks() {
        for item in intervalMenu.items {
            item.state = (item.representedObject as? Int) == intervalMinutes ? .on : .off
        }
    }

    @objc private func openQuotes() {
        ensureEditableQuotesFile()
        NSWorkspace.shared.open(quotesURL)
    }

    @objc private func reloadQuotes() {
        loadQuotes()
        showQuoteInMenu(randomQuote())
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

final class SpeechBubbleView: NSView {
    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let scaleX = bounds.width / 760
        let scaleY = bounds.height / 300
        func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            NSPoint(x: x * scaleX, y: y * scaleY)
        }

        let path = NSBezierPath()
        path.move(to: point(118, 282))
        path.curve(to: point(18, 188), controlPoint1: point(60, 280), controlPoint2: point(24, 248))
        path.curve(to: point(86, 56), controlPoint1: point(12, 126), controlPoint2: point(32, 78))
        path.curve(to: point(324, 42), controlPoint1: point(122, 42), controlPoint2: point(190, 41))
        path.line(to: point(622, 48))
        path.curve(to: point(735, 12), controlPoint1: point(650, 22), controlPoint2: point(690, 8))
        path.curve(to: point(738, 32), controlPoint1: point(748, 13), controlPoint2: point(752, 24))
        path.curve(to: point(718, 112), controlPoint1: point(710, 49), controlPoint2: point(706, 74))
        path.curve(to: point(642, 278), controlPoint1: point(733, 224), controlPoint2: point(708, 272))
        path.curve(to: point(118, 282), controlPoint1: point(512, 290), controlPoint2: point(248, 290))
        path.close()

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.16)
        shadow.shadowBlurRadius = 10
        shadow.shadowOffset = NSSize(width: 0, height: -3)
        shadow.set()
        NSColor(calibratedRed: 1.0, green: 0.992, blue: 0.965, alpha: 0.98).setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor(calibratedWhite: 0.06, alpha: 1).setStroke()
        path.lineWidth = max(6, min(bounds.width, bounds.height) * 0.035)
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }
}

final class HoverImageView: NSImageView {
    var onHoverChanged: ((Bool) -> Void)?
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverChanged?(false)
    }
}

let app = NSApplication.shared
let delegate = QuoteCompanion()
app.delegate = delegate
app.run()
