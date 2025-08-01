//
//  MyStarApp.swift
//  MyStar
//
//  Created by Michiel Vanderlinden on 25/07/2025.
//

import SwiftUI

enum StatusBarDisplayOption: String, CaseIterable {
    case batteryPercentage = "Battery Percentage"
    case rangeKm = "Range (km)"
    case rangeMiles = "Range (miles)"
    case chargeTime = "Charge Time"
    
    var userDefaultsKey: String { "statusbar_display_option" }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Load data after app is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            Task { @MainActor in
                self.loadDataIfCredentialsExist()
            }
        }
    }
    
    @MainActor
    private func loadDataIfCredentialsExist() {
        let email = UserDefaults.standard.string(forKey: "polestar_email") ?? ""
        let password = UserDefaults.standard.string(forKey: "polestar_password") ?? ""
        let vin = UserDefaults.standard.string(forKey: "polestar_vin") ?? ""
        
        print("🔵 AppDelegate checking credentials at startup - Email: \(!email.isEmpty), Password: \(!password.isEmpty), VIN: \(!vin.isEmpty)")
        
        if !email.isEmpty && !password.isEmpty && !vin.isEmpty {
            print("🔵 AppDelegate found credentials, starting authentication...")
            if let api = PolestarAPI.shared {
                Task { @MainActor in
                    await api.authenticate(email: email, password: password, vin: vin)
                }
            } else {
                print("❌ PolestarAPI.shared not available in AppDelegate")
            }
        } else {
            print("🔵 AppDelegate: No complete credentials found at startup")
        }
    }
}

// Global PolestarAPI instance
private let globalPolestarAPI = PolestarAPI()

@main
struct MyStarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var polestarAPI = globalPolestarAPI
    
    init() {
        // Set the shared instance immediately
        PolestarAPI.shared = globalPolestarAPI
    }
    
    
    
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(polestarAPI)
        } label: {
            HStack(spacing: 4) {
                Text(statusBarText)
                    .font(.system(size: 8, weight: .ultraLight))
                Image(systemName: "bolt.car")
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    private var statusBarText: String {
        guard let carData = polestarAPI.carData else { return "0%" }
        
        let selectedOption = UserDefaults.standard.string(forKey: StatusBarDisplayOption.batteryPercentage.userDefaultsKey) ?? StatusBarDisplayOption.batteryPercentage.rawValue
        let displayOption = StatusBarDisplayOption.allCases.first { $0.rawValue == selectedOption } ?? .batteryPercentage
        
        switch displayOption {
        case .batteryPercentage:
            return String(format: "%.1f%%", carData.batteryPercentage)
        case .rangeKm:
            return "\(carData.rangeKm)km"
        case .rangeMiles:
            return "\(carData.rangeMiles ?? 0)mi"
        case .chargeTime:
            if carData.chargingStatus == "CHARGING_STATUS_DONE" || carData.chargingStatus == "CHARGING_STATUS_IDLE" {
                return "0min"
            }
            if let time = carData.estimatedChargingTimeToFullMinutes, time > 0 {
                return formatChargingTimeShort(minutes: time)
            }
            return "0min"
        }
    }
    
    private func formatChargingTimeShort(minutes: Int) -> String {
        if minutes == 0 {
            return "0min"
        } else if minutes < 60 {
            return "\(minutes)min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h\(remainingMinutes)m"
            }
        }
    }
    
}
