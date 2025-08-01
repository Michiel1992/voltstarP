//
//  MyStarTests.swift
//  MyStarTests
//
//  Created by Michiel Vanderlinden on 25/07/2025.
//

import Testing
import Foundation
@testable import MyStar

struct MyStarTests {
    
    // MARK: - PolestarCarData Tests
    
    @Test func testPolestarCarDataInitialization() {
        let carData = PolestarCarData(
            batteryPercentage: 85.0,
            rangeKm: 350,
            rangeMiles: 217,
            chargingStatus: "CHARGING_STATUS_CHARGING",
            chargingPowerWatts: 11000,
            estimatedChargingTimeToFullMinutes: 120,
            imageURL: "https://example.com/car.jpg",
            modelName: "Polestar 2",
            lastUpdated: Date()
        )
        
        #expect(carData.batteryPercentage == 85.0)
        #expect(carData.rangeKm == 350)
        #expect(carData.rangeMiles == 217)
        #expect(carData.chargingStatus == "CHARGING_STATUS_CHARGING")
        #expect(carData.chargingPowerWatts == 11000)
        #expect(carData.estimatedChargingTimeToFullMinutes == 120)
        #expect(carData.imageURL == "https://example.com/car.jpg")
        #expect(carData.modelName == "Polestar 2")
    }
    
    @Test func testPolestarCarDataWithOptionalValues() {
        let carData = PolestarCarData(
            batteryPercentage: 50.0,
            rangeKm: 200,
            rangeMiles: nil,
            chargingStatus: "CHARGING_STATUS_IDLE",
            chargingPowerWatts: nil,
            estimatedChargingTimeToFullMinutes: nil,
            imageURL: nil,
            modelName: nil,
            lastUpdated: Date()
        )
        
        #expect(carData.batteryPercentage == 50.0)
        #expect(carData.rangeKm == 200)
        #expect(carData.rangeMiles == nil)
        #expect(carData.chargingStatus == "CHARGING_STATUS_IDLE")
        #expect(carData.chargingPowerWatts == nil)
        #expect(carData.estimatedChargingTimeToFullMinutes == nil)
        #expect(carData.imageURL == nil)
        #expect(carData.modelName == nil)
    }
}

// MARK: - StatusBarDisplayOption Tests

struct StatusBarDisplayOptionTests {
    
    @Test func testAllCasesExist() {
        let allCases = StatusBarDisplayOption.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.batteryPercentage))
        #expect(allCases.contains(.rangeKm))
        #expect(allCases.contains(.rangeMiles))
        #expect(allCases.contains(.chargeTime))
    }
    
    @Test func testRawValues() {
        #expect(StatusBarDisplayOption.batteryPercentage.rawValue == "Battery Percentage")
        #expect(StatusBarDisplayOption.rangeKm.rawValue == "Range (km)")
        #expect(StatusBarDisplayOption.rangeMiles.rawValue == "Range (miles)")
        #expect(StatusBarDisplayOption.chargeTime.rawValue == "Charge Time")
    }
    
    @Test func testUserDefaultsKey() {
        let option = StatusBarDisplayOption.batteryPercentage
        #expect(option.userDefaultsKey == "statusbar_display_option")
        
        let option2 = StatusBarDisplayOption.rangeKm
        #expect(option2.userDefaultsKey == "statusbar_display_option")
    }
}

// MARK: - PolestarAPIError Tests

struct PolestarAPIErrorTests {
    
    @Test func testErrorDescriptions() {
        let notImplementedError = PolestarAPIError.notImplemented("Test feature")
        #expect(notImplementedError.errorDescription == "Not implemented: Test feature")
        
        let httpError = PolestarAPIError.httpError("Network failed")
        #expect(httpError.errorDescription == "HTTP Error: Network failed")
        
        let parseError = PolestarAPIError.parseError("Invalid JSON")
        #expect(parseError.errorDescription == "Parse Error: Invalid JSON")
        
        let authError = PolestarAPIError.authenticationFailed
        #expect(authError.errorDescription == "Authentication failed")
    }
}

// MARK: - Data Extension Tests

struct DataExtensionTests {
    
    @Test func testBase64URLEncoding() {
        let testData = "Hello, World!".data(using: .utf8)!
        let base64URL = testData.base64URLEncodedString()
        
        // Should not contain +, /, or = characters
        #expect(!base64URL.contains("+"))
        #expect(!base64URL.contains("/"))
        #expect(!base64URL.contains("="))
        
        // Should contain - and _ instead
        let normalBase64 = testData.base64EncodedString()
        let expectedBase64URL = normalBase64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        #expect(base64URL == expectedBase64URL)
    }
    
    @Test func testBase64URLEncodingEmptyData() {
        let emptyData = Data()
        let base64URL = emptyData.base64URLEncodedString()
        #expect(base64URL.isEmpty)
    }
}

// MARK: - OidcConfiguration Tests

struct OidcConfigurationTests {
    
    @Test func testOidcConfigurationInitialization() {
        let config = OidcConfiguration(
            issuer: "https://polestarid.eu.polestar.com",
            tokenEndpoint: "https://polestarid.eu.polestar.com/as/token.oauth2",
            authorizationEndpoint: "https://polestarid.eu.polestar.com/as/authorization.oauth2"
        )
        
        #expect(config.issuer == "https://polestarid.eu.polestar.com")
        #expect(config.tokenEndpoint == "https://polestarid.eu.polestar.com/as/token.oauth2")
        #expect(config.authorizationEndpoint == "https://polestarid.eu.polestar.com/as/authorization.oauth2")
    }
}
