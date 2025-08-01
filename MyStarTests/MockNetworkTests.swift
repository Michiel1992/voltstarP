//
//  MockNetworkTests.swift
//  MyStarTests
//
//  Created by Michiel Vanderlinden on 25/07/2025.
//

import Testing
import Foundation
@testable import MyStar

struct MockNetworkTests {
    
    // MARK: - Mock JSON Response Tests
    
    @Test func testMockOIDCConfigurationResponse() {
        let mockJSON = """
        {
            "issuer": "https://polestarid.eu.polestar.com",
            "authorization_endpoint": "https://polestarid.eu.polestar.com/as/authorization.oauth2",
            "token_endpoint": "https://polestarid.eu.polestar.com/as/token.oauth2",
            "userinfo_endpoint": "https://polestarid.eu.polestar.com/as/userinfo.oauth2",
            "jwks_uri": "https://polestarid.eu.polestar.com/ext/oauth/jwks"
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            let issuer = json?["issuer"] as? String
            let tokenEndpoint = json?["token_endpoint"] as? String
            let authEndpoint = json?["authorization_endpoint"] as? String
            
            #expect(issuer == "https://polestarid.eu.polestar.com")
            #expect(tokenEndpoint == "https://polestarid.eu.polestar.com/as/token.oauth2")
            #expect(authEndpoint == "https://polestarid.eu.polestar.com/as/authorization.oauth2")
            
        } catch {
            Issue.record("Failed to parse mock OIDC configuration: \(error)")
        }
    }
    
    @Test func testMockTokenResponse() {
        let mockJSON = """
        {
            "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
            "refresh_token": "def502004a8b7c0a1...",
            "token_type": "Bearer",
            "expires_in": 3600,
            "scope": "openid profile email customer:attributes"
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            let accessToken = json?["access_token"] as? String
            let refreshToken = json?["refresh_token"] as? String
            let expiresIn = json?["expires_in"] as? Int
            let tokenType = json?["token_type"] as? String
            
            #expect(accessToken?.hasPrefix("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9") == true)
            #expect(refreshToken?.hasPrefix("def502004a8b7c0a1") == true)
            #expect(expiresIn == 3600)
            #expect(tokenType == "Bearer")
            
        } catch {
            Issue.record("Failed to parse mock token response: \(error)")
        }
    }
    
    @Test func testMockTokenErrorResponse() {
        let mockJSON = """
        {
            "error": "invalid_grant",
            "error_description": "The provided authorization grant is invalid, expired, revoked, does not match the redirection URI used in the authorization request, or was issued to another client."
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            let error = json?["error"] as? String
            let errorDescription = json?["error_description"] as? String
            
            #expect(error == "invalid_grant")
            #expect(errorDescription?.contains("authorization grant is invalid") == true)
            
        } catch {
            Issue.record("Failed to parse mock token error response: \(error)")
        }
    }
    
    @Test func testMockCarTelematicsResponse() {
        let mockJSON = """
        {
            "data": {
                "carTelematicsV2": {
                    "battery": [
                        {
                            "vin": "TEST123456789",
                            "batteryChargeLevelPercentage": 85,
                            "estimatedDistanceToEmptyKm": 320,
                            "estimatedDistanceToEmptyMiles": 199,
                            "chargingStatus": "CHARGING_STATUS_CHARGING",
                            "estimatedChargingTimeToFullMinutes": 45,
                            "timestamp": {
                                "seconds": 1690000000
                            }
                        }
                    ]
                }
            }
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let dataObj = json?["data"] as? [String: Any],
                  let carTelematicsV2 = dataObj["carTelematicsV2"] as? [String: Any],
                  let batteryArray = carTelematicsV2["battery"] as? [[String: Any]],
                  let batteryData = batteryArray.first else {
                Issue.record("Failed to parse mock car telematics structure")
                return
            }
            
            let vin = batteryData["vin"] as? String
            let batteryPercentage = batteryData["batteryChargeLevelPercentage"] as? Double
            let rangeKm = batteryData["estimatedDistanceToEmptyKm"] as? Int
            let rangeMiles = batteryData["estimatedDistanceToEmptyMiles"] as? Int
            let chargingStatus = batteryData["chargingStatus"] as? String
            let chargingTime = batteryData["estimatedChargingTimeToFullMinutes"] as? Int
            
            #expect(vin == "TEST123456789")
            #expect(batteryPercentage == 85.0)
            #expect(rangeKm == 320)
            #expect(rangeMiles == 199)
            #expect(chargingStatus == "CHARGING_STATUS_CHARGING")
            #expect(chargingTime == 45)
            
        } catch {
            Issue.record("Failed to parse mock car telematics response: \(error)")
        }
    }
    
    @Test func testMockCarInformationResponse() {
        let mockJSON = """
        {
            "data": {
                "getConsumerCarsV2": [
                    {
                        "vin": "TEST123456789",
                        "content": {
                            "model": {
                                "name": "Polestar 2"
                            },
                            "images": {
                                "studio": {
                                    "url": "https://www.polestar.com/dato/images/polestar-2.jpg"
                                }
                            }
                        }
                    }
                ]
            }
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let dataObj = json?["data"] as? [String: Any],
                  let cars = dataObj["getConsumerCarsV2"] as? [[String: Any]],
                  let car = cars.first,
                  let content = car["content"] as? [String: Any] else {
                Issue.record("Failed to parse mock car information structure")
                return
            }
            
            let vin = car["vin"] as? String
            let modelName = (content["model"] as? [String: Any])?["name"] as? String
            
            var imageURL: String? = nil
            if let images = content["images"] as? [String: Any],
               let studio = images["studio"] as? [String: Any],
               let url = studio["url"] as? String {
                imageURL = url
            }
            
            #expect(vin == "TEST123456789")
            #expect(modelName == "Polestar 2")
            #expect(imageURL == "https://www.polestar.com/dato/images/polestar-2.jpg")
            
        } catch {
            Issue.record("Failed to parse mock car information response: \(error)")
        }
    }
    
    @Test func testMockGraphQLErrorResponse() {
        let mockJSON = """
        {
            "errors": [
                {
                    "message": "Authentication failed",
                    "extensions": {
                        "code": "UNAUTHENTICATED",
                        "exception": {
                            "stacktrace": ["Error: Authentication failed"]
                        }
                    }
                },
                {
                    "message": "VIN not found",
                    "extensions": {
                        "code": "NOT_FOUND"
                    }
                }
            ],
            "data": null
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            let errors = json?["errors"] as? [[String: Any]]
            let dataObj = json?["data"] as? [String: Any]
            
            #expect(errors?.count == 2)
            #expect(dataObj == nil)
            
            let errorMessages = errors?.compactMap { $0["message"] as? String } ?? []
            #expect(errorMessages.contains("Authentication failed"))
            #expect(errorMessages.contains("VIN not found"))
            
        } catch {
            Issue.record("Failed to parse mock GraphQL error response: \(error)")
        }
    }
    
    // MARK: - URL Parsing Tests
    
    @Test func testCallbackURLParsing() {
        let callbackURL = "https://www.polestar.com/sign-in-callback?code=abc123def456&state=xyz789"
        
        guard let url = URL(string: callbackURL),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Issue.record("Failed to create URL components")
            return
        }
        
        let codeItem = components.queryItems?.first(where: { $0.name == "code" })
        let stateItem = components.queryItems?.first(where: { $0.name == "state" })
        
        #expect(codeItem?.value == "abc123def456")
        #expect(stateItem?.value == "xyz789")
    }
    
    @Test func testCallbackURLParsingMissingCode() {
        let callbackURL = "https://www.polestar.com/sign-in-callback?state=xyz789&error=access_denied"
        
        guard let url = URL(string: callbackURL),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Issue.record("Failed to create URL components")
            return
        }
        
        let codeItem = components.queryItems?.first(where: { $0.name == "code" })
        let errorItem = components.queryItems?.first(where: { $0.name == "error" })
        let stateItem = components.queryItems?.first(where: { $0.name == "state" })
        
        #expect(codeItem?.value == nil)
        #expect(errorItem?.value == "access_denied")
        #expect(stateItem?.value == "xyz789")
    }
}