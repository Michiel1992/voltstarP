# Privacy Policy for Voltstar

**Last updated: July 28, 2025**

## Overview

Voltstar ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use the Voltstar application for macOS.

## Information We Collect

### Personal Information
- **Polestar Account Credentials**: Your email address and password for your Polestar account
- **Vehicle Information**: Your vehicle's VIN (Vehicle Identification Number)
- **App Preferences**: Your display preferences and settings within the app

### Vehicle Data
Through Polestar's official API, we access:
- Battery percentage and charging status
- Vehicle range (kilometers and miles)
- Estimated charging time
- Vehicle image and model information
- Location data (if provided by Polestar's API)

## How We Use Your Information

### Authentication
- Your Polestar credentials are used solely to authenticate with Polestar's official API
- We use OAuth2 with PKCE (Proof Key for Code Exchange) for secure authentication
- Your credentials are stored locally on your device using macOS UserDefaults

### Vehicle Monitoring
- Vehicle data is retrieved to display real-time information in the app
- Data is refreshed automatically every 5 minutes while the app is running
- Information is used only to provide the core functionality of the app

## How We Store Your Information

### Local Storage
- All credentials and preferences are stored locally on your Mac using macOS UserDefaults
- No personal information is transmitted to our servers
- No data is stored in the cloud or on external services

### Security Measures
- OAuth2 with PKCE prevents credential interception
- All API communications use HTTPS encryption
- Credentials are stored using macOS's secure storage mechanisms

## Information Sharing

**We do not share, sell, or transmit your personal information to any third parties.**

- Your data stays on your device and between your device and Polestar's official API
- We have no servers that store your personal information
- We do not use analytics services that collect personal data
- We do not use advertising networks

## Third-Party Services

### Polestar API
- The app connects directly to Polestar's official API endpoints
- Your data is subject to Polestar's privacy policy when transmitted to their servers
- We recommend reviewing Polestar's privacy policy at: https://www.polestar.com/privacy-policy

## Data Retention

- Credentials and preferences are stored on your device until you manually delete them or uninstall the app
- Vehicle data is not permanently stored - it's refreshed with each API call
- You can clear all stored data by uninstalling the app

## Your Rights

### Access and Control
- You can view and modify your stored credentials through the app's Settings
- You can delete your data by clearing the app's settings or uninstalling the app
- You maintain full control over what information is stored

### Data Portability
- Your preferences are stored in standard macOS UserDefaults format
- Credentials can be exported or transferred if needed

## Children's Privacy

Voltstar is not intended for use by children under 13 years of age. We do not knowingly collect personal information from children under 13.

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. We will notify users of any material changes by:
- Updating the "Last updated" date at the top of this policy
- Providing notice through the app if significant changes are made

## Technical Details

### OAuth2 Implementation
- We use the OAuth2 authorization code flow with PKCE
- No client secrets are stored in the app
- Authorization codes are exchanged for access tokens securely

### API Endpoints
- Authentication: `polestarid.eu.polestar.com`
- Vehicle Data: `pc-api.polestar.com/eu-north-1/Voltstar-v2/`

## Contact Information

If you have any questions about this Privacy Policy or our privacy practices, please contact us at:

**Email**: [Your contact email]
**GitHub**: https://github.com/[your-username]/Voltstar

## Disclaimer

Voltstar is not affiliated with Polestar. This application is an independent project that uses Polestar's publicly available API. Use of the Polestar API is subject to Polestar's terms of service and privacy policy.

## Consent

By using Voltstar, you consent to the collection and use of information as described in this Privacy Policy.
