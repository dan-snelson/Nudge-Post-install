#!/bin/bash

####################################################################################################
#
#    Nudge Post-install
#
#    Purpose: Configures Nudge to company standards post-install
#    https://github.com/dan-snelson/Nudge-Post-install/wiki
#
####################################################################################################
#
# HISTORY
#
#     Version 0.0.1, 19-Mar-2021, Dan K. Snelson (@dan-snelson)
#        Original version
#
#    Version 0.0.2, 20-Mar-2021, Dan K. Snelson (@dan-snelson)
#        Leveraged additional Script Parameters
#        Added "Reset" function
#
#    Version 0.0.3, 22-Apr-2021, Dan K. Snelson (@dan-snelson)
#        Updated for macOS Big Sur 11.3
#        Fix imminentRefreshCycle typo
#
#    Version 0.0.4, 03-May-2021, Dan K. Snelson (@dan-snelson)
#        Updated for macOS Big Sur 11.3.1
#
#    Version 0.0.5, 18-May-2021, Dan K. Snelson (@dan-snelson)
#        Updated for macOS Big Sur 11.4
#        Updated for long installation times
#
#    Version 0.0.6, 22-Jul-2021, Dan K. Snelson (@dan-snelson)
#        Updated for macOS Big Sur 11.5
#        Updated for Opt-in Beta Testers
#
#    Version 0.0.7, 18-Aug-2021, Dan K. Snelson (@dan-snelson)
#        Updated for Nudge 1.1.0
#
#    Version 0.0.8, 23-Aug-2021, Dan K. Snelson (@dan-snelson)
#        Updated for `targetedOSVersionRule` https://github.com/macadmins/nudge/pull/225
#
#    Version 0.0.9, 12-Oct-2021, Dan K. Snelson (@dan-snelson)
#        Added check for logged-in user before attempting to hide Nudge in Launchpad. (Thanks for the feedback and testing, @Jotai)
#        Compared "Nudge JSON client-side" code to "Nudge / Example Assets / com.github.macadmins.Nudge.json"
#        https://github.com/macadmins/nudge/blob/main/Example%20Assets/com.github.macadmins.Nudge.json
#
#    Version 0.0.10, 19-Oct-2021, Dan K. Snelson (@dan-snelson)
#        Enforce latest version on both macOS Monterey and macOS Big Sur
#        See: https://github.com/macadmins/nudge/wiki/targetedOSVersionsRule#real-world-example-2
#
#    Version 0.0.11, 21-Jan-2022, Dan K. Snelson (@dan-snelson)
#        Updates for "asynchronousSoftwareUpdate"
#        See: https://github.com/macadmins/nudge/issues/294
#
#    Version 0.0.12, 10-Feb-2022, Dan K. Snelson (@dan-snelson)
#        Updates for "disableSoftwareUpdateWorkflow"
#        See: https://github.com/macadmins/nudge/issues/302
#
#    Version 0.0.13, 15-Mar-2022, Dan K. Snelson (@dan-snelson)
#        Updates for Grace Periods for newly provisioned machines
#        See: https://github.com/macadmins/nudge/commit/67088d0648bc038c71dc80aba85d1ec193f87534
#
#   Version 0.0.14, 16-May-2022, Dan K. Snelson (@dan-snelson)
#       Updates for Nudge 1.1.6.81352
#
#   Version 0.0.15, 18-May-2022, Dan K. Snelson (@dan-snelson)
#       Updates for Nudge 1.1.7.81380
#
#   Version 0.0.16, 03-Jun-2022, Dan K. Snelson (@dan-snelson)
#       Updates for Nudge 1.1.7.81411
#
#   Version 0.0.16, 21-Oct-2022, Dan K. Snelson (@dan-snelson)
#       **BREAKING CHANGES**
#           - Reordered Script Parameters
#           - Added default values (for when Script Parameters are left blank in a Jamf Pro policy)
#       Removed `authorizationCheck` function
#       Added macOS Ventura settings
#       Replaced `scriptResult` with `updateScriptLog`
#       Random clean-up
#
#   Version 0.0.17, 03-Jan-2023, Dan K. Snelson (@dan-snelson)
#       - Updates for Nudge [`1.1.10`](https://github.com/macadmins/nudge/pull/435)
#
#   Version 0.0.18, 11-Jan-2023, Dan K. Snelson (@dan-snelson)
#       - Set `majorUpgradeAppPath` to  `/System/Library/CoreServices/Software Update.app`
#
#   Version 0.0.19, 09-Feb-2023, Dan K. Snelson (@dan-snelson)
#       - Set `disableSoftwareUpdateWorkflow` to `true`
#
#   Version 0.0.20, 16-Mar-2023, Dan K. Snelson (@dan-snelson)
#       - Updated `launchctl` load / unload commands
#
#   Version 0.0.21, 02-May-2023, Dan K. Snelson (@dan-snelson)
#       - Disabled `asynchronousSoftwareUpdate` and `attemptToFetchMajorUpgrade`
#
#   Version 0.0.22, 27-Sep-2023, Dan K. Snelson (@dan-snelson)
#       - Added new `calendarDeferralUnit` key from Nudge 1.1.12.81501
#       - 🔥 **Breaking Change** for users of Nudge Post-install prior to `0.0.22` 🔥 
#           - Replaced multiple `required___InstallationDate` variables with a single `deadline`
#           - Updated Script Parameters
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Global Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="0.0.22-rc1"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
plistDomain="${4:-"org.churchofjesuschrist"}"        # Reverse Domain Name Notation (i.e., "org.churchofjesuschrist")
resetConfiguration="${5:-"All"}"                     # Configuration Files to Reset (i.e., None (blank) | All | JSON | LaunchAgent | LaunchDaemon)
deadline="${6:-"2023-10-24T23:00:00Z"}"              # Required Installation Date & Time (i.e., 2023-03-17T10:00:00Z)
requiredBigSurMinimumOSVersion="${7:-"11.99"}"       # Required macOS Big Sur Minimum Version (i.e., 11.7.10)
requiredMontereyMinimumOSVersion="${8:-"12.99"}"     # Required macOS Monterey Minimum Version (i.e., 12.7)
requiredVenturaMinimumOSVersion="${9:-"13.99"}"      # Required macOS Ventura Minimum Version (i.e., 13.6)
requiredSonomaMinimumOSVersion="${10:-"14.99"}"      # Required macOS Sonoma Minimum Version (i.e., 14.0.1)
scriptLog="/var/log/${plistDomain}.log"
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



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Script Logging (thanks, @smithjw!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run command as logged-in user (thanks, @scriptingosx!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function runAsUser() {

    updateScriptLog "Run \"$@\" as \"$loggedInUserID\" … "
    launchctl asuser "$loggedInUserID" sudo -u "$loggedInUser" "$@"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function resetConfiguration() {

    updateScriptLog "Reset Configuration: ${1}"

    case ${1} in

        "All" )
            # Reset JSON, LaunchAgent, LaunchDaemon, Hide Nudge
            updateScriptLog "Reset All Configuration Files … "

            # Reset User Preferences
            # For testing only; see:
            # * https://github.com/macadmins/nudge/wiki/User-Deferrals#resetting-values-when-a-new-nudge-event-is-detected
            # * https://github.com/macadmins/nudge/wiki/User-Deferrals#testing-and-resetting-nudge

            echo "Reset User Preferences"
            rm -f /Users/"${loggedInUser}"/Library/Preferences/com.github.macadmins.Nudge.plist
            pkill -l -U "${loggedInUser}" cfprefsd
            updateScriptLog "Removed User Preferences"

            # Reset JSON
            updateScriptLog "Remove ${jsonPath} … "
            rm -f "${jsonPath}" 2>&1
            updateScriptLog "Removed ${jsonPath}"

            # Reset LaunchAgent
            updateScriptLog "Unload ${launchAgentPath} … "
            runAsUser launchctl bootout gui/"${loggedInUserID}" "${launchAgentPath}" 2>&1
            updateScriptLog "Remove ${launchAgentPath} … "
            rm -f "${launchAgentPath}" 2>&1
            updateScriptLog "Removed ${launchAgentPath}"

            # Reset LaunchDaemon
            updateScriptLog "Unload ${launchDaemonPath} … "
            launchctl bootout system "${launchDaemonPath}"
            updateScriptLog "Remove ${launchDaemonPath} … "
            rm -f "${launchDaemonPath}" 2>&1
            updateScriptLog "Removed ${launchDaemonPath}"

            # Hide Nudge in Finder
            updateScriptLog "Hide Nudge in Finder … "
            chflags hidden "/Applications/Utilities/Nudge.app" 
            updateScriptLog "Hid Nudge in Finder"

            # Hide Nudge in Launchpad
            updateScriptLog "Hide Nudge in Launchpad … "
            if [[ -z "$loggedInUser" ]]; then
                updateScriptLog "Did not detect logged-in user"
            else
                sqlite3 $(sudo find /private/var/folders \( -name com.apple.dock.launchpad -a -user ${loggedInUser} \) 2> /dev/null)/db/db "DELETE FROM apps WHERE title='Nudge';"
                killall Dock
                updateScriptLog "Hid Nudge in Launchpad for ${loggedInUser}"
            fi

            updateScriptLog "Reset All Configuration Files"
            ;;

        "Uninstall" )
           # Uninstall Nudge Post-install
            updateScriptLog "Uninstalling Nudge Post-install … "

            # Uninstall JSON
            rm -f "${jsonPath}"
            updateScriptLog "Uninstalled ${jsonPath}"

            # Uninstall LaunchAgent
            updateScriptLog "Unload ${launchAgentPath} … "
            runAsUser launchctl bootout gui/"${loggedInUserID}" "${launchAgentPath}"
            rm -f "${launchAgentPath}"
            updateScriptLog "Uninstalled ${launchAgentPath}"

            # Uninstall LaunchDaemon
            updateScriptLog "Unload ${launchDaemonPath} … "
            launchctl bootout system "${launchDaemonPath}"
            rm -f "${launchDaemonPath}"
            updateScriptLog "Uninstalled ${launchDaemonPath}"

            # Exit
            updateScriptLog "Uninstalled all Nudge Post-install configuration files"
            updateScriptLog "Thanks for using Nudge Post-install!"
            exit 0
            ;;

        "JSON" )
            # Reset JSON
            updateScriptLog "Remove ${jsonPath} … "
            rm -f "${jsonPath}"
            updateScriptLog "Removed ${jsonPath}"
            ;;

        "LaunchAgent" )
            # Reset LaunchAgent
            updateScriptLog "Unload ${launchAgentPath} … "
            runAsUser launchctl bootout gui/"${loggedInUserID}" "${launchAgentPath}"
            updateScriptLog "Remove ${launchAgentPath} … "
            rm -f "${launchAgentPath}"
            updateScriptLog "Removed ${launchAgentPath}"
            ;;

        "LaunchDaemon" )
            # Reset LaunchDaemon
            updateScriptLog "Unload ${launchDaemonPath} … "
            launchctl bootout system "${launchDaemonPath}" 2>&1
            updateScriptLog "Remove ${launchDaemonPath} … "
            rm -f "${launchDaemonPath}"
            updateScriptLog "Removed ${launchDaemonPath}"
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

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "*** Created log file ***"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Nudge Post-install (${scriptVersion})\n###\n"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

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

    launchctl bootstrap system "${launchDaemonPath}" 2>&1

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
        "acceptableAssertionUsage": true,
        "acceptableAssertionApplicationNames": [
            "zoom.us",
            "Meeting Center"
        ],
        "acceptableCameraUsage": true,
        "acceptableScreenSharingUsage": true,
        "aggressiveUserExperience": true,
        "aggressiveUserFullScreenExperience": true,
        "asynchronousSoftwareUpdate": false,
        "attemptToFetchMajorUpgrade": false,
        "attemptToBlockApplicationLaunches": true,
        "blockedApplicationBundleIDs": [
            "com.apple.ColorSyncUtility",
            "com.apple.DigitalColorMeter"
        ],
        "disableSoftwareUpdateWorkflow": true,
        "enforceMinorUpdates": true,
        "terminateApplicationsOnLaunch": true
    },
    "osVersionRequirements": [
        {
        "aboutUpdateURLs": [
            {
            "_language": "en",
            "aboutUpdateURL": "https://support.apple.com/en-us/HT211896#macos116"
            }
        ],
        "majorUpgradeAppPath": "/System/Library/CoreServices/Software Update.app",
        "requiredInstallationDate": "${deadline}",
        "requiredMinimumOSVersion": "${requiredBigSurMinimumOSVersion}",
        "targetedOSVersionsRule": "11"
        },
        {
        "aboutUpdateURLs": [
            {
            "_language": "en",
            "aboutUpdateURL": "https://www.apple.com/macos/monterey/"
            }
        ],
        "majorUpgradeAppPath": "/System/Library/CoreServices/Software Update.app",
        "requiredInstallationDate": "${deadline}",
        "requiredMinimumOSVersion": "${requiredMontereyMinimumOSVersion}",
        "targetedOSVersionsRule": "12"
        },
        {
        "aboutUpdateURLs": [
            {
            "_language": "en",
            "aboutUpdateURL": "https://www.apple.com/macos/ventura/"
            }
        ],
        "majorUpgradeAppPath": "/System/Library/CoreServices/Software Update.app",
        "requiredInstallationDate": "${deadline}",
        "requiredMinimumOSVersion": "${requiredVenturaMinimumOSVersion}",
        "targetedOSVersionsRule": "13"
        },
        {
        "aboutUpdateURLs": [
            {
            "_language": "en",
            "aboutUpdateURL": "https://servicenow.churchofjesuschrist.org/support?id=kb_article_view&sysparm_article=KB0054571"
            }
        ],
        "majorUpgradeAppPath": "/System/Library/CoreServices/Software Update.app",
        "requiredInstallationDate": "${deadline}",
        "requiredMinimumOSVersion": "${requiredSonomaMinimumOSVersion}",
        "targetedOSVersionsRule": "14"
        }
    ],
    "userExperience": {
        "allowGracePeriods": true,
        "allowLaterDeferralButton": false,
        "allowUserQuitDeferrals": true,
        "allowedDeferrals": 1000000,
        "allowedDeferralsUntilForcedSecondaryQuitButton": 14,
        "approachingRefreshCycle": 6000,
        "approachingWindowTime": 72,
        "calendarDeferralUnit": "imminentWindowTime",
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
        "actionButtonPath": "jamfselfservice://content?entity=policy&id=1&action=execute",
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
            "actionButtonText": "actionButtonText",
            "customDeferralButtonText": "customDeferralButtonText",
            "customDeferralDropdownText": "customDeferralDropdownText",
            "informationButtonText": "informationButtonText",
            "mainContentHeader": "mainContentHeader",
            "mainContentNote": "mainContentNote",
            "mainContentSubHeader": "mainContentSubHeader",
            "mainContentText": "mainContentText \n\nTo perform the update now, click \"actionButtonText,\" review the on-screen instructions by clicking \"More Info…\" then click \"Update Now.\" (Click screenshot below.)\n\nIf you are unable to perform this update now, click \"primaryQuitButtonText\" (which will no longer be visible once the ${deadline} deadline has passed).",
            "mainHeader": "mainHeader",
            "oneDayDeferralButtonText": "oneDayDeferralButtonText",
            "oneHourDeferralButtonText": "oneHourDeferralButtonText",
            "primaryQuitButtonText": "primaryQuitButtonText",
            "secondaryQuitButtonText": "secondaryQuitButtonText",
            "subHeader": "subHeader"
        }
        ]
    }
}
EOF

    updateScriptLog "Wrote Nudge JSON file to ${jsonPath}; "

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

    updateScriptLog "Created ${launchAgentPath};"

    updateScriptLog "Setting ${launchAgentPath} file permissions ..."
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

    updateScriptLog "Unload the LaunchAgent so it can be triggered on re-install"
    # runAsUser launchctl bootout gui/"${loggedInUserID}" "${launchAgentPath}" 2>&1
    launchctl bootout gui/"${loggedInUserID}" "${launchAgentPath}" 2>&1

    updateScriptLog "Kill Nudge just in case (say someone manually opens it and not launched via LaunchAgent"
    killall Nudge

    updateScriptLog "Load the LaunchAgent …"
    # runAsUser launchctl bootstrap gui/"${loggedInUserID}" "${launchAgentPath}" 2>&1
    launchctl bootstrap gui/"${loggedInUserID}" "${launchAgentPath}" 2>&1


fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Goodbye!"

exit 0