<#
.SYNOPSIS
    New_vCenterRole_Veeam.ps1 - PowerShell Script to create a new vCenter Role with all the required permission for Veeam Backup & Replication.
.DESCRIPTION
    This script is used to create a new role on your vCenter server.
    The newly created role will be filled with the needed permissions for using it with Veeam Backup & Replication
    The permissions are based on the Veeam Help Center Cumulative Permissions and can be found here: https://helpcenter.veeam.com/docs/vbr/permissions/cumulativepermissions.html
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Falko Banaszak, https://virtualhome.blog, Twitter: @Falko_Banaszak
    Contributor   Dean Lewis, https://veducate.co.uk, Twitter: @SaintDLE
    Contributor   Rasmus Haslund, https://rasmushaslund.com, X: @haslund

    Change Log    V1.00, 21/04/2020 - Initial version: Creates a new vCenter role with privileges required for Veeam Backup & Replication operations
    Change Log    V2.00, 06/08/2021 - Second version: Updated the script to use the Veeam Backup & Replication Version 11 cumulative privileges
    Change Log    V2.01, 07/10/2021 - Second version revision: Add missing "VirtualMachine.Config.Annotation"
    Change Log    V3.00, 07/15/2023 - Updated code for better error handling, added ability to check if role exists and add missing permissions to existing role, added ability to add user to new role
    Change Log    V4.00, 07/07/2026 - Updated to VBR v13 cumulative permissions (added Cryptographer.RegisterVM, Resource.EditPool,
                                       StorageProfile.Apply/ViewPermissions, VirtualMachine.Inventory.CreateFromExisting);
                                       load PowerCLI as a module for PowerShell 5.1/7 support, detected via VMware.VimAutomation.Core
                                       so both VCF.PowerCLI and the legacy VMware.PowerCLI work; resolve privileges in bulk with
                                       per-ID fallback; hardened error handling around connect, role creation and permission
                                       assignment; disconnect only the session the script opened; fixed exit codes and messaging

.LICENSE
    MIT License
    Copyright (c) 2019 Falko Banaszak
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>

#Requires -Version 5.1

# Here are all necessary and cumulative vCenter Privileges needed for all operations of Veeam Backup & Replication V13.
# Note: some privilege IDs only exist on specific vSphere versions (see inline comments). The script resolves each
# privilege individually and skips any that do not exist on the connected vCenter, so an unsupported ID is a warning,
# not a fatal error.
$VeeamPrivileges = @(
'Cryptographer.Access',
'Cryptographer.AddDisk',
'Cryptographer.Encrypt',
'Cryptographer.EncryptNew',
'Cryptographer.Migrate',
'Cryptographer.RegisterVM',
'DVPortgroup.Create',
'DVPortgroup.Delete',
'DVPortgroup.Modify',
'Datastore.AllocateSpace',
'Datastore.Browse',
'Datastore.Config',
'Datastore.DeleteFile',
'Datastore.FileManagement',
'Extension.Register',
'Extension.Unregister',
'Folder.Create',
'Folder.Delete',
'Global.Diagnostics',
'Global.DisableMethods',
'Global.EnableMethods',
'Global.Licenses',
'Global.LogEvent',
'Global.ManageCustomFields',
'Global.SetCustomField',
'Global.Settings',
'Host.Config.AdvancedConfig',
'Host.Config.Maintenance',
'Host.Config.Network',
'Host.Config.Patch',
'Host.Config.Storage',
'InventoryService.Tagging.AttachTag',
'InventoryService.Tagging.ObjectAttachable',
'Network.Assign',
'Network.Config',
'Resource.AssignVMToPool',
'Resource.ColdMigrate',
'Resource.CreatePool',
'Resource.DeletePool',
'Resource.EditPool',
'Resource.HotMigrate',
'StoragePod.Config',
'StorageProfile.Apply',            # vSphere 8.x and later
'StorageProfile.Update',
'StorageProfile.View',
'StorageProfile.ViewPermissions',  # vSphere 8.x and later
'System.Anonymous',
'System.Read',
'System.View',
'VApp.AssignResourcePool',
'VApp.AssignVM',
'VApp.Unregister',
'VirtualMachine.Config.AddExistingDisk',
'VirtualMachine.Config.AddNewDisk',
'VirtualMachine.Config.AddRemoveDevice',
'VirtualMachine.Config.AdvancedConfig',
'VirtualMachine.Config.Annotation',
'VirtualMachine.Config.ChangeTracking',
'VirtualMachine.Config.DiskExtend',
'VirtualMachine.Config.DiskLease',
'VirtualMachine.Config.EditDevice',
'VirtualMachine.Config.RawDevice',
'VirtualMachine.Config.RemoveDisk',
'VirtualMachine.Config.Rename',
'VirtualMachine.Config.Resource',
'VirtualMachine.Config.Settings',
'VirtualMachine.GuestOperations.Execute',
'VirtualMachine.GuestOperations.Modify',
'VirtualMachine.GuestOperations.Query',
'VirtualMachine.Interact.ConsoleInteract',
'VirtualMachine.Interact.DeviceConnection',
'VirtualMachine.Interact.GuestControl',
'VirtualMachine.Interact.PowerOff',
'VirtualMachine.Interact.PowerOn',
'VirtualMachine.Interact.SetCDMedia',
'VirtualMachine.Interact.SetFloppyMedia',
'VirtualMachine.Interact.Suspend',
'VirtualMachine.Inventory.Create',
'VirtualMachine.Inventory.CreateFromExisting',  # vSphere 9.x and later
'VirtualMachine.Inventory.Delete',
'VirtualMachine.Inventory.Register',
'VirtualMachine.Inventory.Unregister',
'VirtualMachine.Inventory.Move',
'VirtualMachine.Provisioning.DiskRandomAccess',
'VirtualMachine.Provisioning.DiskRandomRead',
'VirtualMachine.Provisioning.GetVmFiles',
'VirtualMachine.Provisioning.MarkAsTemplate',
'VirtualMachine.Provisioning.MarkAsVM',
'VirtualMachine.Provisioning.PutVmFiles',
'VirtualMachine.State.CreateSnapshot',
'VirtualMachine.State.RemoveSnapshot',
'VirtualMachine.State.RenameSnapshot',
'VirtualMachine.State.RevertToSnapshot')

# Resolve a list of privilege IDs into privilege objects. Tries a single bulk lookup first (fast); if that
# fails because one or more IDs do not exist on this vCenter (e.g. version-specific privileges), it falls back
# to resolving each ID individually and skips the missing ones with a warning.
function Resolve-VeeamPrivilege {
    param(
        [Parameter(Mandatory = $true)][string[]]$Ids,
        [Parameter(Mandatory = $true)]$Server
    )

    try {
        return Get-VIPrivilege -Id $Ids -Server $Server -ErrorAction Stop
    }
    catch {
        Write-Warning "Some privileges could not be resolved in bulk; falling back to individual resolution."
        $resolved = foreach ($id in $Ids) {
            try {
                Get-VIPrivilege -Id $id -Server $Server -ErrorAction Stop
            }
            catch {
                Write-Warning "Privilege not available on this vCenter, skipping: $id"
            }
        }
        return $resolved
    }
}

# Load VMware PowerCLI (module-based; PSSnapins are no longer supported in modern PowerCLI / PowerShell 7).
# The meta-module was renamed VMware.PowerCLI -> VCF.PowerCLI (VCF PowerCLI 9.0+, 2025). Both provide the
# VMware.VimAutomation.Core module used below, so we check/import that directly rather than the meta-module name.
if (-not (Get-Module -ListAvailable -Name VMware.VimAutomation.Core)) {
    Write-Host "Error: VMware PowerCLI is not installed. Install it with: Install-Module VCF.PowerCLI -Scope CurrentUser (or the legacy VMware.PowerCLI)." -ForegroundColor Red
    exit 1
}
try {
    Import-Module VMware.VimAutomation.Core -ErrorAction Stop
}
catch {
    Write-Host "Error: Could not load VMware PowerCLI. $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Ignore invalid certificates for this session only (does not persist to the user's PowerCLI configuration)
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null

# Get the vCenter Server Name to connect to
$vCenterServer = (Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)").Trim()
if ([string]::IsNullOrWhiteSpace($vCenterServer)) {
    Write-Host "Error: vCenter Server host name cannot be empty." -ForegroundColor Red
    exit 1
}

# Get User to connect to vCenter Server
$vCenterUser = (Read-Host "Enter your user name (DOMAIN\User or user@domain.com)").Trim()
if ([string]::IsNullOrWhiteSpace($vCenterUser)) {
    Write-Host "Error: User name cannot be empty." -ForegroundColor Red
    exit 1
}

# Get Password to connect to the vCenter Server
$vCenterUserPassword = Read-Host "Enter your password (no worries it is a secure string)" -AsSecureString:$true

# Collect username and password as credentials
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser, $vCenterUserPassword

# Connect to the vCenter Server with collected credentials (capture the connection object so we only
# disconnect the session this script opened, leaving any pre-existing connections intact)
$viConnection = $null
try {
    $viConnection = Connect-VIServer -Server $vCenterServer -Credential $Credentials -ErrorAction Stop
}
catch {
    Write-Host "Error: Could not connect to vCenter server $vCenterServer. $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host "Connected to your vCenter server $vCenterServer" -ForegroundColor Green

# Everything from here on runs against a live connection - wrap in try/finally so the session is always closed
$completedSuccessfully = $false
try {
    # Provide a name for your new role
    $NewRole = (Read-Host "Enter your desired name for the new vCenter role").Trim()
    if ([string]::IsNullOrWhiteSpace($NewRole)) {
        Write-Host "Error: Role name cannot be empty." -ForegroundColor Red
        exit 1
    }

    # Check if the role already exists
    $existingRole = Get-VIRole -Name $NewRole -Server $viConnection -ErrorAction SilentlyContinue
    if ($existingRole) {
        Write-Host "A role with the name $NewRole already exists." -ForegroundColor Yellow

        # Get the current privileges of the role
        $currentPrivileges = $existingRole.PrivilegeList | Sort-Object

        # Compare the current privileges with the required privileges
        $missingPrivileges = $VeeamPrivileges | Where-Object { $_ -notin $currentPrivileges }

        if ($missingPrivileges) {
            Write-Host "The role $NewRole is missing the following privileges:" -ForegroundColor Yellow
            Write-Host ($missingPrivileges -join "`n")

            # Ask the user whether they want to add the missing privileges
            $choice = Read-Host "Do you want to add the missing privileges to the role $NewRole? (yes/no)"
            if ($choice -eq "yes") {
                # Resolve and add ONLY the missing privileges to the role
                $privilegesToAdd = Resolve-VeeamPrivilege -Ids $missingPrivileges -Server $viConnection
                if ($privilegesToAdd) {
                    try {
                        Set-VIRole -Role $existingRole -AddPrivilege $privilegesToAdd -ErrorAction Stop | Out-Null
                        Write-Host "The missing privileges have been added to the role $NewRole." -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Error: Could not add privileges to the role $NewRole. $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "None of the missing privileges could be resolved on this vCenter; nothing was added." -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "The missing privileges have not been added to the role $NewRole." -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "The role $NewRole already has all the required privileges." -ForegroundColor Green
        }
    }
    else {
        Write-Host "Thanks, your new vCenter role will be named $NewRole" -ForegroundColor Green

        # Creating the new role with the needed permissions
        $privilegesToSet = Resolve-VeeamPrivilege -Ids $VeeamPrivileges -Server $viConnection
        if (-not $privilegesToSet) {
            Write-Host "Error: No required privileges could be resolved on this vCenter; the role was not created." -ForegroundColor Red
            exit 1
        }
        try {
            New-VIRole -Name $NewRole -Privilege $privilegesToSet -Server $viConnection -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Host "Error: Could not create the role $NewRole. $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
        Write-Host "Your new vCenter role has been created, here it is:" -ForegroundColor Green
        Get-VIRole -Name $NewRole -Server $viConnection | Select-Object Description, PrivilegeList, Server, Name | Format-List

        # Ask if a user should be assigned to the role
        $assignUser = Read-Host "Do you want to assign a user to the role $NewRole? This will be added at the root level of vCenter. (yes/no)"
        if ($assignUser -eq "yes") {
            # Get the user information
            $userName = (Read-Host "Enter the user name (DOMAIN\User or user@domain.com)").Trim()
            if ([string]::IsNullOrWhiteSpace($userName)) {
                Write-Host "Error: User name cannot be empty; no permission was assigned." -ForegroundColor Red
            }
            else {
                # Locate the vCenter root (Datacenters folder) - there should be exactly one
                $rootFolder = Get-Folder "Datacenters" -Type Datacenter -Server $viConnection -ErrorAction SilentlyContinue | Where-Object { $null -eq $_.ParentId }
                if (-not $rootFolder -or @($rootFolder).Count -ne 1) {
                    Write-Host "Error: Could not unambiguously locate the vCenter root folder; no permission was assigned." -ForegroundColor Red
                }
                else {
                    # Assign the user to the role
                    try {
                        New-VIPermission -Entity $rootFolder -Principal $userName -Role $NewRole -Server $viConnection -Propagate:$true -ErrorAction Stop | Out-Null
                        Write-Host "The user $userName has been assigned to the role $NewRole." -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Error: Could not assign user $userName to the role $NewRole. $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
        }
    }

    # All work completed without a fatal error
    $completedSuccessfully = $true
}
finally {
    # Disconnect only the session this script opened; leave any pre-existing connections intact
    if ($viConnection) {
        Disconnect-VIServer -Server $viConnection -Confirm:$false -ErrorAction SilentlyContinue
        if ($completedSuccessfully) {
            Write-Host "Disconnected from your vCenter Server $vCenterServer - have a Veeamazing day :)" -ForegroundColor Green
        }
        else {
            Write-Host "Disconnected from your vCenter Server $vCenterServer." -ForegroundColor Yellow
        }
    }
}
