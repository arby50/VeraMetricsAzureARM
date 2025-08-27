REM Generate timestamp
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,8%-%datetime:~8,6%

echo Creating snapshot for VM: %VM_NAME%

REM Login to Azure (will prompt for authentication)
az login

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