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
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

scriptVersion="0.0.3"
scriptResult=""
loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
loggedInUserID=$( /usr/bin/id -u "${loggedInUser}" )
authorizationKey="${4}"				# Authorization Key to prevent unauthorized execution via Jamf Remote
plistDomain="${5}"					# Reverse Domain Name Notation (i.e., "org.churchofjesuschrist")
requiredMinimumOSVersion="${6}"		# Required Minimum OS Version (i.e., 11.3)
requiredInstallationDate="${7}"		# Required Installation Date & Time (i.e., 2021-05-07T10:00:00Z)
resetConfiguration="${8}"			# Configuration Files to Reset (i.e., None (blank) | All | JSON | LaunchAgent | LaunchDaemon)
jsonPath="/Library/Preferences/${plistDomain}.Nudge.json"
launchAgentPath="/Library/LaunchAgents/${plistDomain}.Nudge.plist"
launchDaemonPath="/Library/LaunchDaemons/${plistDomain}.Nudge.logger.plist"



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
			# Reset All Configuration Files JSON, LaunchAgent, LaunchDaemon
			echo "Reset All Configuration Files"

			# Reset JSON
			echo "Remove ${jsonPath} …"
			/bin/rm -fv ${jsonPath}
			scriptResult+="Removed ${jsonPath}; "

			# Reset LaunchAgent
			echo "Unload ${launchAgentPath} …"
			/bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}"
			echo "Remove ${launchAgentPath} …"
			/bin/rm -fv ${launchAgentPath}
			scriptResult+="Removed ${launchAgentPath}; "

			# Reset LaunchDaemon
			echo "Unload ${launchDaemonPath} …"
			/bin/launchctl unload -w "${launchDaemonPath}"
			echo "Remove ${launchDaemonPath} …"
			/bin/rm -fv ${launchDaemonPath}
			scriptResult+="Removed ${launchDaemonPath}; "

			scriptResult+="Reset All Configuration Files; "
			;;

		"JSON" )
			# Reset JSON
			echo "Remove ${jsonPath} …"
			/bin/rm -fv ${jsonPath}
			scriptResult+="Removed ${jsonPath}; "
			;;

		"LaunchAgent" )
			# Reset LaunchAgent
			echo "Unload ${launchAgentPath} …"
			/bin/launchctl asuser "${loggedInUserID}" /bin/launchctl unload -w "${launchAgentPath}"
			echo "Remove ${launchAgentPath} …"
			/bin/rm -fv ${launchAgentPath}
			scriptResult+="Removed ${launchAgentPath}; "
			;;

		"LaunchDaemon" )
			# Reset LaunchDaemon
			echo "Unload ${launchDaemonPath} …"
			/bin/launchctl unload -w "${launchDaemonPath}"
			echo "Remove ${launchDaemonPath} …"
			/bin/rm -fv ${launchDaemonPath}
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

	cat <<EOF > ${launchDaemonPath}
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
	/usr/bin/touch ${jsonPath}
	scriptResult+="Created ${jsonPath}; "

	echo "Write ${jsonPath} …"

	cat <<EOF > ${jsonPath}
{
	"optionalFeatures": {
	  "asyncronousSoftwareUpdate": true,
	  "attemptToFetchMajorUpgrade": true,
	  "enforceMinorUpdates": true
	},
	"osVersionRequirements": [
	  {
		"aboutUpdateURL_disabled": "https://servicenow.churchofjesuschrist.org/support?id=kb_article_view&sysparm_article=KB0054571",
		"aboutUpdateURLs": [
		  {
			"_language": "en",
			"aboutUpdateURL": "https://servicenow.churchofjesuschrist.org/support?id=kb_article_view&sysparm_article=KB0054571"
		  }
		],
		"majorUpgradeAppPath": "/Applications/Install macOS Big Sur.app",
		"requiredInstallationDate": "${requiredInstallationDate}",
		"requiredMinimumOSVersion": "${requiredMinimumOSVersion}",
		"targetedOSVersions": [
		  "11.0",
		  "11.0.1",
		  "11.1",
		  "11.2",
		  "11.2.1",
		  "11.2.2",
		  "11.2.3"
		]
	  }
	],
	"userExperience": {
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
	  "fallbackLanguage": "en",
	  "forceFallbackLanguage": false,
	  "forceScreenShotIcon": false,
	  "iconDarkPath": "/usr/local/companyname/icons/WAS.icns",
	  "iconLightPath": "/usr/local/companyname/icons/WAS.icns",
	  "screenShotDarkPath": "/usr/local/companyname/icons/nudgeInstructionsDark.png",
	  "screenShotLightPath": "/usr/local/companyname/icons/nudgeInstructions.png",
	  "simpleMode": false,
	  "singleQuitButton": true,
	  "updateElements": [
		{
		  "_language": "en",
		  "mainHeader": "Critical macOS Update Available",
		  "subHeader": "",
		  "mainContentHeader": "A critical macOS update is available",
		  "mainContentSubHeader": "Updates may take 45 minutes or longer",
		  "actionButtonText": "Open Software Update",
		  "mainContentNote": "Instructions",
		  "mainContentText": "To perform the update now, click \"Open Software Update,\" review the on-screen instructions by clicking \"More Info…\" then click \"Update Now.\" (Click screenshot below.)\n\nIf you are unable to perform this update now, click \"Later\" (which will no longer be visible once the ${requiredInstallationDate} deadline has passed).\n\nPlease see KB0054571 or contact the Global Service Department with questions:\n+1 (801) 240-4357.",
		  "informationButtonText": "View KB0054571 …",
		  "primaryQuitButtonText": "Later",
		  "secondaryQuitButtonText": "secondaryQuitButtonText"
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

	cat <<EOF > ${launchAgentPath}
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
		<string>file:////${jsonPath}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StartCalendarInterval</key>
	<array>
		<dict>
			<key>Hour</key>
  			<integer>9</integer>
			<key>Minute</key>
			<integer>17</integer>
			<key>Hour</key>
  			<integer>15</integer>
			<key>Minute</key>
			<integer>17</integer>
		</dict>
	</array>
</dict>
</plist>
EOF

	scriptResult+="Created ${launchAgentPath}; "

	echo "Set ${launchAgentPath} file permissions ..."
	/usr/sbin/chown root:wheel ${launchAgentPath}
	/bin/chmod 644 ${launchAgentPath}
	/bin/chmod +x ${launchAgentPath}
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
# Hide Nudge in Finder & Launchpad
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Hide Nudge in Finder …"
/usr/bin/chflags hidden "/Applications/Utilities/Nudge.app" 

sleep 15

echo "Hide Nudge in Launchpad …"
/usr/bin/sqlite3 $(/usr/bin/sudo find /private/var/folders -name com.apple.dock.launchpad)/db/db "DELETE FROM apps WHERE title='Nudge'"
/usr/bin/killall Dock

scriptResult+="Hid Nudge in Finder & Launchpad; "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Goodbye!"

echo "${scriptResult}"

exit 0