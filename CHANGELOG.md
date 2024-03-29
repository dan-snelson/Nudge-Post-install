# CHANGELOG

## 0.0.17

### 03-Jan-2023
- Updates for Nudge [`1.1.10`](https://github.com/macadmins/nudge/pull/435)

## 0.0.16

### 21-Oct-2022
> :warning: **BREAKING CHANGE**
>  - Reordered Script Parameters
> - Added default Script Parameter values (for when Script Parameters are left blank in a Jamf Pro policy)
- Removed `authorizationCheck` function
- Added macOS Ventura settings
- Replaced `scriptResult` with `updateScriptLog`
- Random clean-up

## 0.0.15

### 08-Jun-2022
- Added an `Uninstall` option to the `resetConfiguration` function
- Removed verbosity when removing files
- Started macOS Ventura logic (using macOS Monterey's deadline)
## 0.0.14

### 03-Jun-2022
- Updates for Nudge 1.1.7.81411
    - `terminateApplicationsOnLaunch`
    - `customDeferralDropdownText`
## 0.0.13
### 25-May-2022
- Updates for Nudge 1.1.7.81388
    - `acceptableAssertionUsage`
    - `acceptableAssertionApplicationNames`
    - `acceptableCameraUsage`
    - `acceptableScreenSharingUsage`
    - `logReferralTime`
    - `attemptToBlockApplicationLaunches`
    - `blockedApplicationBundleIDs`
    - remove `logReferralTime`

## 0.0.12
### 16-May-2022
- Updates for Nudge 1.1.6.81354
    - Replaced tabs with spaces
    - Simplified Logging preamble

## 0.0.11
### 15-Mar-2022
- `allowGracePeriods`
- `gracePeriodInstallDelay`
- `gracePeriodLaunchDelay`
- `gracePeriodPath`

## 0.0.10
### 10-Feb-2022
- `disableSoftwareUpdateWorkflow`

## 0.0.9
### 21-Jan-2022
- `asynchronousSoftwareUpdate`

## 0.0.8
### 19-Oct-2021
- Enforce latest version on both macOS Monterey and macOS Big Sur

## 0.0.7
### 12-Oct-2021
- Added check for logged-in user before attempting to hide Nudge in Launchpad. (Thanks for the feedback and testing, @JOTAI)

## 0.0.6
### 25-Aug-2021
- Nudge 1.1.0 updates

## 0.0.5
### 12-Aug-2021
- Updates for macOS 11.5.2; formatting

## 0.0.4
### 27-May-2021
- Updated for macOS Big Sur 11.4
- Moved the "Hide Nudge in Finder & Launchpad" code into the "Reset > All" section
- Changed "userInterface" values to field names (to hopefully more easily identify in the UI)

## 0.0.3
### 06-May-2021
- Updated for macOS Big Sur 11.3.1
- Standardized StartCalendarInterval

## 0.0.2
### 23-Mar-2021
- Updated to defaults from https://github.com/macadmins/nudge/wiki/userExperience