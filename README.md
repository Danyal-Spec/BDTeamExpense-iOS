# BD Team Expense — iOS

iPhone version of the group expense app. Same screens and same Google Sheet server as the Android app:
everyone has an account, everyone sees all expenses and balances, and a member's entry is added to the
sheet only after the admin approves it.

This repository contains **source code only**. Nothing is built automatically.

## Server

The server (Google Apps Script attached to the expense sheet) and its setup steps are in the Android
repository: `BDTeamExpense-APK/apps-script` and its README. Both apps use the same server link.

## Connect the app to the sheet

Put the server link into `BDTeamExpense/config.json`:

```json
{ "apiUrl": "https://script.google.com/macros/s/…/exec" }
```

If it is left empty, the app asks for the link on first start.

## Build (when needed)

On a Mac with Xcode 15 or newer:

```sh
brew install xcodegen
xcodegen generate
open BDTeamExpense.xcodeproj
```

Choose your team under *Signing & Capabilities*, then run on a phone.

Without a Mac: the **Actions** tab has a workflow called *Build iOS (manual)*. It runs only when started by
hand and produces an unsigned `.ipa` (for AltStore / Sideloadly, or to sign with a developer account).

## Use it on iPhone today, without building

If the optional `Index` HTML file was added to the Apps Script project, the server link itself opens the
app in Safari. **Share → Add to Home Screen** gives it an icon like a normal app.

## What is inside

| Path | What |
| --- | --- |
| `BDTeamExpense/www/index.html` | All app screens (identical to the Android project) |
| `BDTeamExpense/WebScreen.swift` | Shows the screens |
| `BDTeamExpense/Bridge.swift` | Sends requests to the sheet server, share sheet |
| `BDTeamExpense/config.json` | Server link |
| `project.yml` | Xcode project definition (XcodeGen) |
