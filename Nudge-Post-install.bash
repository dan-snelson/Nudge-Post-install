#!/bin/bash

####################################################################################################
#
#	Nudge Post-install
#
#	Purpose: Configures Nudge to company standards post-install
#	https://github.com/macadmins/nudge/blob/main/README.md#configuration
#
####################################################################################################
#
# HISTORY
#
# 	Version 0.0.1, 19-Mar-2021, Dan K. Snelson (@dan-snelson)
#		Original version
#
#	Version 0.0.2, 20-Mar-2021, Dan K. Snelson (@dan-snelson)
#		Leveraged additional Script Parameters
#		Added "Reset" function
#
#	Version 0.0.3, 29-Apr-2021, Dan K. Snelson (@dan-snelson)
#		Updated for macOS Big Sur 11.3
#		Fix imminentRefreshCycle typo
#
#	Version 0.0.4, 27-May-2021, Dan K. Snelson (@dan-snelson)
#		Updated for macOS Big Sur 11.4
#		Moved the "Hide Nudge in Finder & Launchpad" code into the "Reset > All" section
#		Changed "userInterface" values to field names (to hopefully more easily identify in the UI)
#
#	Version 0.0.5, 02-Jul-2021, Dan K. Snelson (@dan-snelson)
#		Updated for macOS Big Sur 11.5
#		Corrected Hiding Nudge in Launchpad for macOS Monterey
#
#	Version 0.0.6, 18-Aug-2021, Dan K. Snelson (@dan-snelson)
#		Updated for Nudge 1.1.0
#
#	Version 0.0.7, 12-Oct-2021, Dan K. Snelson (@dan-snelson)
#		Added check for logged-in user before attempting to hide Nudge in Launchpad. (Thanks for the feedback and testing, @Jotai)
#		Compared "Nudge JSON client-side" code to "Nudge / Example Assets / com.github.macadmins.Nudge.json"
#		https://github.com/macadmins/nudge/blob/main/Example%20Assets/com.github.macadmins.Nudge.json
#
#	Version 0.0.8, 19-Oct-2021, Dan K. Snelson (@dan-snelson)
#		Enforce latest version on both macOS Monterey and macOS Big Sur
#		See: https://github.com/macadmins/nudge/wiki/targetedOSVersionsRule#real-world-example-2
#
#	Version 0.0.9, 21-Jan-2022, Dan K. Snelson (@dan-snelson)
#		Updates for "asynchronousSoftwareUpdate"
#		See: https://github.com/macadmins/nudge/issues/294
#
#	Version 0.0.10, 10-Feb-2022, Dan K. Snelson (@dan-snelson)
#		Updates for "disableSoftwareUpdateWorkflow"
#		See: https://github.com/macadmins/nudge/issues/302
#
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

scriptVersion="0.0.10"
scriptResult=""
loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
loggedInUserID=$( /usr/bin/id -u "${loggedInUser}" )
authorizationKey="${4}"				# Authorization Key to prevent unauthorized execution via Jamf Remote
plistDomain="${5}"				# Reverse Domain Name Notation (i.e., "org.churchofjesuschrist")
resetConfiguration="${6}"			# Configuration Files to Reset (i.e., None (blank) | All | JSON | LaunchAgent | LaunchDaemon)
requiredBigSurMinimumOSVersion="${7}"		# Required macOS Big Sur Minimum Version (i.e., 11.6.3)
requiredBigSurInstallationDate="${8}"		# Required macOS Big SurInstallation Date & Time (i.e., 2022-02-15T10:00:00Z)
requiredMontereyMinimumOSVersion="${9}"		# Required macOS Monterey Minimum Version (i.e., 12.2)
requiredMontereyInstallationDate="${10}"	# Required macOS Monterey Installation Date & Time (i.e., 2022-02-15T10:00:00Z)
jsonPath="/Library/Preferences/${plistDomain}.Nudge.json"
launchAgentPath="/Library/LaunchAgents/${plistDomain}.Nudge.plist"
launchDaemonPath="/Library/LaunchDaemons/${plistDomain}.Nudge.logger.plist"

# Set deadline variable based on OS version
osProductVersion=$( /usr/bin/sw_vers -productVersion )
case "${osProductVersion}" in
	11* ) deadline="${requiredBigSurInstallationDate}"	;;
	12* ) deadline="${requiredMontereyInstallationDate}"	;;
esac



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for a specified value in Parameter 4 to prevent unauthorized script execution
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function authorizationCheck() {

	if [[ "${authorizationKey}" != "PurpleMonkeyDishwasher" ]]; then

		scriptResult+="Error: Incorrect Authorization Key; exiting."
		echo "${scriptResult}"
		exit 1

	else

		scriptResult+="Correct Authorization Key, proceeding; "

	fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function resetConfiguration() {

	echo "Reset Configuration: ${1}"
	scriptResult+="Reset Configuration: ${1}; "

	case ${1} in

		"All" )
			# Reset JSON, LaunchAgent, LaunchDaemon, Hide Nudge
			echo "Reset All Configuration Files"

			# Reset User Preferences
			# For testing only; see:
			# * https://github.com/macadmins/nudge/wiki/User-Deferrals#resetting-values-when-a-new-nudge-event-is-detected
			# * https://github.com/macadmins/nudge/wiki/User-Deferrals#testing-and-resetting-nudge

			# echo "Reset User Preferences"
			# /bin/rm -fv /Users/"${loggedInUser}"/Library/Preferences/com.github.macadmins.Nudge.plist
			# /usr/bin/pkill -l -U "${loggedInUser}" cfprefsd
			# scriptResult+="Removed User Preferences; "

			# Reset JSON
			echo "Remove ${jsonPath} …"
			/bin/rm -fv "${jsonPath}"
			scriptResult+="Removed ${jsonPath}; "

			# Reset LaunchAgent
			echo "Unload ${launchAgentPath} …"
			/bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}"
			echo "Remove ${launchAgentPath} …"
			/bin/rm -fv "${launchAgentPath}"
			scriptResult+="Removed ${launchAgentPath}; "

			# Reset LaunchDaemon
			echo "Unload ${launchDaemonPath} …"
			/bin/launchctl unload -w "${launchDaemonPath}"
			echo "Remove ${launchDaemonPath} …"
			/bin/rm -fv "${launchDaemonPath}"
			scriptResult+="Removed ${launchDaemonPath}; "

			# Hide Nudge in Finder
			echo "Hide Nudge in Finder …"
			/usr/bin/chflags hidden "/Applications/Utilities/Nudge.app" 
			scriptResult+="Hid Nudge in Finder; "

			# Hide Nudge in Launchpad
			echo "Hide Nudge in Launchpad …"
			if [[ -z "$loggedInUser" ]]; then
				scriptResult+="Did not detect logged-in user"
			else
				/usr/bin/sqlite3 $(/usr/bin/sudo find /private/var/folders \( -name com.apple.dock.launchpad -a -user "${loggedInUser}" \) 2> /dev/null)/db/db "DELETE FROM apps WHERE title='Nudge';"
				/usr/bin/killall Dock
				scriptResult+="Hid Nudge in Launchpad for ${loggedInUser}; "
			fi

			scriptResult+="Reset All Configuration Files; "
			;;

		"JSON" )
			# Reset JSON
			echo "Remove ${jsonPath} …"
			/bin/rm -fv "${jsonPath}"
			scriptResult+="Removed ${jsonPath}; "
			;;

		"LaunchAgent" )
			# Reset LaunchAgent
			echo "Unload ${launchAgentPath} …"
			/bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}"
			echo "Remove ${launchAgentPath} …"
			/bin/rm -fv "${launchAgentPath}"
			scriptResult+="Removed ${launchAgentPath}; "
			;;

		"LaunchDaemon" )
			# Reset LaunchDaemon
			echo "Unload ${launchDaemonPath} …"
			/bin/launchctl unload -w "${launchDaemonPath}"
			echo "Remove ${launchDaemonPath} …"
			/bin/rm -fv "${launchDaemonPath}"
			scriptResult+="Removed ${launchDaemonPath}; "
			;;

		* )
			# None of the expected options was entered; don't reset anything
			echo "None of the expected reset options was entered; don't reset anything"
			scriptResult+="None of the expected reset options was entered; don't reset anything; "
			;;

	esac

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo " "
echo "###"
echo "# Nudge Post-install (${scriptVersion})"
echo "###"
echo " "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Authorization
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

authorizationCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reset Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resetConfiguration "${resetConfiguration}"




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Nudge Logger LaunchDaemon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f ${launchDaemonPath} ]]; then

	echo "Create ${launchDaemonPath} …"

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

	/bin/launchctl load -w "${launchDaemonPath}"

else

	echo "${launchDaemonPath} exists"
	scriptResult+="${launchDaemonPath} exists; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Nudge JSON client-side
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f ${jsonPath} ]]; then

	echo "Create ${jsonPath} …"
	/usr/bin/touch "${jsonPath}"
	scriptResult+="Created ${jsonPath}; "

	echo "Write ${jsonPath} …"

	cat <<EOF > "${jsonPath}"
{
	"optionalFeatures": {
		"acceptableApplicationBundleIDs": [
			"us.zoom.xos"
		],
		"aggressiveUserExperience": true,
		"asynchronousSoftwareUpdate": true,
		"attemptToFetchMajorUpgrade": true,
		"disableSoftwareUpdateWorkflow": false,
		"enforceMinorUpdates": true
	},
	"osVersionRequirements": [
		{
		"aboutUpdateURLs": [
			{
			"_language": "en",
			"aboutUpdateURL": "https://support.apple.com/en-us/HT211896#macos116"
			}
		],
		"majorUpgradeAppPath": "/Applications/Install macOS Big Sur.app",
		"requiredInstallationDate": "${requiredBigSurInstallationDate}",
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
		"majorUpgradeAppPath": "/Applications/Install macOS Monterey.app",
		"requiredInstallationDate": "${requiredMontereyInstallationDate}",
		"requiredMinimumOSVersion": "${requiredMontereyMinimumOSVersion}",
		"targetedOSVersionsRule": "12"
		}
	],
	"userExperience": {
		"allowUserQuitDeferrals": true,
		"allowedDeferrals": 1000000,
		"allowedDeferralsUntilForcedSecondaryQuitButton": 14,
		"approachingRefreshCycle": 6000,
		"approachingWindowTime": 72,
		"elapsedRefreshCycle": 300,
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
		"iconDarkPath": "",
		"iconLightPath": "",
		"screenShotDarkPath": "",
		"screenShotLightPath": "",
		"showDeferralCount": true,
		"simpleMode": false,
		"singleQuitButton": false,
		"updateElements": [
		{
			"_language": "en",
			"actionButtonText": "actionButtonText",
			"customDeferralButtonText": "customDeferralButtonText",
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

	scriptResult+="Wrote Nudge JSON file to ${jsonPath}; "

else

	echo "${jsonPath} exists"
	scriptResult+="${jsonPath} exists; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Nudge LaunchAgent
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f ${launchAgentPath} ]]; then

	echo "Create ${launchAgentPath} …"

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

	scriptResult+="Created ${launchAgentPath}; "

	echo "Set ${launchAgentPath} file permissions ..."
	/usr/sbin/chown root:wheel "${launchAgentPath}"
	/bin/chmod 644 "${launchAgentPath}"
	/bin/chmod +x "${launchAgentPath}"
	scriptResult+="Set ${launchAgentPath} file permissions; "

else

	echo "${launchAgentPath} exists"
	scriptResult+="${launchAgentPath} exists; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Load Nudge LaunchAgent
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# https://github.com/macadmins/nudge/blob/main/build_assets/postinstall-launchagent
# Only enable the LaunchAgent if there is a user logged in, otherwise rely on built in LaunchAgent behavior
if [[ -z "$loggedInUser" ]]; then
	echo "Did not detect user"
elif [[ "$loggedInUser" == "loginwindow" ]]; then
	echo "Detected Loginwindow Environment"
elif [[ "$loggedInUser" == "_mbsetupuser" ]]; then
	echo "Detect SetupAssistant Environment"
elif [[ "$loggedInUser" == "root" ]]; then
	echo "Detect root as currently logged-in user"
else
	# Unload the LaunchAgent so it can be triggered on re-install
	/bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}"
	# Kill Nudge just in case (say someone manually opens it and not launched via LaunchAgent
	/usr/bin/killall Nudge
	# Load the LaunchAgent
	/bin/launchctl asuser "${loggedInUserID}" /bin/launchctl load -w "${launchAgentPath}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Goodbye!"

echo "${scriptResult}"

exit 0