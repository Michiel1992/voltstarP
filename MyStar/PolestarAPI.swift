//
//  PolestarAPI.swift
//  MyStar
//
//  Created by Michiel Vanderlinden on 25/07/2025.
//

import Foundation
import CryptoKit

struct PolestarCarData {
    let batteryPercentage: Double
    let rangeKm: Int
    let rangeMiles: Int?
    let chargingStatus: String
    let chargingPowerWatts: Int?
    let estimatedChargingTimeToFullMinutes: Int?
    let imageURL: String?
    let modelName: String?
    let lastUpdated: Date
}

struct OidcConfiguration {
    let issuer: String
    let tokenEndpoint: String
    let authorizationEndpoint: String
}

class PolestarAPI: ObservableObject {
    static var shared: PolestarAPI?
    
    @Published var carData: PolestarCarData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var carImageURL: String?
    private var carModelName: String?
    
    private let apiBaseURL = "https://pc-api.polestar.com/eu-north-1/mystar-v2/"
    private let oidcProviderURL = "https://polestarid.eu.polestar.com"
    private let oidcClientId = "l3oopkc_10"
    private let oidcRedirectUri = "https://www.polestar.com/sign-in-callback"
    private let oidcScope = "openid profile email customer:attributes"
    
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date?
    private var refreshTimer: Timer?
    private var currentVin: String?
    
    private var oidcConfiguration: OidcConfiguration?
    private var codeVerifier: String?
    private var state: String?
    private var urlSession: URLSession?
    
    @MainActor
    func authenticate(email: String, password: String, vin: String) async {
        self.currentVin = vin
        
        // Create URLSession with cookie storage
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        self.urlSession = URLSession(configuration: config)
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            print("🔵 Starting authentication for email: \(email)")
            
            // Step 1: Get OIDC configuration
            print("🔵 Step 1: Getting OIDC configuration...")
            try await updateOidcConfiguration()
            print("✅ OIDC configuration retrieved")
            
            // Step 2: Get authorization code through login flow
            print("🔵 Step 2: Getting authorization code...")
            let authCode = try await getAuthorizationCode(email: email, password: password)
            print("✅ Authorization code received: \(String(authCode.prefix(10)))...")
            
            // Step 3: Exchange code for access token
            print("🔵 Step 3: Exchanging code for token...")
            try await exchangeCodeForToken(authCode: authCode)
            print("✅ Access token received")
            
            // Step 4: Fetch car information (image, model)
            print("🔵 Step 4: Fetching car information for VIN: \(vin)")
            await fetchCarInformation(vin: vin)
            
            // Step 5: Fetch car telematics data
            print("🔵 Step 5: Fetching car data for VIN: \(vin)")
            await fetchCarData(vin: vin)
            
            // Step 6: Start periodic refresh
            print("🔵 Step 6: Starting periodic refresh")
            startPeriodicRefresh()
            
        } catch {
            print("❌ Authentication failed: \(error)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    private func updateOidcConfiguration() async throws {
        let configURL = URL(string: "\(oidcProviderURL)/.well-known/openid-configuration")!
        let (data, response) = try await URLSession.shared.data(from: configURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PolestarAPIError.httpError("Failed to get OIDC configuration")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let issuer = json["issuer"] as? String,
              let tokenEndpoint = json["token_endpoint"] as? String,
              let authEndpoint = json["authorization_endpoint"] as? String else {
            throw PolestarAPIError.parseError("Invalid OIDC configuration")
        }
        
        self.oidcConfiguration = OidcConfiguration(
            issuer: issuer,
            tokenEndpoint: tokenEndpoint,
            authorizationEndpoint: authEndpoint
        )
    }
    
    private func getAuthorizationCode(email: String, password: String) async throws -> String {
        guard let config = oidcConfiguration else {
            throw PolestarAPIError.authenticationFailed
        }
        
        // Step 1: Generate PKCE parameters
        self.codeVerifier = generateCodeVerifier()
        self.state = generateState()
        let codeChallenge = generateCodeChallenge(verifier: codeVerifier!)
        
        // Step 2: Try authorization endpoint directly (might redirect to callback with code)
        let authCode = try await attemptDirectAuthorization(config: config, codeChallenge: codeChallenge, email: email, password: password)
        
        return authCode
    }
    
    private func attemptDirectAuthorization(config: OidcConfiguration, codeChallenge: String, email: String, password: String) async throws -> String {
        var components = URLComponents(string: config.authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: oidcClientId),
            URLQueryItem(name: "redirect_uri", value: oidcRedirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: oidcScope),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "response_mode", value: "query")
        ]
        
        print("🔵 Attempting direct authorization from: \(components.url!)")
        
        var request = URLRequest(url: components.url!)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await urlSession!.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PolestarAPIError.httpError("Invalid response type")
        }
        
        print("🔵 Authorization response status: \(httpResponse.statusCode)")
        print("🔵 Response URL: \(httpResponse.url?.absoluteString ?? "none")")
        
        // Check if we already got redirected to callback URL with code
        if let url = httpResponse.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
           let code = codeItem.value {
            print("✅ Found authorization code in callback URL: \(String(code.prefix(10)))...")
            return code
        }
        
        // If we don't have a code yet, we need to parse the response for a resume path and login
        //let html = String(data: data, encoding: .utf8) ?? ""
        
        // Try to find resume path for login
        if let resumePath = try? await parseResumePathFromHTML(data: data, response: response) {
            print("🔵 Found resume path, attempting login: \(resumePath)")
            return try await performLogin(resumePath: resumePath, email: email, password: password)
        }
        
        throw PolestarAPIError.parseError("Could not get authorization code from response")
    }
    
    private func exchangeCodeForToken(authCode: String) async throws {
        guard let config = oidcConfiguration,
              let codeVerifier = codeVerifier else {
            throw PolestarAPIError.authenticationFailed
        }
        
        var request = URLRequest(url: URL(string: config.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let formData = [
            "grant_type=authorization_code",
            "client_id=\(oidcClientId)",
            "code=\(authCode)",
            "redirect_uri=\(oidcRedirectUri)",
            "code_verifier=\(codeVerifier)"
        ].joined(separator: "&")
        
        request.httpBody = formData.data(using: .utf8)
        
        let (data, response) = try await urlSession!.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PolestarAPIError.httpError("Token exchange failed")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PolestarAPIError.parseError("Invalid token response")
        }
        
        if let error = json["error"] as? String {
            throw PolestarAPIError.httpError("Token error: \(error)")
        }
        
        guard let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String,
              let expiresIn = json["expires_in"] as? Int else {
            throw PolestarAPIError.parseError("Missing token data")
        }
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn))
    }
    
    @MainActor
    func fetchCarData(vin: String) async {
        // Check if token needs refresh
        if let expiry = tokenExpiry, expiry.timeIntervalSinceNow < 300 { // 5 minutes
            do {
                try await refreshAccessToken()
            } catch {
                self.errorMessage = "Token refresh failed: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
        }
        
        guard let token = accessToken else {
            self.errorMessage = "Not authenticated"
            self.isLoading = false
            return
        }
        
        do {
            let data = try await performGraphQLQuery(vin: vin, token: token)
            
            self.carData = data
            self.isLoading = false
            
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    private func refreshAccessToken() async throws {
        guard let config = oidcConfiguration,
              let refreshToken = refreshToken else {
            throw PolestarAPIError.authenticationFailed
        }
        
        var request = URLRequest(url: URL(string: config.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let formData = [
            "grant_type=refresh_token",
            "client_id=\(oidcClientId)",
            "refresh_token=\(refreshToken)"
        ].joined(separator: "&")
        
        request.httpBody = formData.data(using: .utf8)
        
        let (data, response) = try await urlSession!.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PolestarAPIError.httpError("Token refresh failed")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PolestarAPIError.parseError("Invalid refresh response")
        }
        
        if let error = json["error"] as? String {
            throw PolestarAPIError.httpError("Refresh error: \(error)")
        }
        
        guard let accessToken = json["access_token"] as? String,
              let expiresIn = json["expires_in"] as? Int else {
            throw PolestarAPIError.parseError("Missing refresh token data")
        }
        
        self.accessToken = accessToken
        if let newRefreshToken = json["refresh_token"] as? String {
            self.refreshToken = newRefreshToken
        }
        self.tokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn))
    }
    
    func fetchCarInformation(vin: String) async {
        guard let token = accessToken else {
            print("❌ No access token for car information")
            return
        }
        
        do {
            let (imageURL, modelName) = try await performCarInformationQuery(vin: vin, token: token)
            self.carImageURL = imageURL
            self.carModelName = modelName
            print("✅ Car information retrieved - Model: \(modelName ?? "Unknown"), Image: \(imageURL != nil ? "Yes" : "No")")
        } catch {
            print("❌ Failed to fetch car information: \(error)")
        }
    }
    
    private func performGraphQLQuery(vin: String, token: String) async throws -> PolestarCarData {
        let query = """
        query CarTelematicsV2($vins: [String!]!) {
          carTelematicsV2(vins: $vins) {
            battery {
              vin
              batteryChargeLevelPercentage
              estimatedDistanceToEmptyKm
              estimatedDistanceToEmptyMiles
              chargingStatus
              estimatedChargingTimeToFullMinutes
              timestamp {
                seconds
              }
            }
          }
        }
        """
        
        let requestBody = ["query": query, "variables": ["vins": [vin]]] as [String : Any]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔵 Making GraphQL request to: \(apiBaseURL)")
        print("🔵 VIN: \(vin)")
        print("🔵 Token: \(String(token.prefix(20)))...")
        
        var request = URLRequest(url: URL(string: apiBaseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let (data, response) = try await urlSession!.data(for: request)
        
        print("🔵 GraphQL Response status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 GraphQL Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw PolestarAPIError.httpError("Failed to fetch data. Status: \(statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PolestarAPIError.parseError("Invalid JSON response")
        }
        
        // Check for GraphQL errors
        if let errors = json["errors"] as? [[String: Any]] {
            let errorMessages = errors.compactMap { $0["message"] as? String }
            throw PolestarAPIError.httpError("GraphQL errors: \(errorMessages.joined(separator: ", "))")
        }
        
        // Parse the GraphQL response
        guard let data = json["data"] as? [String: Any],
              let carTelematicsV2 = data["carTelematicsV2"] as? [String: Any],
              let batteryArray = carTelematicsV2["battery"] as? [[String: Any]],
              let batteryData = batteryArray.first else {
            throw PolestarAPIError.parseError("Invalid response format. Data structure: \(json)")
        }
        
        let batteryPercentage = batteryData["batteryChargeLevelPercentage"] as? Double ?? 0.0
        let rangeKm = batteryData["estimatedDistanceToEmptyKm"] as? Int ?? 0
        let rangeMiles = batteryData["estimatedDistanceToEmptyMiles"] as? Int
        let chargingStatus = batteryData["chargingStatus"] as? String ?? "Unknown"
        let estimatedChargingTimeToFullMinutes = batteryData["estimatedChargingTimeToFullMinutes"] as? Int
        
        print("✅ Parsed data - Battery: \(batteryPercentage)%, Range: \(rangeKm)km/\(rangeMiles ?? 0)miles, Status: \(chargingStatus), Time: \(estimatedChargingTimeToFullMinutes ?? 0)min")
        
        return PolestarCarData(
            batteryPercentage: batteryPercentage,
            rangeKm: rangeKm,
            rangeMiles: rangeMiles,
            chargingStatus: chargingStatus,
            chargingPowerWatts: nil, // Not available in carTelematicsV2
            estimatedChargingTimeToFullMinutes: estimatedChargingTimeToFullMinutes,
            imageURL: carImageURL,
            modelName: carModelName,
            lastUpdated: Date()
        )
    }
    
    private func performCarInformationQuery(vin: String, token: String) async throws -> (String?, String?) {
        let query = """
        query GetConsumerCarsV2 {
          getConsumerCarsV2 {
            vin
            content {
              model { name }
              images {
                studio { url }
              }
            }
          }
        }
        """
        
        let requestBody = ["query": query] as [String : Any]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔵 Making car information GraphQL request")
        
        var request = URLRequest(url: URL(string: apiBaseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw PolestarAPIError.httpError("Failed to fetch car information. Status: \(statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PolestarAPIError.parseError("Invalid JSON response for car information")
        }
        
        // Check for GraphQL errors
        if let errors = json["errors"] as? [[String: Any]] {
            let errorMessages = errors.compactMap { $0["message"] as? String }
            throw PolestarAPIError.httpError("GraphQL errors in car info: \(errorMessages.joined(separator: ", "))")
        }
        
        // Parse the car information response
        guard let data = json["data"] as? [String: Any],
              let cars = data["getConsumerCarsV2"] as? [[String: Any]] else {
            throw PolestarAPIError.parseError("Invalid car information response format")
        }
        
        // Find the car with matching VIN
        let car = cars.first { carData in
            return (carData["vin"] as? String) == vin
        }
        
        guard let carData = car,
              let content = carData["content"] as? [String: Any] else {
            return (nil, nil) // No car found with this VIN
        }
        
        // Extract model name
        let modelName = (content["model"] as? [String: Any])?["name"] as? String
        
        // Extract image URL
        var imageURL: String? = nil
        if let images = content["images"] as? [String: Any],
           let studio = images["studio"] as? [String: Any],
           let url = studio["url"] as? String {
            imageURL = url
        }
        
        return (imageURL, modelName)
    }
    
    private func startPeriodicRefresh() {
        self.refreshTimer?.invalidate()
        self.refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            if let vin = self.currentVin {
                Task { @MainActor in
                    await self.fetchCarData(vin: vin)
                }
            }
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - PKCE Helper Functions
    
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncodedString()
    }
    
    private func generateState() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncodedString()
    }
    
    private func generateCodeChallenge(verifier: String) -> String {
        let data = verifier.data(using: .utf8)!
        let digest = SHA256.hash(data: data)
        return Data(digest).base64URLEncodedString()
    }
    
    
    private func parseResumePathFromHTML(data: Data, response: URLResponse) async throws -> String {
        let html = String(data: data, encoding: .utf8) ?? ""
        print("🔵 HTML Response length: \(html.count)")
        print("🔵 HTML snippet: \(String(html.prefix(1000)))")
        
        // Check if this is actually a login form or if we got redirected to main site
        if html.contains("www.polestar.com") && !html.contains("authorization") && !html.contains("login") {
            print("❌ Got redirected to main Polestar website instead of login form")
            // This might mean we need to try a different approach or the OAuth endpoint changed
            throw PolestarAPIError.authenticationFailed
        }
        
        // Look for JavaScript variables or configurations
        if html.contains("resumePath") || html.contains("pf.") {
            let jsPattern = #"(?:resumePath|pf\.resumePath)\s*[:=]\s*['""]([^'""]+)['""]"#
            if let regex = try? NSRegularExpression(pattern: jsPattern, options: []),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let resumePath = String(html[range])
                print("✅ Found resume path in JavaScript: \(resumePath)")
                return resumePath
            }
        }
        
        // Try multiple patterns to extract resume path
        let patterns = [
            #"(?:url|action):\s*"([^"]+)""#,
            #"action="([^"]+)""#,
            #"action:\s*'([^']+)'"#,
            #"url:\s*"([^"]+)""#,
            #"url:\s*'([^']+)'"#,
            #"/as/([^"'\s]+)""#,
            #"pf\.resumePath\s*=\s*['""]([^'""]+)['""]"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let resumePath = String(html[range])
                print("✅ Found resume path with pattern \(pattern): \(resumePath)")
                return resumePath
            }
        }
        
        // If no pattern works, try to find any path that looks like a resume path
        if let regex = try? NSRegularExpression(pattern: #"/as/[a-zA-Z0-9\-_/]+"#, options: []),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range, in: html) {
            let resumePath = String(html[range])
            print("✅ Found resume path with fallback pattern: \(resumePath)")
            return resumePath
        }
        
        // Last resort: look for form action
        if html.contains("<form") {
            if let regex = try? NSRegularExpression(pattern: #"<form[^>]+action=['""]([^'""]+)['""]"#, options: []),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let resumePath = String(html[range])
                print("✅ Found resume path in form action: \(resumePath)")
                return resumePath
            }
        }
        
        print("❌ Could not find resume path in HTML")
        print("❌ This suggests the OAuth endpoint may have changed or requires different handling")
        throw PolestarAPIError.parseError("Could not extract resume path from HTML response - may need to update OAuth flow")
    }
    
    private func performLogin(resumePath: String, email: String, password: String) async throws -> String {
        let loginURL = URL(string: "\(oidcProviderURL)\(resumePath)")!
        
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let formData = "pf.username=\(email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email)&pf.pass=\(password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? password)"
        request.httpBody = formData.data(using: .utf8)
        
        let (data, response) = try await urlSession!.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PolestarAPIError.httpError("Invalid response")
        }
        
        // Check for redirect (302/303) which contains the authorization code
        if httpResponse.statusCode == 302 || httpResponse.statusCode == 303 {
            if let location = httpResponse.value(forHTTPHeaderField: "Location"),
               let url = URL(string: location),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
               let code = codeItem.value {
                return code
            }
        }
        
        // Check for authentication errors
        let html = String(data: data, encoding: .utf8) ?? ""
        if html.contains("ERR001") {
            throw PolestarAPIError.authenticationFailed
        }
        
        throw PolestarAPIError.httpError("Authentication failed")
    }
}

extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

enum PolestarAPIError: Error, LocalizedError {
    case notImplemented(String)
    case httpError(String)
    case parseError(String)
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .notImplemented(let message):
            return "Not implemented: \(message)"
        case .httpError(let message):
            return "HTTP Error: \(message)"
        case .parseError(let message):
            return "Parse Error: \(message)"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}
