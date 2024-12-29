# RDVerify iOS

Identity verification app for iOS that supports proxy configuration and web-based verification flow.

## Building the App

This project can be built using Codemagic CI/CD. Follow these steps:

1. Fork this repository to your GitHub account
2. Go to [Codemagic](https://codemagic.io/)
3. Sign up with your GitHub account
4. Add this repository as a new application
5. Use the existing `codemagic.yaml` configuration
6. Start your first build

## Features

- Custom URL scheme handling (rdverify://)
- Proxy support with authentication
- WebView-based verification flow
- Camera permission handling
- Base64 configuration decoding

## URL Scheme Format

The app accepts URLs in the following format:
```
rdverify://[base64-encoded-config]
```

The base64-encoded config should contain:
```json
{
  "proxy": {
    "login": "username",
    "password": "password",
    "host": "proxy.example.com",
    "port": 8080
  },
  "idenfyLink": "https://verification-url.com"
}
```
