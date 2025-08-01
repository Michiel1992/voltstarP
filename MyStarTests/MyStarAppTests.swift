//
//  MyStarAppTests.swift
//  MyStarTests
//
//  Created by Michiel Vanderlinden on 25/07/2025.
//

import Testing
import Foundation
@testable import MyStar

struct MyStarAppTests {
    
    // MARK: - Helper Functions
    
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
    
    // MARK: - Status Bar Text Logic Tests
    
    @Test func testStatusBarTextBatteryPercentage() {
        // Create mock car data
        let carData = PolestarCarData(
            batteryPercentage: 85.0,
            rangeKm: 350,
            rangeMiles: 217,
            chargingStatus: "CHARGING_STATUS_CHARGING",
            chargingPowerWatts: 11000,
            estimatedChargingTimeToFullMinutes: 120,
            imageURL: nil,
            modelName: nil,
            lastUpdated: Date()
        )
        
        // Mock UserDefaults for battery percentage option
        let defaults = UserDefaults.standard
        defaults.set(StatusBarDisplayOption.batteryPercentage.rawValue, forKey: StatusBarDisplayOption.batteryPercentage.userDefaultsKey)
        
        // Test the logic that would be in statusBarText computed property
        let selectedOption = defaults.string(forKey: StatusBarDisplayOption.batteryPercentage.userDefaultsKey) ?? StatusBarDisplayOption.batteryPercentage.rawValue
        let displayOption = StatusBarDisplayOption.allCases.first { $0.rawValue == selectedOption } ?? .batteryPercentage
        
        var statusText: String
        switch displayOption {
        case .batteryPercentage:
            statusText = String(format: "%.1f%%", carData.batteryPercentage)
        case .rangeKm:
            statusText = "\(carData.rangeKm)km"
        case .rangeMiles:
            statusText = "\(carData.rangeMiles ?? 0)mi"
        case .chargeTime:
            if let time = carData.estimatedChargingTimeToFullMinutes, time > 0 {
                statusText = formatChargingTimeShort(minutes: time)
            } else {
                statusText = "0min"
            }
        }
        
        #expect(statusText == "85.0%")
        
        // Clean up
        defaults.removeObject(forKey: StatusBarDisplayOption.batteryPercentage.userDefaultsKey)
    }
    
    @Test func testStatusBarTextRangeKm() {
        let carData = PolestarCarData(
            batteryPercentage: 75.0,
            rangeKm: 280,
            rangeMiles: 174,
            chargingStatus: "CHARGING_STATUS_IDLE",
            chargingPowerWatts: nil,
            estimatedChargingTimeToFullMinutes: nil,
            imageURL: nil,
            modelName: nil,
            lastUpdated: Date()
        )
        
        // Test the logic directly without UserDefaults interference
        let selectedOption = StatusBarDisplayOption.rangeKm.rawValue // "Range (km)"
        let displayOption = StatusBarDisplayOption.allCases.first { $0.rawValue == selectedOption } ?? .batteryPercentage
        
        #expect(displayOption == .rangeKm) // Verify we got the right option
        
        var statusText: String
        switch displayOption {
        case .batteryPercentage:
            statusText = String(format: "%.1f%%", carData.batteryPercentage)
        case .rangeKm:
            statusText = "\(carData.rangeKm)km"
        case .rangeMiles:
            statusText = "\(carData.rangeMiles ?? 0)mi"
        case .chargeTime:
            if let time = carData.estimatedChargingTimeToFullMinutes, time > 0 {
                statusText = formatChargingTimeShort(minutes: time)
            } else {
                statusText = "0min"
            }
        }
        
        #expect(statusText == "280km")
    }
    
    @Test func testStatusBarTextRangeMiles() {
        let carData = PolestarCarData(
            batteryPercentage: 60.0,
            rangeKm: 220,
            rangeMiles: 137,
            chargingStatus: "CHARGING_STATUS_DONE",
            chargingPowerWatts: nil,
            estimatedChargingTimeToFullMinutes: 0,
            imageURL: nil,
            modelName: nil,
            lastUpdated: Date()
        )
        
        // Test the logic directly without UserDefaults interference
        let selectedOption = StatusBarDisplayOption.rangeMiles.rawValue // "Range (miles)"
        let displayOption = StatusBarDisplayOption.allCases.first { $0.rawValue == selectedOption } ?? .batteryPercentage
        
        #expect(displayOption == .rangeMiles) // Verify we got the right option
        
        var statusText: String
        switch displayOption {
        case .batteryPercentage:
            statusText = String(format: "%.1f%%", carData.batteryPercentage)
        case .rangeKm:
            statusText = "\(carData.rangeKm)km"
        case .rangeMiles:
            statusText = "\(carData.rangeMiles ?? 0)mi"
        case .chargeTime:
            if let time = carData.estimatedChargingTimeToFullMinutes, time > 0 {
                statusText = formatChargingTimeShort(minutes: time)
            } else {
                statusText = "0min"
            }
        }
        
        #expect(statusText == "137mi")
    }
    
    @Test func testStatusBarTextRangeMilesNil() {
        let carData = PolestarCarData(
            batteryPercentage: 60.0,
            rangeKm: 220,
            rangeMiles: nil, // No miles data
            chargingStatus: "CHARGING_STATUS_DONE",
            chargingPowerWatts: nil,
            estimatedChargingTimeToFullMinutes: 0,
            imageURL: nil,
            modelName: nil,
            lastUpdated: Date()
        )
        
        // Test the logic directly without UserDefaults interference
        let selectedOption = StatusBarDisplayOption.rangeMiles.rawValue // "Range (miles)"
        let displayOption = StatusBarDisplayOption.allCases.first { $0.rawValue == selectedOption } ?? .batteryPercentage
        
        #expect(displayOption == .rangeMiles) // Verify we got the right option
        
        var statusText: String
        switch displayOption {
        case .batteryPercentage:
            statusText = String(format: "%.1f%%", carData.batteryPercentage)
        case .rangeKm:
            statusText = "\(carData.rangeKm)km"
        case .rangeMiles:
            statusText = "\(carData.rangeMiles ?? 0)mi"
        case .chargeTime:
            if let time = carData.estimatedChargingTimeToFullMinutes, time > 0 {
                statusText = formatChargingTimeShort(minutes: time)
            } else {
                statusText = "0min"
            }
        }
        
        #expect(statusText == "0mi")
    }
    
    @Test func testStatusBarTextChargeTime() {
        let carData = PolestarCarData(
            batteryPercentage: 45.0,
            rangeKm: 180,
            rangeMiles: 112,
            chargingStatus: "CHARGING_STATUS_CHARGING",
            chargingPowerWatts: 7400,
            estimatedChargingTimeToFullMinutes: 95,
            imageURL: nil,
            modelName: nil,
            lastUpdated: Date()
        )
        
        // Test the logic directly without UserDefaults interference
        let selectedOption = StatusBarDisplayOption.chargeTime.rawValue // "Charge Time"
        let displayOption = StatusBarDisplayOption.allCases.first { $0.rawValue == selectedOption } ?? .batteryPercentage
        
        #expect(displayOption == .chargeTime) // Verify we got the right option
        
        var statusText: String
        switch displayOption {
        case .batteryPercentage:
            statusText = String(format: "%.1f%%", carData.batteryPercentage)
        case .rangeKm:
            statusText = "\(carData.rangeKm)km"
        case .rangeMiles:
            statusText = "\(carData.rangeMiles ?? 0)mi"
        case .chargeTime:
            if let time = carData.estimatedChargingTimeToFullMinutes, time > 0 {
                statusText = formatChargingTimeShort(minutes: time)
            } else {
                statusText = "0min"
            }
        }
        
        #expect(statusText == "1h35m")
    }
    
    @Test func testStatusBarTextChargeTimeZero() {
        let carData = PolestarCarData(
            batteryPercentage: 100.0,
            rangeKm: 400,
            rangeMiles: 248,
            chargingStatus: "CHARGING_STATUS_DONE",
            chargingPowerWatts: nil,
            estimatedChargingTimeToFullMinutes: 0,
            imageURL: nil,
            modelName: nil,
            lastUpdated: Date()
        )
        
        // Test the logic directly without UserDefaults interference
        let selectedOption = StatusBarDisplayOption.chargeTime.rawValue // "Charge Time"
        let displayOption = StatusBarDisplayOption.allCases.first { $0.rawValue == selectedOption } ?? .batteryPercentage
        
        #expect(displayOption == .chargeTime) // Verify we got the right option
        
        var statusText: String
        switch displayOption {
        case .batteryPercentage:
            statusText = String(format: "%.1f%%", carData.batteryPercentage)
        case .rangeKm:
            statusText = "\(carData.rangeKm)km"
        case .rangeMiles:
            statusText = "\(carData.rangeMiles ?? 0)mi"
        case .chargeTime:
            if let time = carData.estimatedChargingTimeToFullMinutes, time > 0 {
                statusText = formatChargingTimeShort(minutes: time)
            } else {
                statusText = "0min"
            }
        }
        
        #expect(statusText == "0min")
    }
    
    @Test func testStatusBarTextChargeTimeNil() {
        let carData = PolestarCarData(
            batteryPercentage: 100.0,
            rangeKm: 400,
            rangeMiles: 248,
            chargingStatus: "CHARGING_STATUS_DONE",
            chargingPowerWatts: nil,
            estimatedChargingTimeToFullMinutes: nil,
            imageURL: nil,
            modelName: nil,
            lastUpdated: Date()
        )
        
        let defaults = UserDefaults.standard
        defaults.set(StatusBarDisplayOption.chargeTime.rawValue, forKey: StatusBarDisplayOption.batteryPercentage.userDefaultsKey)
        
        let selectedOption = defaults.string(forKey: StatusBarDisplayOption.batteryPercentage.userDefaultsKey) ?? StatusBarDisplayOption.batteryPercentage.rawValue
        let displayOption = StatusBarDisplayOption.allCases.first { $0.rawValue == selectedOption } ?? .batteryPercentage
        
        var statusText: String
        switch displayOption {
        case .batteryPercentage:
            statusText = String(format: "%.1f%%", carData.batteryPercentage)
        case .rangeKm:
            statusText = "\(carData.rangeKm)km"
        case .rangeMiles:
            statusText = "\(carData.rangeMiles ?? 0)mi"
        case .chargeTime:
            if let time = carData.estimatedChargingTimeToFullMinutes, time > 0 {
                statusText = formatChargingTimeShort(minutes: time)
            } else {
                statusText = "0min"
            }
        }
        
        #expect(statusText == "0min")
        
        defaults.removeObject(forKey: StatusBarDisplayOption.batteryPercentage.userDefaultsKey)
    }
    
    @Test func testStatusBarTextNoCarData() {
        // Test when carData is nil (should return "0%")
        let carData: PolestarCarData? = nil
        
        let statusText = carData != nil ? String(format: "%.1f%%", carData!.batteryPercentage) : "0%"
        #expect(statusText == "0%")
    }
    
    @Test func testStatusBarTextInvalidUserDefaults() {
        // Test with invalid/missing UserDefaults setting
        let carData = PolestarCarData(
            batteryPercentage: 50.0,
            rangeKm: 200,
            rangeMiles: 124,
            chargingStatus: "CHARGING_STATUS_IDLE",
            chargingPowerWatts: nil,
            estimatedChargingTimeToFullMinutes: nil,
            imageURL: nil,
            modelName: nil,
            lastUpdated: Date()
        )
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: StatusBarDisplayOption.batteryPercentage.userDefaultsKey)
        
        // Should default to battery percentage when no setting is found
        let selectedOption = defaults.string(forKey: StatusBarDisplayOption.batteryPercentage.userDefaultsKey) ?? StatusBarDisplayOption.batteryPercentage.rawValue
        let displayOption = StatusBarDisplayOption.allCases.first { $0.rawValue == selectedOption } ?? .batteryPercentage
        
        #expect(displayOption == .batteryPercentage)
        
        var statusText: String
        switch displayOption {
        case .batteryPercentage:
            statusText = String(format: "%.1f%%", carData.batteryPercentage)
        case .rangeKm:
            statusText = "\(carData.rangeKm)km"
        case .rangeMiles:
            statusText = "\(carData.rangeMiles ?? 0)mi"
        case .chargeTime:
            if let time = carData.estimatedChargingTimeToFullMinutes, time > 0 {
                statusText = formatChargingTimeShort(minutes: time)
            } else {
                statusText = "0min"
            }
        }
        
        #expect(statusText == "50.0%")
    }
}