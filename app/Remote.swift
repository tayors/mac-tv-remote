import AppKit
import SwiftUI

final class RemoteState: ObservableObject {
    @Published var title = "Set up your TV"
    @Published var subtitle = "Add its ADB address to get started."
    @Published var remoteName = "Your TV"
    @Published var deviceModel = "Android / Google TV"
    @Published var availableApps: [String] = []
    @Published var feedback = ""
    @Published var connected = false
    @Published var refreshing = false
    @Published var busy = false
    @Published var endpoint = ""
    @Published var currentApp = ""
    var action: ((String) -> Void)?
}

struct RemoteKeyStyle: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background(prominent ? Color.accentColor : Color.primary.opacity(configuration.isPressed ? 0.12 : 0.055))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct RemoteContent: View {
    @ObservedObject var state: RemoteState
    @Environment(\.colorScheme) var scheme
    @State private var hovered = ""
    private let apps = [("YouTube", "youtube", "play.rectangle.fill"), ("Stremio", "stremio", "play.circle.fill"),
                        ("Netflix", "netflix", "n.square.fill"), ("Prime Video", "prime", "play.tv.fill"),
                        ("Disney+", "disney", "sparkles.tv.fill"), ("Apple TV", "apple", "appletv.fill")]
    private func send(_ command: String) { state.action?(command) }

    private func iconKey(_ symbol: String, title: String, command: String, size: CGFloat = 46) -> some View {
        Button { send(command) } label: {
            Image(systemName: symbol).font(.system(size: 17, weight: .medium)).frame(width: size, height: size)
        }
        .buttonStyle(RemoteKeyStyle()).help(title).accessibilityLabel(title)
        .disabled(state.endpoint.isEmpty || (!state.connected && command != "wake")).opacity(!state.connected && command != "wake" ? 0.5 : 1)
    }
    private func direction(_ symbol: String, title: String, command: String, x: CGFloat, y: CGFloat) -> some View {
        Button { send(command) } label: {
            Image(systemName: symbol).font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.92)).frame(width: 62, height: 55)
                .background(hovered == command ? Color.white.opacity(0.10) : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain).offset(x: x, y: y).help(title).accessibilityLabel(title)
        .onHover { hovered = $0 ? command : "" }
    }
    private var dpad: some View {
        ZStack {
            Circle().fill(Color(red: 0.18, green: 0.20, blue: 0.24))
            Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            direction("chevron.up", title: "Up", command: "up", x: 0, y: -72)
            direction("chevron.left", title: "Left", command: "left", x: -73, y: 0)
            direction("chevron.right", title: "Right", command: "right", x: 73, y: 0)
            direction("chevron.down", title: "Down", command: "down", x: 0, y: 72)
            Button { send("select") } label: {
                Text("OK").font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white).frame(width: 82, height: 82)
                    .background(Circle().fill(Color(red: 0.27, green: 0.30, blue: 0.36)))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
            }.buttonStyle(.plain).help("Select · Return").accessibilityLabel("OK")
        }.frame(width: 212, height: 212)
        .shadow(color: .black.opacity(scheme == .dark ? 0.15 : 0.13), radius: 12, y: 7)
        .opacity(state.connected ? 1 : 0.55).disabled(!state.connected)
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 11) {
                Image(systemName: "tv").font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.remoteName).font(.system(size: 23, weight: .semibold, design: .rounded))
                    Text(state.deviceModel).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Button { send("settings") } label: {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 17)).frame(width: 32, height: 36)
                }.buttonStyle(.plain).foregroundStyle(.secondary).help("Connection settings").accessibilityLabel("Settings")
            }.padding(.bottom, 18)

            HStack(alignment: .center, spacing: 10) {
                Circle().fill(state.connected ? Color.green : Color.orange).frame(width: 7, height: 7)
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    Text(state.subtitle).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button { send(state.endpoint.isEmpty ? "settings" : "refresh") } label: {
                    ZStack {
                        Image(systemName: state.endpoint.isEmpty ? "plus" : "arrow.clockwise").opacity(state.refreshing ? 0 : 1)
                        if state.refreshing { ProgressView().controlSize(.small).scaleEffect(0.75) }
                    }.frame(width: 30, height: 32)
                }.buttonStyle(.plain).help(state.endpoint.isEmpty ? "Set up TV connection" : "Refresh TV status").accessibilityLabel(state.endpoint.isEmpty ? "Set up TV" : "Refresh")
            }
            .padding(.horizontal, 13).frame(height: 68)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 13))
            .padding(.bottom, 20)

            dpad.padding(.bottom, 18)

            HStack(spacing: 12) {
                iconKey("arrow.uturn.backward", title: "Back · Escape", command: "back")
                iconKey("house", title: "Home", command: "home")
                iconKey("moon", title: "Sleep", command: "sleep")
                iconKey("power", title: "Turn on", command: "wake")
            }.padding(.bottom, 17)

            HStack(spacing: 11) {
                HStack(spacing: 0) {
                    Button { send("volume-down") } label: {
                        Image(systemName: "minus").font(.system(size: 16, weight: .medium)).frame(width: 40, height: 46)
                    }.help("Volume down").accessibilityLabel("Volume down")
                    Image(systemName: "speaker.wave.2").font(.system(size: 15)).foregroundStyle(.secondary).frame(width: 30)
                    Button { send("volume-up") } label: {
                        Image(systemName: "plus").font(.system(size: 16, weight: .medium)).frame(width: 40, height: 46)
                    }.help("Volume up").accessibilityLabel("Volume up")
                }.buttonStyle(.plain).background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 13))
                iconKey("speaker.slash", title: "Mute / unmute", command: "mute")
                Button { send("play-pause") } label: {
                    Image(systemName: "playpause.fill").font(.system(size: 19)).frame(width: 70, height: 46)
                }.buttonStyle(RemoteKeyStyle(prominent: true)).help("Play / pause · Space").accessibilityLabel("Play / pause")
            }.disabled(!state.connected).opacity(state.connected ? 1 : 0.5)
            .padding(.bottom, 20)

            HStack {
                Text("Open an app").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                Spacer()
                if state.busy { ProgressView().controlSize(.mini) }
            }.padding(.bottom, 9)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(apps.filter { state.availableApps.contains($0.1) }, id: \.1) { app in
                    Button { send(app.1) } label: {
                        VStack(spacing: 5) {
                            Image(systemName: app.2).font(.system(size: 20, weight: .medium))
                            Text(app.0).font(.system(size: 10, weight: .medium)).lineLimit(1)
                        }.frame(maxWidth: .infinity).frame(height: 57)
                    }.buttonStyle(RemoteKeyStyle()).help("Open \(app.0)").accessibilityLabel(app.0)
                }
            }
            .overlay {
                if state.availableApps.isEmpty {
                    Text(state.connected ? "No recognised app shortcuts found." : "Connect your TV to discover app shortcuts.")
                        .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
            }
            .frame(height: 122).disabled(!state.connected).opacity(state.connected ? 1 : 0.5)
            .padding(.bottom, 14)

            HStack(alignment: .center, spacing: 8) {
                Text(state.feedback.isEmpty ? "Arrow keys navigate · Return selects" : state.feedback)
                    .font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Menu {
                    Button("Reconnect to TV") { send("reconnect") }
                    Button("Connection settings…") { send("settings") }
                    Divider()
                    Button("Quit TV Remote") { send("quit") }
                } label: { Image(systemName: "ellipsis.circle").font(.system(size: 17)) }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().help("More options").accessibilityLabel("More options")
            }.frame(height: 28)
        }
        .padding(22).frame(width: 350)
        .background(scheme == .dark ? Color(nsColor: .windowBackgroundColor) : Color(red: 0.965, green: 0.972, blue: 0.982))
    }
}

final class RemoteView: NSView {
    var command: ((String) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
        if !event.modifierFlags.intersection([.command, .control, .option]).isEmpty { super.keyDown(with: event); return }
        let keys: [UInt16: String] = [123:"left",124:"right",125:"down",126:"up",36:"select",49:"play-pause",53:"back"]
        if let action = keys[event.keyCode] { command?(action) } else { super.keyDown(with: event) }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let popover = NSPopover()
    let model = RemoteState()
    let root = RemoteView()
    let defaults = UserDefaults.standard
    let commands = DispatchQueue(label: "org.mactvremote.commands")
    let statusQueue = DispatchQueue(label: "org.mactvremote.status")
    var statusProcess: Process?
    var statusID = UUID()
    var pending = 0
    var lastRefresh = Date.distantPast
    var refreshTimer: Timer?
    var endpoint: String { defaults.string(forKey: "device") ?? "" }
    var mac: String { defaults.string(forKey: "mac") ?? "" }
    var broadcast: String { defaults.string(forKey: "broadcast") ?? "" }
    var remoteName: String { defaults.string(forKey: "remoteName") ?? "Your TV" }
    var discoveredEndpoint = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        item.button?.image = NSImage(systemSymbolName: "tv", accessibilityDescription: "TV Remote")
        item.button?.target = self; item.button?.action = #selector(toggle)
        item.button?.toolTip = "Mac TV Remote"
        model.remoteName = remoteName
        model.action = { [weak self] in self?.send($0) }
        root.command = model.action
        let host = NSHostingView(rootView: RemoteContent(state: model).tint(Color(red: 0.14, green: 0.36, blue: 0.82)))
        let size = host.fittingSize
        root.frame = NSRect(origin: .zero, size: size)
        host.frame = root.bounds; host.autoresizingMask = [.width, .height]
        root.addSubview(host)
        let controller = NSViewController(); controller.view = root
        popover.contentViewController = controller; popover.behavior = .transient; popover.contentSize = size
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            guard let self = self, self.popover.isShown, !self.model.refreshing, self.pending == 0 else { return }
            self.refresh()
        }
        DispatchQueue.main.async { self.show() }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { show(); return false }
    func show() {
        guard !popover.isShown, let button = item.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        root.window?.makeFirstResponder(root)
        if Date().timeIntervalSince(lastRefresh) > 15 && !model.refreshing { refresh() }
    }
    @objc func toggle() { if popover.isShown { popover.performClose(nil) } else { show() } }
    func send(_ action: String) {
        switch action {
        case "quit": NSApp.terminate(nil)
        case "settings": settings()
        case "refresh": refresh()
        case "reconnect": refresh(reconnect: true)
        default:
            guard model.connected || action == "wake" else { model.feedback = "Connect to the TV before sending controls."; return }
            execute(action)
        }
    }
    func refresh(reconnect: Bool = false) {
        guard !endpoint.isEmpty else {
            model.title = "Set up your TV"; model.subtitle = "Add its ADB address in Settings."; return
        }
        if model.refreshing && !reconnect { model.feedback = "Checking the TV connection…"; return }
        // Refresh has its own queue and cancels a previous status request.
        if let process = statusProcess, process.isRunning { process.terminate() }
        let id = UUID(); statusID = id
        let process = Process(); statusProcess = process
        let device = endpoint, address = mac, subnet = broadcast
        let discover = discoveredEndpoint != device || reconnect
        model.endpoint = device; model.refreshing = true
        model.title = reconnect ? "Reconnecting…" : (model.connected ? "Connected" : "Connecting to TV")
        model.subtitle = "Checking \(device)…"
        statusQueue.async { [weak self] in
            let result = Self.run(reconnect ? "reconnect" : "status", device: device, mac: address, broadcast: subnet, process: process, discover: discover)
            DispatchQueue.main.async {
                guard let self = self, self.statusID == id else { return }
                self.model.refreshing = false; self.statusProcess = nil
                self.lastRefresh = Date()
                if result.0, let data = result.1.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.model.connected = true
                    if let apps = json["available_apps"] as? [String] {
                        self.model.availableApps = apps; self.discoveredEndpoint = device
                    }
                    if let deviceModel = json["model"] as? String { self.model.deviceModel = deviceModel }
                    let power = json["power"] as? String ?? "unknown"
                    let app = json["foreground_app"] as? String ?? ""
                    let names = ["com.stremio.one":"Stremio", "com.google.android.youtube.tv":"YouTube", "com.netflix.ninja":"Netflix", "com.amazon.amazonvideo.livingroom":"Prime Video", "com.google.android.apps.tv.launcherx":"Google TV home", "com.disney.disneyplus":"Disney+", "com.apple.atve.androidtv.appletv":"Apple TV"]
                    self.model.currentApp = names[app] ?? app
                    self.model.title = power == "Awake" ? "Connected · TV on" : "Connected · \(power.lowercased())"
                    self.model.subtitle = "\(self.model.currentApp.isEmpty ? "Ready to control" : self.model.currentApp) · \(device)"
                    self.model.feedback = "Updated \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)) · Space plays / pauses"
                    self.item.button?.image = NSImage(systemSymbolName: "tv", accessibilityDescription: "TV connected")
                } else { self.connectionFailed(result.1) }
            }
        }
    }
    func connectionFailed(_ error: String) {
        model.connected = false; model.title = "Can’t connect to TV"
        let text = error.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.localizedCaseInsensitiveContains("unauthorized") || text.localizedCaseInsensitiveContains("authorization") {
            model.subtitle = "Accept the ADB authorization prompt on the TV."
        } else if text.contains("No route to host") {
            model.subtitle = "Network access failed. Try Reconnect in More options."
        } else if text.localizedCaseInsensitiveContains("refused") {
            model.subtitle = "TV refused ADB. Check its debugging setting."
        } else { model.subtitle = String(text.prefix(130)) }
        model.feedback = "\(endpoint) · Open More options to reconnect."
        NSLog("TV Remote: %@", text)
    }
    func execute(_ action: String) {
        guard pending < 3 else { model.feedback = "Waiting for the TV. Try again in a moment."; return }
        pending += 1; model.busy = true
        let device = endpoint, address = mac, subnet = broadcast
        model.feedback = action == "wake" ? "Sending wake signal…" : "Sending \(action.replacingOccurrences(of: "-", with: " "))…"
        commands.async { [weak self] in
            let result = Self.run(action, device: device, mac: address, broadcast: subnet, process: Process())
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.pending -= 1; self.model.busy = self.pending > 0
                if result.0 {
                    self.model.feedback = "Sent \(action.replacingOccurrences(of: "-", with: " "))"
                    if ["wake", "sleep", "home", "youtube", "stremio", "prime", "netflix", "disney", "apple"].contains(action) {
                        self.refresh()
                    }
                } else if result.1.contains("No launchable TV activity") {
                    self.model.feedback = "This app is not available on the TV."
                } else { self.connectionFailed(result.1) }
            }
        }
        root.window?.makeFirstResponder(root)
    }
    static func run(_ action: String, device: String, mac: String, broadcast: String, process: Process, discover: Bool = false) -> (Bool, String) {
        guard let resources = Bundle.main.resourceURL else { return (false, "App resources are missing. Reinstall TV Remote.") }
        let pythonCandidates = ["/opt/homebrew/bin/python3", "/usr/local/bin/python3", "/usr/bin/python3"]
        guard let python = pythonCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else { return (false, "Python 3 was not found.") }
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: python)
        process.arguments = ["-B", resources.appendingPathComponent("remote_bridge.py").path, "--device", device, "--mac", mac, "--broadcast", broadcast, action == "play-pause" ? "toggle-playback" : action]
        if discover { process.arguments?.append("--discover") }
        process.standardOutput = pipe; process.standardError = pipe
        let timeout = DispatchWorkItem { if process.isRunning { process.terminate() } }
        do {
            try process.run()
            DispatchQueue.global().asyncAfter(deadline: .now() + (action == "wake" || discover ? 38 : 25), execute: timeout)
            let output = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit(); timeout.cancel()
            let text = String(data: output, encoding: .utf8) ?? ""
            return (process.terminationStatus == 0, text.isEmpty && process.terminationStatus != 0 ? "Connection was interrupted or timed out. Try Refresh." : text)
        } catch { timeout.cancel(); return (false, error.localizedDescription) }
    }
    func settings() {
        popover.performClose(nil)
        let alert = NSAlert(); alert.messageText = "Set up your TV"
        alert.informativeText = "Use the ADB address shown by your TV. Enable debugging and authorize this Mac on the TV. Network wake details are optional."
        alert.addButton(withTitle: "Save and connect"); alert.addButton(withTitle: "Cancel")
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 310, height: 218))
        var fields: [NSTextField] = []
        for (i, pair) in [("Remote name", remoteName), ("ADB address", endpoint), ("Wake MAC (optional)", mac), ("Broadcast IPv4 (optional)", broadcast)].enumerated() {
            let y = CGFloat(193 - i * 53)
            let label = NSTextField(labelWithString: pair.0); label.frame = NSRect(x: 0, y: y, width: 310, height: 20); view.addSubview(label)
            let field = NSTextField(string: pair.1); field.frame = NSRect(x: 0, y: y - 24, width: 310, height: 24); view.addSubview(field); fields.append(field)
        }
        fields[1].placeholderString = "TV_IP:PORT"
        alert.accessoryView = view
        while alert.runModal() == .alertFirstButtonReturn {
            let values = fields.map { $0.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) }
            let address = values[1].split(separator: ":", omittingEmptySubsequences: false)
            let validAddress = address.count == 2 && address[0].range(of: "^[A-Za-z0-9][A-Za-z0-9.-]*$", options: .regularExpression) != nil && Int(address[1]).map { (1...65535).contains($0) } == true
            let validMAC = values[2].range(of: "^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$", options: .regularExpression) != nil
            let parts = values[3].split(separator: ".", omittingEmptySubsequences: false)
            let validBroadcast = parts.count == 4 && parts.allSatisfy { Int($0).map { (0...255).contains($0) } == true }
            let validWake = (values[2].isEmpty && values[3].isEmpty) || (validMAC && validBroadcast)
            guard !values[0].isEmpty && values[0].count <= 40 && validAddress && validWake else {
                alert.informativeText = "Use a name up to 40 characters and a valid hostname or IPv4 address with a port. Set both wake fields, or leave both blank."; continue
            }
            for (key, value) in zip(["remoteName", "device", "mac", "broadcast"], values) { defaults.set(value, forKey: key) }
            model.remoteName = values[0]; model.connected = false; model.availableApps = []; discoveredEndpoint = ""
            refresh(reconnect: true); break
        }
        show()
    }

}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
