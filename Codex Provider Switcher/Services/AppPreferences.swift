import Foundation

final class AppPreferences: ObservableObject {
    private enum Keys {
        static let offerRestart = "offerRestartAfterSwitch"
        static let showKeys = "showKeysByDefault"
    }

    @Published var offerRestartAfterSwitch: Bool {
        didSet { UserDefaults.standard.set(offerRestartAfterSwitch, forKey: Keys.offerRestart) }
    }

    @Published var showKeysByDefault: Bool {
        didSet { UserDefaults.standard.set(showKeysByDefault, forKey: Keys.showKeys) }
    }

    init() {
        if UserDefaults.standard.object(forKey: Keys.offerRestart) == nil {
            offerRestartAfterSwitch = true
        } else {
            offerRestartAfterSwitch = UserDefaults.standard.bool(forKey: Keys.offerRestart)
        }

        if UserDefaults.standard.object(forKey: Keys.showKeys) == nil {
            showKeysByDefault = true
        } else {
            showKeysByDefault = UserDefaults.standard.bool(forKey: Keys.showKeys)
        }
    }
}
