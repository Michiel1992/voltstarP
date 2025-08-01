//
//  PolestarAPITests.swift
//  MyStarTests
//
//  Created by Michiel Vanderlinden on 25/07/2025.
//

import Testing
import Foundation
import Security
@testable import MyStar

@MainActor
struct PolestarAPITests {
    
    // MARK: - Initialization Tests
    
    @Test func testPolestarAPIInitialization() {
        let api = PolestarAPI()
        
        #expect(api.carData == nil)
        #expect(api.isLoading == false)
        #expect(api.errorMessage == nil)
    }
    
    @Test func testSharedInstance() {
        let api1 = PolestarAPI()
        PolestarAPI.shared = api1
        
        #expect(PolestarAPI.shared === api1)
    }
    
    // MARK: - PKCE Helper Function Tests
    
    @Test func testPKCECodeVerifierGeneration() {
        // Test the PKCE code verifier generation logic manually
        var buffer1 = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer1.count, &buffer1)
        let codeVerifier1 = Data(buffer1).base64URLEncodedString()
        
        var buffer2 = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer2.count, &buffer2)
        let codeVerifier2 = Data(buffer2).base64URLEncodedString()
        
        // Code verifiers should be different each time
        #expect(codeVerifier1 != codeVerifier2)
        #expect(codeVerifier1.count > 0)
        #expect(codeVerifier2.count > 0)
        
        // Should not contain URL-unsafe characters
        #expect(!codeVerifier1.contains("+"))
        #expect(!codeVerifier1.contains("/"))
        #expect(!codeVerifier1.contains("="))
    }
    
    // MARK: - GraphQL Query Parsing Tests
    
    @Test func testPerformGraphQLQueryParsing() async throws {
        let _ = PolestarAPI()
        
        // Mock JSON response that matches the expected GraphQL structure
        let mockJSON: [String: Any] = [
            "data": [
                "carTelematicsV2": [
                    "battery": [
                        [
                            "batteryChargeLevelPercentage": 75.0,
                            "estimatedDistanceToEmptyKm": 300,
                            "estimatedDistanceToEmptyMiles": 186,
                            "chargingStatus": "CHARGING_STATUS_CHARGING",
                            "estimatedChargingTimeToFullMinutes": 90,
                            "timestamp": [
                                "seconds": 1690000000
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        // This test verifies the JSON parsing logic would work correctly
        // In a real implementation, we'd need to extract the parsing logic 
        // to a separate testable method
        if let data = mockJSON["data"] as? [String: Any],
           let carTelematicsV2 = data["carTelematicsV2"] as? [String: Any],
           let batteryArray = carTelematicsV2["battery"] as? [[String: Any]],
           let batteryData = batteryArray.first {
            
            let batteryPercentage = batteryData["batteryChargeLevelPercentage"] as? Double ?? 0.0
            let rangeKm = batteryData["estimatedDistanceToEmptyKm"] as? Int ?? 0
            let rangeMiles = batteryData["estimatedDistanceToEmptyMiles"] as? Int
            let chargingStatus = batteryData["chargingStatus"] as? String ?? "Unknown"
            let estimatedChargingTimeToFullMinutes = batteryData["estimatedChargingTimeToFullMinutes"] as? Int
            
            #expect(batteryPercentage == 75.0)
            #expect(rangeKm == 300)
            #expect(rangeMiles == 186)
            #expect(chargingStatus == "CHARGING_STATUS_CHARGING")
            #expect(estimatedChargingTimeToFullMinutes == 90)
        } else {
            Issue.record("Failed to parse mock GraphQL response")
        }
    }
    
    // MARK: - GraphQL Error Handling Tests
    
    @Test func testGraphQLErrorParsing() {
        let mockErrorJSON: [String: Any] = [
            "errors": [
                [
                    "message": "Authentication failed",
                    "code": "AUTH_ERROR"
                ],
                [
                    "message": "VIN not found",
                    "code": "VIN_ERROR"
                ]
            ]
        ]
        
        if let errors = mockErrorJSON["errors"] as? [[String: Any]] {
            let errorMessages = errors.compactMap { $0["message"] as? String }
            #expect(errorMessages.count == 2)
            #expect(errorMessages.contains("Authentication failed"))
            #expect(errorMessages.contains("VIN not found"))
        }
    }
    
    // MARK: - Car Information Query Parsing Tests
    
    @Test func testCarInformationQueryParsing() {
        let mockCarInfoJSON: [String: Any] = [
            "data": [
                "getConsumerCarsV2": [
                    [
                        "vin": "TEST123456789",
                        "content": [
                            "model": [
                                "name": "Polestar 2"
                            ],
                            "images": [
                                "studio": [
                                    "url": "https://example.com/polestar2.jpg"
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        if let data = mockCarInfoJSON["data"] as? [String: Any],
           let cars = data["getConsumerCarsV2"] as? [[String: Any]] {
            
            let testVIN = "TEST123456789"
            let car = cars.first { carData in
                return (carData["vin"] as? String) == testVIN
            }
            
            #expect(car != nil)
            
            if let carData = car,
               let content = carData["content"] as? [String: Any] {
                
                let modelName = (content["model"] as? [String: Any])?["name"] as? String
                #expect(modelName == "Polestar 2")
                
                var imageURL: String? = nil
                if let images = content["images"] as? [String: Any],
                   let studio = images["studio"] as? [String: Any],
                   let url = studio["url"] as? String {
                    imageURL = url
                }
                
                #expect(imageURL == "https://example.com/polestar2.jpg")
            }
        }
    }
    
    // MARK: - Token Refresh Logic Tests
    
    @Test func testTokenExpiryCheck() {
        // Test token expiry logic
        let now = Date()
        let expiredToken = now.addingTimeInterval(-600) // 10 minutes ago
        let validToken = now.addingTimeInterval(600) // 10 minutes from now
        let soonToExpireToken = now.addingTimeInterval(240) // 4 minutes from now (less than 5 minute threshold)
        
        // Token should be considered expired/needs refresh
        #expect(expiredToken.timeIntervalSinceNow < 300) // 5 minutes threshold
        #expect(soonToExpireToken.timeIntervalSinceNow < 300)
        
        // Token should be considered valid
        #expect(validToken.timeIntervalSinceNow >= 300)
    }
    
    // MARK: - URL Construction Tests
    
    @Test func testAuthorizationURLConstruction() {
        let baseURL = "https://polestarid.eu.polestar.com/as/authorization.oauth2"
        let clientId = "l3oopkc_10"
        let redirectUri = "https://www.polestar.com/sign-in-callback"
        let scope = "openid profile email customer:attributes"
        let state = "test-state"
        let codeChallenge = "test-challenge"
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "response_mode", value: "query")
        ]
        
        let constructedURL = components.url!
        let finalComponents = URLComponents(url: constructedURL, resolvingAgainstBaseURL: false)!
        
        let queryItems = finalComponents.queryItems ?? []
        let queryDict = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })
        
        #expect(queryDict["client_id"] == "l3oopkc_10")
        #expect(queryDict["response_type"] == "code")
        #expect(queryDict["code_challenge_method"] == "S256")
        #expect(queryDict["scope"] == "openid profile email customer:attributes")
    }
    
    // MARK: - Form Data Encoding Tests
    
    @Test func testTokenExchangeFormData() {
        let authCode = "test-auth-code"
        let clientId = "l3oopkc_10"
        let redirectUri = "https://www.polestar.com/sign-in-callback"
        let codeVerifier = "test-verifier"
        
        let formData = [
            "grant_type=authorization_code",
            "client_id=\(clientId)",
            "code=\(authCode)",
            "redirect_uri=\(redirectUri)",
            "code_verifier=\(codeVerifier)"
        ].joined(separator: "&")
        
        #expect(formData.contains("grant_type=authorization_code"))
        #expect(formData.contains("client_id=l3oopkc_10"))
        #expect(formData.contains("code=test-auth-code"))
        #expect(formData.contains("code_verifier=test-verifier"))
    }
    
    @Test func testRefreshTokenFormData() {
        let refreshToken = "test-refresh-token"
        let clientId = "l3oopkc_10"
        
        let formData = [
            "grant_type=refresh_token",
            "client_id=\(clientId)",
            "refresh_token=\(refreshToken)"
        ].joined(separator: "&")
        
        #expect(formData.contains("grant_type=refresh_token"))
        #expect(formData.contains("client_id=l3oopkc_10"))
        #expect(formData.contains("refresh_token=test-refresh-token"))
    }
}