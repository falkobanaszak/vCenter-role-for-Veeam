<#
.SYNOPSIS
    New_vCenterRole_Veeam.ps1 - PowerShell Script to create a new vCenter Role with all the required permission for Veeam Backup & Replication. 
.DESCRIPTION
    This script is used to create a new role on your vCenter server.
    The newly created role will be filled with the needed permissions for using it with Veeam Backup & Replication
    The permissions are based on the Veeam Help Center Cumulative Permissions and can be found here: https://helpcenter.veeam.com/docs/backup/permissions/cumulativepermissions.html?ver=120
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Falko Banaszak, https://virtualhome.blog, Twitter: @Falko_Banaszak
    Contributor   Dean Lewis, https://veducate.co.uk, Twitter: @SaintDLE
    
    Change Log    V1.00, 21/04/2020 - Initial version: Creates a new vCenter role with privileges required for Veeam Backup & Replication operations
    Change Log    V2.00, 06/08/2021 - Second version: Updated the script to use the Veeam Backup & Replication Version 11 cumulative privileges
    Change Log    V2.01, 07/10/2021 - Second version revision: Add missing "VirtualMachine.Config.Annotation"
    Change Log    V3.00, 07/15/2023 - Updated code for better error handling, added ability to check if role exists and add missing permissions to existing role, added ability to add user to new role
    
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

# Here are all necessary and cumualative vCenter Privileges needed for all operations of Veeam Backup & Replication V12
$VeeamPrivileges = @(
    'Cryptographer.Access',
'Cryptographer.AddDisk',
'Cryptographer.Encrypt',
'Cryptographer.EncryptNew',
'Cryptographer.Migrate',
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
'Network.Assign',
'Network.Config',
'Resource.AssignVMToPool',
'Resource.ColdMigrate',
'Resource.CreatePool',
'Resource.DeletePool',
'Resource.HotMigrate',
'StoragePod.Config',
'StorageProfile.Update',
'StorageProfile.View',
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

# Load the PowerCLI SnapIn and set the configuration
if (!(Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
    Add-PSSnapin VMware.VimAutomation.Core
}
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Get the vCenter Server Name to connect to
$vCenterServer = Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)"

# Get User to connect to vCenter Server
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"

# Get Password to connect to the vCenter Server
$vCenterUserPassword = Read-Host "Enter your password (no worries it is a secure string)" -AsSecureString:$true

# Collect username and password as credentials
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

# Connect to the vCenter Server with collected credentials
if(!(Connect-VIServer -Server $vCenterServer -Credential $Credentials -ErrorAction Silently)) {
    Write-Host "Error: Could not connect to vCenter server $vCenterServer" -ForegroundColor Red
    exit 1
}
Write-Host "Connected to your vCenter server $vCenterServer" -ForegroundColor Green

# Provide a name for your new role
$NewRole = Read-Host "Enter your desired name for the new vCenter role"

# Check if the role already exists
$existingRole = Get-VIRole -Name $NewRole -ErrorAction SilentlyContinue
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
            # Add the missing privileges to the role
            $rolePrivileges = $existingRole.PrivilegeList + $missingPrivileges
            Set-VIRole -Role $existingRole -AddPrivilege (Get-VIPrivilege -Id $rolePrivileges) | Out-Null
            Write-Host "The missing privileges have been added to the role $NewRole." -ForegroundColor Green
        } else {
            Write-Host "The missing privileges have not been added to the role $NewRole." -ForegroundColor Yellow
        }
    } else {
        Write-Host "The role $NewRole already has all the required privileges." -ForegroundColor Green
    }
    
    # Exit the script since the user chose not to add the missing privileges or there were no missing privileges
    exit 1
}

Write-Host "Thanks, your new vCenter role will be named $NewRole" -ForegroundColor Green

# Creating the new role with the needed permissions
New-VIRole -Name $NewRole -Privilege (Get-VIPrivilege -Id $VeeamPrivileges) | Out-Null
Write-Host "Your new vCenter role has been created, here it is:" -ForegroundColor Green
Get-VIRole -Name $NewRole | Select-Object Description, PrivilegeList, Server, Name | Format-List

# Ask if a user should be assigned to the role
$assignUser = Read-Host "Do you want to assign a user to the role $NewRole, this be be added at the root level of vCenter? (yes/no)"
if ($assignUser -eq "yes") {
    # Get the user information
    $userName = Read-Host "Enter the user name (DOMAIN\User or user@domain.com)"

    # Assign the user to the role
    New-VIPermission -Entity (Get-Folder "Datacenters" -Type Datacenter | Where { $_.ParentId -eq $null }) -Principal $userName -Role $NewRole -Propagate:$true
    Write-Host "The user $userName has been assigned to the role $NewRole." -ForegroundColor Green
}

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer - have a Veeamazing day :)" -ForegroundColor Green
