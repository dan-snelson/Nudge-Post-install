# Nudge Post-install

**Configures [Nudge](https://github.com/macadmins/nudge/blob/main/README.md) via the [Nudge Post-install](Nudge-Post-install.bash) script to create:**
- LaunchAgent: Opens Nudge 
- LaunchDaemon: Redirect Logs
- Local JSON: Configures Nudge
- Hides Nudge: Finder & Launchpad
- Reset function: Policy Script Parameter

---

## Contents
- [Presentations](#presentations)
- [Step Zero](#step-zero)
- [Plan Your Deployment Stategy](#plan-your-deployment-stategy)
- [Configuration Methods](#configuration-methods)
- [Script](#script)
- [Package](#package)
- [Smart Group](#smart-group)
- [Policies](#policies)
- [General Resources](#general-resources)

---

### Presentations

- JNUC 2021
  - ["Nudge" users to keep macOS up-to-date with Jamf Pro](https://rumble.com/vnqm8k-nudge-users-to-keep-macos-up-to-date-with-jamf-pro.html)
  - [Nudge v1.1.0 Features](https://rumble.com/vlsp5h-nudge-v1.1.0-features.html)

---
## Step Zero

Please first review Nudge's [Jamf Pro Guide](https://github.com/macadmins/nudge/wiki/Jamf-Pro-Guide). 

This article details **Option No. 3** and presumes you are comfortable editing scripts.


---

## Plan Your Deployment Stategy

### Understanding Nudge
Ensure you understand what Nudge _is_ and what Nudge is **not**:

> Nudge is an multi-linguistic application, offering custom user deferrals, which strongly encourages macOS updates. Written in Swift 5.5 and SwiftUI 5.2, Nudge will only work on macOS Big Sur 11 and later.
>
> Rather than trying to install updates via the macOS built-in `softwareupdate` binary, Nudge prompts users to install updates via Apple approved / tested methods: **System Preferences > Software Update** and major application upgrades via the standalone macOS installer (i.e., Install macOS Monterey.app).

While Nudge will compare a Mac's currently installed version of macOS to the value you set for Nudge's `requiredMinimumOSVersion`, before deploying Nudge to computers with Jamf Pro, review the computers' **Inventory > Software Updates** to ensure the update users are being prompted to install is available.

---
## Configuration Methods
### Configuration Profile vs. Local JSON

Carefully review [Nudge Preferences](https://github.com/macadmins/nudge/wiki/Preferences) and determine if deploying either a Configuration Profile [(Option No. 2)](https://github.com/macadmins/nudge/wiki/Jamf-Pro-Guide) or local JSON (Option No. 3, the remainder of this article) will best meet your needs. 

| Option | Nudge.app | LaunchAgent | Preference |
|--------|-----------|-------------|------------|
| <center>1</center> | <center><img src="images/PKG%20icon.png" width="100"></center> <br /> Nudge-1.1.2.x.pkg | | <img src="images/Firefox%20icon.png" width="100">  <img src="images/Terminal%20icon.png" width="100"> <br /> <center>Local Testing</center> |
|  <center>2</center> | <center><img src="images/PKG%20icon.png" width="100"></center> <br /> Nudge-1.1.2.x.pkg | <center><img src="images/PKG%20icon.png" width="100"> <br /> Nudge_LaunchAgent-1.0.0.pkg </center> | <img src="images/Jamf%20Pro%20icon.png" width="100">  <img src="images/Configuration%20Profile%20icon.png" width="100"> <br /> <center>Jamf Pro JSON Schema</center> |
|  <center>3</center> | <center><img src="images/PKG%20icon.png" width="100"></center> <br /> Nudge-1.1.2.x.pkg | <img src="images/Terminal%20icon.png" width="100"> <img src="images/PLIST%20icon.png" width="100"> <br /> <center>Nudge Post-install script</center> | <img src="images/Terminal%20icon.png" width="100"> <img src="images/JSON%20icon.png" width="100"> <br /> <center>Nudge Post-install script</center> |

1. **Option No. 1** is when you are first testing Nudge. You'll install the [latest Nudge.app](https://github.com/macadmins/nudge/releases) on a test Mac and then carefully review the following articles and use your favorite editor to modify Nudge's configuration, then use Terminal to test Nudge's built-in [JSON support](https://github.com/macadmins/nudge/wiki#json-support):
	- [Nudge README](https://github.com/macadmins/nudge/blob/main/README.md)
	- [Nudge Wiki](https://github.com/macadmins/nudge/wiki)
	- [Getting Started](https://github.com/macadmins/nudge/wiki/Getting-Started)
	
	When you're satisfied with your Nudge configuration on your local test Mac, it's time to deploy to your testing group.
1. Every release of Nudge includes a [`LaunchAgent` package](https://github.com/macadmins/nudge/wiki#scheduling-nudge-to-run), which we see in **Option No. 2**. This `LaunchAgent` will open Nudge every 30 minutes — on the hour and half-past the hour.  You will still need to deploy the Nudge app itself,  and with this option, a [Jamf Pro JSON Schema to deploy a Configuration Profile](https://github.com/macadmins/nudge/wiki/Jamf-Pro-Guide#configuration-profile) for Nudge's settings.
	- If you deploy a standard Configuration Profile, **it must be signed** or it *will be* modified by Jamf Pro. (See: [Creating a Signing Certificate Using Jamf Pro's Built-in CA to Use for Signing Configuration Profiles and Packages](https://www.jamf.com/jamf-nation/articles/649/).)
1. **Option No. 3** leverages the [Nudge Post-install](Nudge-Post-install.bash) script deployed via the Jamf Pro Script Payload to create:
	- LaunchAgent: Opens Nudge 
	- LaunchDaemon: Redirect Logs
	- Local JSON: Configures Nudge
	- Hides Nudge: Finder & Launchpad
	- Reset function: Policy Script Parameter

	**Note:** All support for this workflow will need to be asked in the [author's GitHub](https://github.com/dan-snelson/Nudge-Post-install/discussions) and you should be comfortable editing scripts when using this option.

The remainder of this article focuses on **Option No. 3**.

---
## Script

### Resources

- [Jamf Pro Administrator's Guide Scripts](https://docs.jamf.com/10.32.0/jamf-pro/administrator-guide/Scripts.html)
- [Screencast](https://rumble.com/vnxv7u-nudge-post-install-script.html) (01:44; no audio)

Add the [Nudge Post-install](Nudge-Post-install.bash) script to Jamf Pro:

#### Jamf Pro Script Parameter Labels

- **Parameter 4:** Authorization Key
- **Parameter 5:** Reverse Domain Name Notation (i.e., `org.churchofjesuschrist`)
- **Parameter 6:** Configuration Files to Reset (i.e., `None (blank) | All | JSON | LaunchAgent | LaunchDaemon`)
- **Parameter 7:** Required macOS Big Sur Minimum OS Version (i.e., `11.6`)
- **Parameter 8:** Required macOS Big Sur Installation Date & Time (i.e., `2021-10-01T23:00:00Z`)
- **Parameter 9:** Required macOS Monterey Minimum OS Version (i.e., `12.0.1`)
- **Parameter 10:** Required macOS Monterey Installation Date & Time (i.e., `2021-11-12T23:00:00Z`)

<img src="images/Nudge%20Post-install%20Script%20Parameter%20Labels.png" width="900">

**Note:** Beginning with **Nudge 1.1.0**, Mac Admins can leverage `userInterface : actionButtonPath` to execute a [Jamf Pro policy](https://docs.jamf.com/10.32.0/jamf-pro/administrator-guide/Jamf_Self_Service_for_macOS_URL_Schemes.html).

```json
"userInterface": {
	"actionButtonPath": "jamfselfservice://content?entity=policy&id=1&action=execute",
```

To open **System Preferences > Software Update** (i.e., Nudge v1.0.0 behavior), [delete the entire `actionButtonPath` line](Nudge-Post-install.bash#L352).

---

## Package

Nudge is updated frequently and the latest version is always available from [Nudge Releases](https://github.com/macadmins/nudge/releases).

Using [Jamf Pro Package Management](https://docs.jamf.com/10.32.0/jamf-pro/administrator-guide/Package_Management.html) as a guide, upload the required Nudge .PKG:
- Nudge-1.1.2.x.pkg
- ~~Nudge_LaunchAgent-1.0.0.pkg~~ (The required `LaunchAgent` is included in the Nudge Post-install script.) 

---

## Smart Group

Using the Jamf Pro Administrator's Guide [Smart Groups](https://docs.jamf.com/10.32.0/jamf-pro/administrator-guide/Smart_Groups.html) as a guide, create the following Smart Groups:

### Update Smart: Nudge

| And / Or | | Criteria | Operator | Value | |
|----------|-|----------|----------|-------|-|
| | ( | Application Title | is | `Nudge.app` | |
| and | | Application Version | is not | `1.1.2.10182021160959` | ) |
| or | | Application Title | does not have | `Nudge.app` | |
| and | | Operating System Version | greater than or equal | `11.0.1` | |

<img src="images/Update%20Smart%20Nudge.png" width="900">

---

## Policies
### Overview

<img src="images/Nudge%20Polciies.png" width="900">

#### Nudge (1.1.2.x)
#### Options
- **General**
	- Display Name: Nudge (1.1.2.x)
	- Trigger: Recurring Check-in
	- Execution Frequency: Ongoing
- **Package**
	- Nudge-1.1.2.x.pkg
	- ~~Nudge_LaunchAgent-1.0.0.pkg~~ (The required `LaunchAgent` is included in the Nudge Post-install script.) 
- **Maintenance**
	- Update Inventory 
- **Files and Processes**
	- Execute Command: `/usr/bin/chflags hidden "/Applications/Utilities/Nudge.app" ; loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' ) ; [ -z "${loggedInUser}" ] && echo "Did not detect user" || /usr/bin/sqlite3 $(/usr/bin/sudo find /private/var/folders \( -name com.apple.dock.launchpad -a -user ${loggedInUser} \) 2> /dev/null)/db/db "DELETE FROM apps WHERE title='Nudge';" && /usr/bin/killall Dock`
#### Scope
- **Targets:** Update Smart: Nudge
- **Limitations:** No Limitations
- **Exclusions:** No Exclusions

<hr width="33%">

#### Nudge Configuration for General Workforce

- [Screencast](https://rumble.com/vnxvb6-nudge-post-install-policy.html) (01:53; no audio)

##### Options
- **General**
	- Display Name: Nudge Configuration for General Workforce
	- Trigger: Recurring Check-in
	- Execution Frequency: Once per computer
- **Scripts**
	- Nudge Post-install (0.0.8)
		- Priority: After
		- Authorization Key: `PurpleMonkeyDishwasher`
		- Reverse Domain Name Notation: `org.churchofjesuschrist`
		- Configuration Files to Reset: `All`
		- Required macOS Big Sur Minimum OS Version: `11.6`
		- Required macOS Big Sur Installation Date & Time: `2021-10-15T23:00:00Z`
		- Required macOS Monterey Minimum OS Version: `12.0.1`
		- Required macOS Monterey Installation Date & Time: `2021-12-01T23:00:00Z`
##### Scope
- **Targets:** Nudge
- **Limitations:** No Limitations
- **Exclusions:**
	- Testing: Alpha Group
	- Testing: Beta Group
	- Testing: Gamma Group

<img src="images/Nudge%20Configuration%20General%20Workforce.png" width="900">

<hr width="33%">

#### Nudge Configuration for [Opt-in Beta Testers](https://github.com/dan-snelson/Internal-Beta-Test-Program/blob/master/README.md)
##### Options
- **General**
	- Display Name: Nudge Configuration for Opt-in Beta Testers
	- Trigger: Recurring Check-in
	- Execution Frequency: Once per computer
- **Scripts**
	- Nudge Post-install (0.0.8)
		- Priority: After
		- Authorization Key: `PurpleMonkeyDishwasher`
		- Reverse Domain Name Notation: `org.churchofjesuschrist`
		- Configuration Files to Reset: `All`
		- Required macOS Big Sur Minimum OS Version: `11.6`
		- Required macOS Big Sur Installation Date & Time: `2021-10-01T23:00:00Z`
		- Required macOS Monterey Minimum OS Version: `12.0.1`
		- Required macOS Monterey Installation Date & Time: `2021-11-12T23:00:00Z`
##### Scope
- **Targets:** Nudge
- **Limitations:** No Limitations
- **Exclusions:**
	- Testing: None

<img src="images/Nudge%20Configuration%20for%20Opt-in%20Beta%20Testers.png" width="900">


---

## General Resources

- [Feature Requests & Technical Issues](https://github.com/macadmins/nudge/issues)
- [MacAdmin's Slack](https://www.macadmins.org) #nudge
- [Creating Launch Daemons and Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
  - [Timed Jobs Using launchd](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html#//apple_ref/doc/uid/10000172i-CH1-SW1)

### Reference Images

Nudge's `userInterface : updateElements` Field Names (before deadline)
<img src="images/Field%20Names.png" width="900">

Nudge's `userInterface : updateElements` Field Names (deferral options disabled after deadline)
<img src="images/Field%20Names%20(deadline%20past).png" width="900">
