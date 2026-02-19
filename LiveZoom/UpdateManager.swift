import Cocoa
import Foundation

class UpdateManager {
    static let shared = UpdateManager()
    
    private let githubOwner = "ulfendk"
    private let githubRepo = "LiveZoom"
    private let checkInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private var checkTimer: Timer?
    
    private init() {}
    
    // MARK: - Public API
    
    func startAutoUpdateCheck() {
        guard isAutoUpdateEnabled() else {
            print("Auto-update is disabled")
            stopAutoUpdateCheck()
            return
        }
        
        print("Starting auto-update checks")
        
        // Check immediately on start
        checkForUpdates(userInitiated: false)
        
        // Schedule periodic checks
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkForUpdates(userInitiated: false)
        }
    }
    
    func stopAutoUpdateCheck() {
        print("Stopping auto-update checks")
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    func checkForUpdates(userInitiated: Bool) {
        print("Checking for updates...")
        
        let currentVersion = getCurrentVersion()
        print("Current version: \(currentVersion)")
        
        fetchLatestRelease { [weak self] result in
            switch result {
            case .success(let release):
                print("Latest release: \(release.version)")
                
                if self?.isNewerVersion(release.version, than: currentVersion) == true {
                    DispatchQueue.main.async {
                        self?.showUpdateAvailableDialog(release: release)
                    }
                } else if userInitiated {
                    DispatchQueue.main.async {
                        self?.showNoUpdateDialog()
                    }
                }
                
            case .failure(let error):
                print("Failed to check for updates: \(error)")
                if userInitiated {
                    DispatchQueue.main.async {
                        self?.showUpdateCheckFailedDialog(error: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Version Management
    
    func getCurrentVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
    
    private func isNewerVersion(_ newVersion: String, than currentVersion: String) -> Bool {
        let new = newVersion.replacingOccurrences(of: "v", with: "").split(separator: ".").compactMap { Int($0) }
        let current = currentVersion.replacingOccurrences(of: "v", with: "").split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(new.count, current.count) {
            let newPart = i < new.count ? new[i] : 0
            let currentPart = i < current.count ? current[i] : 0
            
            if newPart > currentPart {
                return true
            } else if newPart < currentPart {
                return false
            }
        }
        
        return false
    }
    
    // MARK: - GitHub API
    
    private func fetchLatestRelease(completion: @escaping (Result<Release, Error>) -> Void) {
        let urlString = "https://api.github.com/repos/\(githubOwner)/\(githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else {
            completion(.failure(UpdateError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(UpdateError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let releaseResponse = try decoder.decode(GitHubRelease.self, from: data)
                
                // Find DMG asset
                let dmgAsset = releaseResponse.assets.first { $0.name.hasSuffix(".dmg") }
                
                let release = Release(
                    version: releaseResponse.tagName,
                    name: releaseResponse.name ?? releaseResponse.tagName,
                    releaseNotes: releaseResponse.body ?? "No release notes available",
                    downloadURL: dmgAsset?.browserDownloadUrl ?? releaseResponse.htmlUrl,
                    publishedAt: releaseResponse.publishedAt
                )
                
                completion(.success(release))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - User Dialogs
    
    private func showUpdateAvailableDialog(release: Release) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = """
        A new version of LiveZoom is available!
        
        Current version: \(getCurrentVersion())
        New version: \(release.version)
        
        \(release.name)
        
        Would you like to download it now?
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Release Notes")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Download
            openURL(release.downloadURL)
        } else if response == .alertSecondButtonReturn {
            // Show release notes then ask again
            showReleaseNotesDialog(release: release)
        }
    }
    
    private func showReleaseNotesDialog(release: Release) {
        let alert = NSAlert()
        alert.messageText = "Release Notes - \(release.version)"
        alert.informativeText = release.releaseNotes
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Close")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            openURL(release.downloadURL)
        }
    }
    
    private func showNoUpdateDialog() {
        let alert = NSAlert()
        alert.messageText = "No Updates Available"
        alert.informativeText = "You are running the latest version of LiveZoom (\(getCurrentVersion()))."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showUpdateCheckFailedDialog(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Failed to check for updates: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Settings
    
    func isAutoUpdateEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "autoUpdate")
    }
    
    func setAutoUpdateEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "autoUpdate")
        
        if enabled {
            startAutoUpdateCheck()
        } else {
            stopAutoUpdateCheck()
        }
    }
}

// MARK: - Models

struct Release {
    let version: String
    let name: String
    let releaseNotes: String
    let downloadURL: String
    let publishedAt: String
}

struct GitHubRelease: Codable {
    let tagName: String
    let name: String?
    let body: String?
    let htmlUrl: String
    let publishedAt: String
    let assets: [GitHubAsset]
}

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadUrl: String
}

enum UpdateError: LocalizedError {
    case invalidURL
    case noData
    case invalidVersion
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid GitHub API URL"
        case .noData:
            return "No data received from GitHub API"
        case .invalidVersion:
            return "Invalid version format"
        }
    }
}
