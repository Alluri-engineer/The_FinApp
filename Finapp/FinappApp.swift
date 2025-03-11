import SwiftUI
import SwiftData

enum SchemaVersion: Int {
    case v1 = 1
}

@main
struct FinappApp: App {
    @State private var showMigrationAlert = false
    
    var sharedModelContainer: ModelContainer = {
        let currentVersion = SchemaVersion.v1
        let schema = Schema([
            Wallet.self,
            Transaction.self,
            CryptoAsset.self,
            Stock.self
        ])
        
        let url = URL.applicationSupportDirectory.appending(path: "Finapp.sqlite")
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("Database successfully connected at: \(url.path())")
            return container
        } catch {
            print("SwiftData error: \(error)")
            resetSwiftDataStorage(at: url)
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                print("Using in-memory database as fallback")
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)

                WalletView()
                    .tabItem {
                        Image(systemName: "creditcard.fill")
                        Text("Wallet")
                    }
                    .tag(1)

                MoreView()
                    .tabItem {
                        Image(systemName: "ellipsis.circle.fill")
                        Text("More")
                    }
                    .tag(2)
            }
            .tint(.blue) // Sets the active tab and icon color
            .background(AppTheme.backgroundColor) // Add this line to set the tab bar background
            .alert("Database Migration", isPresented: $showMigrationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The database has been reset due to schema changes. Your data has been initialized with default values.")
            }
            .onAppear {
                if UserDefaults.standard.bool(forKey: "didResetDatabase") {
                    showMigrationAlert = true
                    UserDefaults.standard.set(false, forKey: "didResetDatabase")
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    static func resetSwiftDataStorage(at url: URL? = nil) {
        let fileManager = FileManager.default
        let storeURL: URL
        if let url = url {
            storeURL = url
        } else {
            guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                print("Could not find application support directory")
                return
            }
            storeURL = appSupportURL.appendingPathComponent("Finapp.sqlite")
        }
        
        let storeDirectory = storeURL.deletingLastPathComponent()
        let storeName = storeURL.lastPathComponent
        let storeBaseName = storeName.components(separatedBy: ".").first ?? storeName
        
        do {
            let directoryContents = try fileManager.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
            let storePaths = directoryContents.filter { url in
                let filename = url.lastPathComponent
                return filename.hasPrefix(storeBaseName)
            }
            for path in storePaths {
                try fileManager.removeItem(at: path)
                print("Removed database file: \(path.lastPathComponent)")
            }
            UserDefaults.standard.set(true, forKey: "didResetDatabase")
            print("Successfully reset SwiftData storage")
        } catch {
            print("Failed to reset SwiftData storage: \(error)")
        }
    }
    
    static func databaseExists() -> Bool {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return false
        }
        let storeURL = appSupportURL.appendingPathComponent("Finapp.sqlite")
        return fileManager.fileExists(atPath: storeURL.path)
    }
}
