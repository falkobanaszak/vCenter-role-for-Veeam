# Creating a new vCenter server role with cumulative privileges and permissions to use with Veeam Backup & Replication

This PowerShell / PowerCLI script lets you create a new vCenter server role with all the cumulative privileges and permissions required to use it with Veeam Backup & Replication (v13).

The privileges are based on the recommendations from the Veeam Help Center, which you can find here:
[Cumulative Permissions for VMware vSphere - Veeam Help Center](https://helpcenter.veeam.com/docs/vbr/permissions/cumulativepermissions.html)

## Requirements
- Windows PowerShell 5.1 or PowerShell 7.x
- VMware PowerCLI - install the current meta-module `VCF.PowerCLI` (`Install-Module VCF.PowerCLI -Scope CurrentUser`). The legacy `VMware.PowerCLI` module (now deprecated) also works; the script loads the `VMware.VimAutomation.Core` component, which both packages provide.
- A vCenter Server account allowed to create roles and assign permissions

## Usage
Execute the script and follow the prompts: your vCenter server name, username, and password. The script then asks you to choose a name for the new role and creates it automatically. If the role already exists, the script checks for missing privileges and prompts whether to add them. Finally, you can optionally assign a user to the role at the vCenter root level.

Privileges that don't exist on your vCenter version (for example vSphere 9.x-only IDs on an older server) are skipped with a warning instead of failing the whole run.

![Example execution of the script](/vCenter-role-for-Veeam-Output.png)

Feel free to give me feedback on this script, as I want to further improve it.

## Recent Improvements
 - [X] Updated to Veeam Backup & Replication v13 cumulative permissions
 - [X] PowerShell 5.1 and 7.x support (module-based PowerCLI loading)
 - [X] Compatible with both `VCF.PowerCLI` and the legacy `VMware.PowerCLI`
 - [X] Hardened error handling and guaranteed vCenter session cleanup
 - [X] Resilient per-privilege resolution (skips IDs not present on the connected vCenter)
 - [X] Add a function to assign a user to the role
 - [X] Add a function to check against an existing role, print the missing privileges and let the user decide to apply the missing privileges to the already existing role

You can get the script here: [New_vCenterRole_Veeam.ps1](/New_vCenterRole_Veeam.ps1)

Successfully tested against:
- VMware vCenter 6.5
- VMware vCenter 6.7
- VMware vCenter 7.0
- VMware vCenter 8.0
- Veeam Backup & Replication Version 10
- Veeam Backup & Replication Version 11
- Veeam Backup & Replication Version 12
- Veeam Backup & Replication Version 13
