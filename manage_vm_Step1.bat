
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

REM Get the disk resource group (may be different from VM resource group)
echo Finding disk resource group...
for /f %%i in ('az disk list --query "[?name=='%OS_DISK_NAME%'].resourceGroup" -o tsv') do set DISK_RESOURCE_GROUP=%%i

if "%DISK_RESOURCE_GROUP%"=="" (
    echo Error: Could not find resource group for disk %OS_DISK_NAME%
    exit /b 1
)

echo Found disk in resource group: %DISK_RESOURCE_GROUP%

REM Get the full disk resource ID
echo Getting disk resource ID...
for /f %%i in ('az disk show --resource-group %DISK_RESOURCE_GROUP% --name %OS_DISK_NAME% --query "id" -o tsv') do set DISK_RESOURCE_ID=%%i

if "%DISK_RESOURCE_ID%"=="" (
    echo Error: Could not find disk resource ID for %OS_DISK_NAME%
    exit /b 1
)

echo Found disk resource ID: %DISK_RESOURCE_ID%

REM Create the snapshot
set SNAPSHOT_NAME=%VM_NAME%-snapshot-%TIMESTAMP%
echo Creating snapshot: %SNAPSHOT_NAME%

CALL az snapshot create --resource-group %RESOURCE_GROUP% --name %SNAPSHOT_NAME% --source %DISK_RESOURCE_ID% --output none
REM az snapshot wait

if %errorlevel% neq 0 (
    echo Failed to create snapshot!!!!!
    exit /b 1
) else (
    echo  created snapshot
)

echo Snapshot created successfully: %SNAPSHOT_NAME%

REM Create disk from snapshot
set DISK_NAME=%VM_NAME%-snapshot-disk-%TIMESTAMP%
echo Creating disk %DISK_NAME% from snapshot: %SNAPSHOT_NAME% 

CALL az disk create --resource-group %RESOURCE_GROUP% --name %DISK_NAME% --source %SNAPSHOT_NAME% --sku Standard_LRS --output none
REM az snapshot wait

if %errorlevel% equ 0 (
    echo Disk created successfully: %DISK_NAME%
    echo You can now use this disk to create a new VM
) else (
    echo Failed to create disk from snapshot
    exit /b 1
)

echo Created disk %DISK_NAME% from snapshot: %SNAPSHOT_NAME% successfully