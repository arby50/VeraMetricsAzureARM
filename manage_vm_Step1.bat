
@echo off
REM Simple Azure VM Disk Snapshot Script
REM Usage: manage_vm_Step1.bat [vm-name]

set VM_NAME=%1

if "%VM_NAME%"=="" (
    echo Usage: %0 [vm-name]
    echo Example: %0 myTestApp20250825i-vm
    exit /b 1
)

REM Check who is logged in to Azure
echo Checking Azure login status...
for /f "tokens=*" %%i in ('az account show --query "user.name" -o tsv 2^>nul') do set AZURE_USER=%%i

if "%AZURE_USER%"=="" (
    echo Error: Not logged in to Azure CLI. Please run 'az login' first.
    exit /b 1
)

echo You are logged in to Azure as: %AZURE_USER%
set /p CONTINUE="Do you wish to continue? (y/N): "
if /i not "%CONTINUE%"=="y" (
    echo Operation cancelled.
    exit /b 0
)

REM Generate timestamp
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,8%-%datetime:~8,6%

echo Creating snapshot for VM: %VM_NAME%

REM Get the resource group and OS disk from the VM
echo Getting VM information...
for /f %%i in ('az vm list --query "[?name=='%VM_NAME%'].resourceGroup" -o tsv') do set RESOURCE_GROUP=%%i

if "%RESOURCE_GROUP%"=="" (
    echo Error: Could not find VM %VM_NAME%
    exit /b 1
)

echo Found VM in resource group: %RESOURCE_GROUP%

for /f %%i in ('az vm show --resource-group %RESOURCE_GROUP% --name %VM_NAME% --query "storageProfile.osDisk.name" -o tsv') do set OS_DISK_NAME=%%i

if "%OS_DISK_NAME%"=="" (
    echo Error: Could not find OS disk for VM %VM_NAME%
    exit /b 1
)

echo Found OS disk: %OS_DISK_NAME%

REM Create the snapshot
set SNAPSHOT_NAME=%VM_NAME%-snapshot-%TIMESTAMP%
echo Creating snapshot: %SNAPSHOT_NAME%

az snapshot create --resource-group %RESOURCE_GROUP% --name %SNAPSHOT_NAME% --source %OS_DISK_NAME%

if %errorlevel% equ 0 (
    echo ✅ Snapshot created successfully: %SNAPSHOT_NAME%
    echo You can now use this snapshot to create a new disk or restore the VM
) else (
    echo ❌ Failed to create snapshot
    exit /b 1
)
