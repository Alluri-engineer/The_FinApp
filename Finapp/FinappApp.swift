//
//  FinappApp.swift
//  Finapp
//
//  Created by Alluri santosh Varma on 3/7/25.
//

import SwiftUI
import SwiftData

// Define a schema version for migration purposes
enum SchemaVersion: Int {
    case v1 = 1
}

@main
struct FinappApp: App {
    @State private var showMigrationAlert = false
    
    var sharedModelContainer: ModelContainer = {
        // Define the current schema version
        let currentVersion = SchemaVersion.v1
        
        // Create the schema with all model types
        let schema = Schema([
            Wallet.self,
            Transaction.self,
            CryptoAsset.self
        ])
        
        // Create a URL for the database file
        let url = URL.applicationSupportDirectory.appending(path: "Finapp.sqlite")
        
        // Configure the model with persistent storage
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            // Create the container with the configuration
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("Database successfully connected at: \(url.path())")
            return container
        } catch {
            print("SwiftData error: \(error)")
            
            // Try to reset the database
            resetSwiftDataStorage(at: url)
            
            // Fallback to in-memory only as a last resort
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
            WalletView()
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
    
    // Helper function to reset SwiftData storage
    static func resetSwiftDataStorage(at url: URL? = nil) {
        let fileManager = FileManager.default
        
        // If a specific URL is provided, use it; otherwise, find the default location
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
        
        // Also try to remove any auxiliary files
        let storeDirectory = storeURL.deletingLastPathComponent()
        let storeName = storeURL.lastPathComponent
        let storeBaseName = storeName.components(separatedBy: ".").first ?? storeName
        
        do {
            // Get all files in the directory
            let directoryContents = try fileManager.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
            
            // Find all files related to our database
            let storePaths = directoryContents.filter { url in
                let filename = url.lastPathComponent
                return filename.hasPrefix(storeBaseName)
            }
            
            // Delete each file
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
    
    // Helper to check if the database exists
    static func databaseExists() -> Bool {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return false
        }
        let storeURL = appSupportURL.appendingPathComponent("Finapp.sqlite")
        return fileManager.fileExists(atPath: storeURL.path)
    }
}
