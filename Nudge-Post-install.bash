#!/bin/bash

####################################################################################################
#
#   Nudge Post-install
#
#   Purpose: Configures Nudge to company standards post-install
#   https://github.com/dan-snelson/Nudge-Post-install/wiki
#
#   Original author:
#   Dan K. Snelson (@dan-snelson)
#   Nudge Updates:
#   see notes for version [`1.1.10`](https://github.com/macadmins/nudge/pull/435)
#
####################################################################################################

####################################################################################################
#
# Initial Variables Setup
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Jamf Parameter Labels
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## Reverse Domain Name Notation (i.e., "org.corp.app")
plistDomain="${4:-"org.corp.app"}"               

## Configuration Files to Reset (i.e., All | JSON | LaunchAgent | LaunchDaemon | none (blank))
resetConfiguration="${5:-"All"}"

## Required macOS Installation Date & Time (i.e., 2023-01-17T10:00:00Z) - use Z at the end for UTC time, otherwise local time will be used
requiredInstallationDate="${6:-"2025-12-31T23:23:23Z"}"

## Required TargetedOSVersionsRule
requiredTargetedOSVersionsRule="${7:-"14"}"
## See for reference:
## https://github.com/macadmins/nudge/wiki/osVersionRequirements#targetedosversionsrule---type-string-default-value--required-no
## https://github.com/macadmins/nudge/wiki/targetedOSVersionsRule

## Required AboutUpdateURL
requiredAboutUpdateURL="${8:-"aboutUpdateURL"}"
## See for reference:
## https://github.com/macadmins/nudge/wiki/osVersionRequirements#aboutupdateurl---type-string-default-value-none-required-no
## https://github.com/macadmins/nudge/wiki/aboutUpdateURLs

## Required MainContentText
requiredMainContentText="${9:-"mainContentText"}"
## See for reference:
## https://github.com/macadmins/nudge/wiki/updateElements#maincontenttext---type-string-default-value-

## Required SubHeader
requiredSubHeader="${10:-"subHeader"}"
## See for reference:
## https://github.com/macadmins/nudge/wiki/updateElements#subheader---type-string-default-value-

## Required ForceDownloadURL
requiredForceDownloadURL="${11:-"https://swcdn.apple.com/content/downloads/26/09/042-58988-A_114Q05ZS90/yudaal746aeavnzu5qdhk26uhlphm3r79u/InstallAssistant.pkg"}"
# 14.0 URL used above
## See for reference:
## https://mrmacintosh.com/macos-sonoma-full-installer-database-download-directly-from-apple/
## https://www.apple.com/newsroom/2023/09/macos-sonoma-is-available-today/

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Global Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="18.0.0"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

requiredMinimumOSInstallerFilename="Install macOS Sonoma.app"
requiredMinimumOSVersion="14.0"
requiredMinimumOSInstallerVersion="19.0.02"
shouldForceDownload=false

scriptLog="/var/log/${plistDomain}.NudgePostInstall.log"
jsonPath="/Library/Preferences/${plistDomain}.Nudge.json"
launchAgentPath="/Library/LaunchAgents/${plistDomain}.Nudge.plist"
launchDaemonPath="/Library/LaunchDaemons/${plistDomain}.Nudge.logger.plist"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; then
    echo "No user logged-in; exiting."
    exit #1
else
    loggedInUserID=$(id -u "${loggedInUser}")
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate force macOS download
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
if [[ "$requiredForceDownloadURL" != "" ]] ; then
    shouldForceDownload=true
fi

####################################################################################################
#
# Functions
#
####################################################################################################

function updateScriptLog() {
    # Client-side Script Logging
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

function runAsUser() {
    # Run command as logged-in user (thanks, @scriptingosx!)
    updateScriptLog "Run command \"$@\" as \"$loggedInUserID\" … "
    launchctl asuser "$loggedInUserID" sudo -u "$loggedInUser" "$@"

}

function killNudgeProcess(){
    # Make sure Nudge stops running (in case aggresive mode may be active, or whether deadline has passed)
    updateScriptLog "Stopping Nudge process..."
    pkill -l -U "${loggedInUser}" nudge
    updateScriptLog "Stopped Nudge process"

}

function forceDownloadLatestUpgrade(){
    updateScriptLog "Clearing InstallAssistant.pkg from any previous download attempts"
    if [[ -f "/tmp/InstallAssistant.pkg" ]]; then
        rm -rf "/tmp/InstallAssistant.pkg" 2>&1
    fi

    updateScriptLog "Downloading InstallAssistant.pkg from this URL: $requiredForceDownloadURL"
    curl "$requiredForceDownloadURL" -o /tmp/InstallAssistant.pkg

    updateScriptLog "Installing InstallAssistant.pkg to extract $requiredMinimumOSInstallerFilename"
    installer -verbose -pkg /tmp/InstallAssistant.pkg -target /

}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Make sure that version found in /Applications/Install macOS xxx.app matches $requiredMinimumOSInstallerVersion
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validateOSInstallerVersion(){
	if [[ -f "/Applications/${requiredMinimumOSInstallerFilename}" ]]; then
        
        OSInstallerVersion=$(defaults read "/Applications/${requiredMinimumOSInstallerFilename}/Contents/Info" CFBundleShortVersionString)
        
        if [[ "$OSInstallerVersion" != "$requiredMinimumOSInstallerVersion" ]]; then
            updateScriptLog "Found a mismatch on '${requiredMinimumOSInstallerFilename}' installer version."
            updateScriptLog "Removing ${requiredMinimumOSInstallerFilename}..."
            rm -rf "/Applications/${requiredMinimumOSInstallerFilename}" 2>&1
            updateScriptLog "Removed ${requiredMinimumOSInstallerFilename}"

        else
            updateScriptLog "Found that '${requiredMinimumOSInstallerFilename}' installer version currently matches '${requiredMinimumOSInstallerVersion}'."
            updateScriptLog "Installer looks good."
        fi
    else
    	updateScriptLog "The installer /Applications/${requiredMinimumOSInstallerFilename} for the required OS version ${requiredMinimumOSVersion} does not exist."
        updateScriptLog "It may have never been downloaded before, or it may have been previously deleted."
        updateScriptLog "Please note previous major upgrade installers won't get removed, only minor update ones."
    fi

    updateScriptLog "Should force download macOS $requiredMinimumOSVersion ?? Jamf Policy Input: ${shouldForceDownload}"
    if shouldForceDownload ; then
        forceDownloadLatestUpgrade
    else
        updateScriptLog "Allowing Nudge LaunchAgent to trigger softwareUpdate on its own to download the correct installer instead."
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset Configurations
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function resetLocalUserPreferences(){
    # For testing only; see:
    # * https://github.com/macadmins/nudge/wiki/User-Deferrals#resetting-values-when-a-new-nudge-event-is-detected
    # * https://github.com/macadmins/nudge/wiki/User-Deferrals#testing-and-resetting-nudge

    updateScriptLog "Removing User Preferences (/Users/${loggedInUser}/Library/Preferences/${plistDomain}.Nudge.plist)"
    rm -f /Users/"${loggedInUser}"/Library/Preferences/"${plistDomain}".Nudge.plist 2>&1
    updateScriptLog "Stopping Core Foundation Preferences daemon … "
    pkill -l -U "${loggedInUser}" cfprefsd
    updateScriptLog "Removed User Preferences"
}

function resetLocalJSON(){
    updateScriptLog "Removing ${jsonPath} … "
    rm -f "${jsonPath}" 2>&1
    updateScriptLog "Removed ${jsonPath}"
}

function resetLaunchAgent(){
    updateScriptLog "Unloading ${launchAgentPath} … "
    runAsUser launchctl unload -w "${launchAgentPath}" 2>&1
    updateScriptLog "Removing ${launchAgentPath} … "
    rm -f "${launchAgentPath}" 2>&1
    updateScriptLog "Removed ${launchAgentPath}"
}

function resetLaunchDaemon(){
    updateScriptLog "Unloading ${launchDaemonPath} … "
    /bin/launchctl unload -w "${launchDaemonPath}" 2>&1
    updateScriptLog "Removing ${launchDaemonPath} … "
    rm -f "${launchDaemonPath}" 2>&1
    updateScriptLog "Removed ${launchDaemonPath}"
}

function hideNudgeInFinder(){
    updateScriptLog "Hiding Nudge in Finder … "
    chflags hidden "/Applications/Utilities/Nudge.app" 
    updateScriptLog "Hid Nudge in Finder"
}

function hideNudgeInLaunchpad(){
    updateScriptLog "Hiding Nudge in Launchpad … "
    if [[ -z "$loggedInUser" ]]; then
        updateScriptLog "Did not detect logged-in user"
    else
        sqlite3 $(sudo find /private/var/folders \( -name com.apple.dock.launchpad -a -user ${loggedInUser} \) 2> /dev/null)/db/db "DELETE FROM apps WHERE title='Nudge';"
        killall Dock
        updateScriptLog "Hid Nudge in Launchpad for ${loggedInUser}"
    fi
}

function resetConfiguration() {

    killNudgeProcess

    updateScriptLog "Reset Configuration: ${1}"

    case ${1} in

        "All" )
            # Reset JSON, LaunchAgent, LaunchDaemon, Hide Nudge
            updateScriptLog "Reset All Configuration Files … "

            resetLocalUserPreferences
            resetLocalJSON
            resetLaunchAgent
            resetLaunchDaemon
            hideNudgeInFinder
            hideNudgeInLaunchpad

            updateScriptLog "Reset All Configuration Files"
            ;;

        "Uninstall" )
           # Uninstall Nudge Post-install
            updateScriptLog "Uninstalling Nudge Post-install … "

            resetLocalJSON
            resetLaunchAgent
            resetLaunchDaemon

            # Exit
            updateScriptLog "Uninstalled all Nudge Post-install configuration files"
            updateScriptLog "Thanks for using Nudge Post-install!"
            exit 0
            ;;

        "JSON" )
            # Reset JSON
            resetLocalJSON
            ;;

        "LaunchAgent" )
            # Reset LaunchAgent
            resetLaunchAgent
            ;;

        "LaunchDaemon" )
            resetLaunchDaemon
            ;;

        * )
            # None of the expected options was entered; don't reset anything
            updateScriptLog "None of the expected reset options was entered; don't reset anything"
            ;;

    esac

}


####################################################################################################
#
# Program
#
####################################################################################################

# Client-side Logging
if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "*** Created log file ***"
fi

# Logging preamble
updateScriptLog "Nudge Post-install - version: (${scriptVersion})"

# Reset Configuration
resetConfiguration "${resetConfiguration}"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Nudge Logger LaunchDaemon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f ${launchDaemonPath} ]]; then

    updateScriptLog "Create ${launchDaemonPath} … "

    cat <<EOF > "${launchDaemonPath}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${plistDomain}.Nudge.Logger</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/log</string>
        <string>stream</string>
        <string>--predicate</string>
        <string>subsystem == 'com.github.macadmins.Nudge'</string>
        <string>--style</string>
        <string>syslog</string>
        <string>--color</string>
        <string>none</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/${plistDomain}.log</string>
</dict>
</plist>
EOF

    /bin/launchctl load -w "${launchDaemonPath}" 2>&1

else

    updateScriptLog "${launchDaemonPath} exists"

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Nudge JSON client-side
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f ${jsonPath} ]]; then

    updateScriptLog "Create ${jsonPath} … "
    touch "${jsonPath}"
    updateScriptLog "Created ${jsonPath}"

    updateScriptLog "Write ${jsonPath} … "

    cat <<EOF > "${jsonPath}"
{
    "optionalFeatures": {
        "acceptableApplicationBundleIDs": [
            "us.zoom.xos",
            "com.cisco.webexmeetingsapp"
        ],
        "acceptableAssertionUsage": false,
        "acceptableAssertionApplicationNames": [
            "zoom.us",
            "Meeting Center"
        ],
        "acceptableCameraUsage": false,
        "acceptableScreenSharingUsage": false,
        "aggressiveUserExperience": false,
        "aggressiveUserFullScreenExperience": false,
        "asynchronousSoftwareUpdate": true,
        "attemptToFetchMajorUpgrade": true,
        "attemptToBlockApplicationLaunches": true,
        "blockedApplicationBundleIDs": [
            "com.apple.ColorSyncUtility",
            "com.apple.DigitalColorMeter"
            ],
        "disableSoftwareUpdateWorkflow": false,
        "enforceMinorUpdates": true,
        "terminateApplicationsOnLaunch": true
    },
    "osVersionRequirements": [
        {
        "aboutUpdateURL_disabled": "${requiredAboutUpdateURL}",
        "aboutUpdateURLs": [
            {
            "_language": "en",
            "aboutUpdateURL": "${requiredAboutUpdateURL}"
            }
        ],
        "majorUpgradeAppPath": "/Applications/${requiredMinimumOSInstallerFilename}",
        "requiredInstallationDate": "${requiredInstallationDate}",
        "requiredMinimumOSVersion": "${requiredMinimumOSVersion}",
        "targetedOSVersionsRule": "${requiredTargetedOSVersionsRule}"
        }
    ],
    "userExperience": {
        "allowGracePeriods": false,
        "allowLaterDeferralButton": true,
        "allowUserQuitDeferrals": true,
        "allowedDeferrals": 1000000,
        "allowedDeferralsUntilForcedSecondaryQuitButton": 14,
        "approachingRefreshCycle": 6000,
        "approachingWindowTime": 72,
        "elapsedRefreshCycle": 300,
        "gracePeriodInstallDelay": 23,
        "gracePeriodLaunchDelay": 1,
        "gracePeriodPath": "/private/var/db/.AppleSetupDone",
        "imminentRefreshCycle": 600,
        "imminentWindowTime": 24,
        "initialRefreshCycle": 18000,
        "maxRandomDelayInSeconds": 1200,
        "noTimers": false,
        "nudgeRefreshCycle": 60,
        "randomDelay": false
    },
    "userInterface": {
        "fallbackLanguage": "en",
        "forceFallbackLanguage": false,
        "forceScreenShotIcon": false,
        "iconDarkPath": "/somewhere/logoDark.png",
        "iconLightPath": "/somewhere/logoLight.png",
        "screenShotDarkPath": "/somewhere/screenShotDark.png",
        "screenShotLightPath": "/somewhere/screenShotLight.png",
        "showDeferralCount": true,
        "simpleMode": false,
        "singleQuitButton": false,
        "updateElements": [
        {
            "_language": "en",
            "actionButtonText": "Install & Reboot",
            "customDeferralButtonText": "Custom",
            "customDeferralDropdownText": "Defer",
            "informationButtonText": "More Info",
            "mainContentHeader": "The computer will reboot shortly after you select the ''Install & Reboot'' option.",
            "mainContentNote": "Important Notes",
            "mainContentSubHeader": "Updates can take around 30 minutes to complete.\nThis update requires at least 50% battery or connection to a power source.\nRequired Installation Date: ${requiredInstallationDate}",
            "mainContentText": "${requiredMainContentText}",
            "mainHeader": "Install the latest macOS version",
            "oneDayDeferralButtonText": "Postpone for One Day",
            "oneHourDeferralButtonText": "Postpone for One Hour",
            "primaryQuitButtonText": "Update Later",
            "secondaryQuitButtonText": "Deferral Options",
            "subHeader": "${requiredSubHeader}"
        }
        ]
    }
}
EOF

    updateScriptLog "Wrote Nudge JSON file to ${jsonPath}"

else

    updateScriptLog "${jsonPath} exists"

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Nudge LaunchAgent
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f ${launchAgentPath} ]]; then

    updateScriptLog "Create ${launchAgentPath} … "

    cat <<EOF > "${launchAgentPath}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AssociatedBundleIdentifiers</key>
	<array>
		<string>com.github.macadmins.Nudge</string>
	</array>
    <key>Label</key>
    <string>${plistDomain}.Nudge.plist</string>
    <key>LimitLoadToSessionType</key>
    <array>
        <string>Aqua</string>
    </array>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/Utilities/Nudge.app/Contents/MacOS/Nudge</string>
        <string>-json-url</string>
        <string>file://${jsonPath}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartCalendarInterval</key>
    <array>
        <dict>
            <key>Minute</key>
            <integer>0</integer>
        </dict>
        <dict>
            <key>Minute</key>
            <integer>30</integer>
        </dict>
    </array>
</dict>
</plist>
EOF

    updateScriptLog "Created ${launchAgentPath}"

    updateScriptLog "Set ${launchAgentPath} file permissions ..."
    chown root:wheel "${launchAgentPath}"
    chmod 644 "${launchAgentPath}"
    chmod +x "${launchAgentPath}"
    updateScriptLog "Set ${launchAgentPath} file permissions"

else

    updateScriptLog "${launchAgentPath} exists"

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Load Nudge LaunchAgent
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# https://github.com/macadmins/nudge/blob/main/build_assets/postinstall-launchagent
# Only enable the LaunchAgent if there is a user logged in, otherwise rely on built in LaunchAgent behavior
if [[ -z "$loggedInUser" ]]; then
    updateScriptLog "Did not detect user"
elif [[ "$loggedInUser" == "loginwindow" ]]; then
    updateScriptLog "Detected Loginwindow Environment"
elif [[ "$loggedInUser" == "_mbsetupuser" ]]; then
    updateScriptLog "Detect SetupAssistant Environment"
elif [[ "$loggedInUser" == "root" ]]; then
    updateScriptLog "Detect root as currently logged-in user"
else
    # Unload the LaunchAgent so it can be triggered on re-install
    runAsUser launchctl unload -w "${launchAgentPath}"
    # Kill Nudge just in case (say someone manually opens it and not launched via LaunchAgent
    killall Nudge
    # Validate to Make sure that version found in /Applications/Install macOS xxx.app matches $requiredMinimumOSInstallerVersion
    validateOSInstallerVersion
    # Load the LaunchAgent
    runAsUser launchctl load -w "${launchAgentPath}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Goodbye!"

exit 0