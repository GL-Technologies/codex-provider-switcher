import Foundation

final class AppPreferences: ObservableObject {
    private enum Keys {
        static let offerRestart = "offerRestartAfterSwitch"
        static let showKeys = "showKeysByDefault"
        static let accessSetupCompleted = "accessSetupCompleted"
        static let autoBridge = "autoBridgeEnabled"
    }

    @Published var offerRestartAfterSwitch: Bool {
        didSet { UserDefaults.standard.set(offerRestartAfterSwitch, forKey: Keys.offerRestart) }
    }

    @Published var showKeysByDefault: Bool {
        didSet { UserDefaults.standard.set(showKeysByDefault, forKey: Keys.showKeys) }
    }

    @Published var accessSetupCompleted: Bool {
        didSet { UserDefaults.standard.set(accessSetupCompleted, forKey: Keys.accessSetupCompleted) }
    }

    @Published var autoBridgeEnabled: Bool {
        didSet { UserDefaults.standard.set(autoBridgeEnabled, forKey: Keys.autoBridge) }
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

        if UserDefaults.standard.object(forKey: Keys.autoBridge) == nil {
            autoBridgeEnabled = true
        } else {
            autoBridgeEnabled = UserDefaults.standard.bool(forKey: Keys.autoBridge)
        }

        accessSetupCompleted = UserDefaults.standard.bool(forKey: Keys.accessSetupCompleted)
    }
}
