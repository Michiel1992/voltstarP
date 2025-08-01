//
//  ContentView.swift
//  MyStar
//
//  Created by Michiel Vanderlinden on 25/07/2025.
//

import SwiftUI
import Cocoa
import ServiceManagement

struct ContentView: View {
    @State private var isSettingsHovered = false
    @State private var isQuitHovered = false
    @State private var showingSettings = false
    @EnvironmentObject var polestarAPI: PolestarAPI
    
    private var chargingStatusText: String {
        guard let status = polestarAPI.carData?.chargingStatus else { return "Unknown" }
        switch status {
        case "CHARGING_STATUS_CHARGING", "CHARGING_STATUS_SMART_CHARGING":
            return "Charging"
        case "CHARGING_STATUS_DONE":
            return "Done"
        case "CHARGING_STATUS_SCHEDULED":
            return "Scheduled"
        case "CHARGING_STATUS_IDLE":
            return "Idle"
        case "CHARGING_STATUS_FAULT", "CHARGING_STATUS_ERROR":
            return "Error"
        case "CHARGING_STATUS_DISCHARGING":
            return "Discharging"
        default:
            return "Unknown"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Voltstar")
            }
            // Polestar car image
            HStack {
                Spacer()
                if let imageURL = polestarAPI.carData?.imageURL,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 240, height: 140)
                    }
                    .frame(width: 240, height: 140)
                    .cornerRadius(8)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 240, height: 140)
                }
                Spacer()
            }
            
            Divider()
            
            // 4 rows of text data
            VStack(alignment: .leading, spacing: 8) {
                
                HStack {
                    Image(systemName: "battery.100percent.bolt")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    Text("Battery:")
                    Spacer()
                    Text(String(format: "%.1f%%", polestarAPI.carData?.batteryPercentage ?? 0.0))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: "gauge.medium")
                        .foregroundColor(.primary)
                        .frame(width: 20)
                    Text("Range:")
                    Spacer()
                    Text("\(polestarAPI.carData?.rangeKm ?? 0)km / \(polestarAPI.carData?.rangeMiles ?? 0)mi")
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Image(systemName: "ev.charger")
                        .foregroundColor(.primary)
                        .frame(width: 20)
                    Text("Charge status:")
                    Spacer()
                    Text(chargingStatusText)
                        .foregroundColor(.primary)
                }
                
                
                HStack {
                    Image(systemName: "bolt.badge.clock")
                        .foregroundColor(.yellow)
                        .frame(width: 20)
                    Text("Charging time:")
                    Spacer()
                    Text(formatChargingTime(minutes: {
                        if let status = polestarAPI.carData?.chargingStatus {
                            if status == "CHARGING_STATUS_DONE" || status == "CHARGING_STATUS_IDLE" {
                                return 0
                            }
                        }
                        return polestarAPI.carData?.estimatedChargingTimeToFullMinutes ?? 0
                    }()))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                Divider()
                
                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Text("Settings")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onHover { isHovered in
                    isSettingsHovered = isHovered
                }
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.2))
                        .opacity(isSettingsHovered ? 1 : 0)
                )
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Text("Quit")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onHover { isHovered in
                    isQuitHovered = isHovered
                }
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.2))
                        .opacity(isQuitHovered ? 1 : 0)
                )
            }
            .font(.system(.body, design: .monospaced))
        }
        .padding()
        .frame(width: 280, height: 370)
        .background(Color(NSColor.windowBackgroundColor))
        .popover(isPresented: $showingSettings, arrowEdge: .top) {
            SettingsView()
        }
        .onAppear {
            // Set the shared instance for AppDelegate to use
            PolestarAPI.shared = polestarAPI
            loadDataIfCredentialsExist()
        }
    }
    
    private func loadDataIfCredentialsExist() {
        let email = UserDefaults.standard.string(forKey: "polestar_email") ?? ""
        let password = UserDefaults.standard.string(forKey: "polestar_password") ?? ""
        let vin = UserDefaults.standard.string(forKey: "polestar_vin") ?? ""
        
        print("🔵 ContentView checking credentials - Email: \(!email.isEmpty), Password: \(!password.isEmpty), VIN: \(!vin.isEmpty)")
        
        if !email.isEmpty && !password.isEmpty && !vin.isEmpty {
            print("🔵 ContentView found credentials, starting authentication...")
            Task { @MainActor in
                await polestarAPI.authenticate(email: email, password: password, vin: vin)
            }
        } else {
            print("🔵 ContentView: No complete credentials found")
        }
    }
    
    private func formatChargingTime(minutes: Int) -> String {
        if minutes == 0 {
            return "0 min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)min"
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var polestarAPI: PolestarAPI
    @State private var email: String = UserDefaults.standard.string(forKey: "polestar_email") ?? ""
    @State private var password: String = UserDefaults.standard.string(forKey: "polestar_password") ?? ""
    @State private var vinNumber: String = UserDefaults.standard.string(forKey: "polestar_vin") ?? ""
    @State private var selectedDisplayOption: StatusBarDisplayOption = {
        let saved = UserDefaults.standard.string(forKey: StatusBarDisplayOption.batteryPercentage.userDefaultsKey) ?? StatusBarDisplayOption.batteryPercentage.rawValue
        return StatusBarDisplayOption.allCases.first { $0.rawValue == saved } ?? .batteryPercentage
    }()
    @State private var launchAtStartup: Bool = UserDefaults.standard.bool(forKey: "launch_at_startup")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Polestar Account")
                .font(.headline)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email:")
                        .font(.system(size: 12))
                    TextField("Enter email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .frame(height: 22)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password:")
                        .font(.system(size: 12))
                    SecureField("Enter password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .frame(height: 22)
                        .disableAutocorrection(true)
                        .autocorrectionDisabled(true)
                        .textContentType(.none)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("VIN Number:")
                        .font(.system(size: 12))
                    TextField("Enter VIN", text: $vinNumber)
                        .textFieldStyle(.roundedBorder)
                        .frame(height: 22)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Status Bar Display:")
                        .font(.system(size: 12))
                    Picker("Display Option", selection: $selectedDisplayOption) {
                        ForEach(StatusBarDisplayOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(height: 22)
                }
                
                HStack {
                    Toggle("Launch at Startup", isOn: $launchAtStartup)
                        .font(.system(size: 12))
                        .onChange(of: launchAtStartup) {
                            setLaunchAtStartup(enabled: launchAtStartup)
                        }
                    Spacer()
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Save") {
                    UserDefaults.standard.set(email, forKey: "polestar_email")
                    UserDefaults.standard.set(password, forKey: "polestar_password")
                    UserDefaults.standard.set(vinNumber, forKey: "polestar_vin")
                    UserDefaults.standard.set(selectedDisplayOption.rawValue, forKey: selectedDisplayOption.userDefaultsKey)
                    UserDefaults.standard.set(launchAtStartup, forKey: "launch_at_startup")
                    
                    // Authenticate and fetch data
                    if !email.isEmpty && !password.isEmpty && !vinNumber.isEmpty {
                        Task { @MainActor in
                            await polestarAPI.authenticate(email: email, password: password, vin: vinNumber)
                        }
                    }
                    
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 20)
        }
        .padding(20)
        .frame(width: 400, height: 380)
        .onAppear {
            // Disable password autofill for this view
            NSApp.mainWindow?.makeFirstResponder(nil)
            
            // Check current launch at startup status
            if #available(macOS 13.0, *) {
                launchAtStartup = SMAppService.mainApp.status == .enabled
            }
        }
    }
    
    private func setLaunchAtStartup(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                UserDefaults.standard.set(enabled, forKey: "launch_at_startup")
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at startup: \(error)")
                // Revert the toggle if the operation failed
                DispatchQueue.main.async {
                    launchAtStartup = !enabled
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 250, height: 300)
}
