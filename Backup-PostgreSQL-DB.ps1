<# 
This script was created to automate the backup of DB's in PostgreSQL using Windows scheduled tasks
Credit to persons who shared parts of this code helping to speed up the creation of this script without re-inventing the wheel or the code in this case ;)
Use at your own discretion.
My use case was to backup VMware Cloud Director DB's keeping it simple. Room for improvement is and tunning is there
#>

##### Create file to store password into profile of account that will execute the manual tasks/scheduled tasks
# Path for password file
$AccountFile = "$env:HOMEPATH\Account.User.pwd"

# Check for password file
if ((Test-Path $AccountFile) -eq "True") {
Write-Host "The file $AccountFile exist. Skipping credential request"
}
else {
Write-Host ("The value $AccountFile not found," +
" creating credentials file.")

# Create credential object by prompting user for data. Only the password is used. For user name use $username.  As per post https://stackoverflow.com/questions/13992772/how-do-i-avoid-saving-usernames-and-passwords-in-powershell-scripts
$Credential = Get-Credential

# Encrypt the password to disk
$Credential.Password | ConvertFrom-SecureString | Out-File $env:HOMEPATH\Account.User.pwd
}

##### Read password for DBhost login #####
# Read password from file
$SecureString = Get-Content $AccountFile | ConvertTo-SecureString

# Create credential object programmatically
$NewCred = New-Object System.Management.Automation.PSCredential("Account",$SecureString)

# Variable for postgres password in clear text
$env:PGPASSWORD = $NewCred.GetNetworkCredential().Password

##### Job configuration #####

$DBhost = "XXXX"
$port = "5432"
# Username used for backup task
$username = "XXX"
$role = "XX"
# Parameters for backup job
$format = "t" # t for TAR file
$DBnamesarray = @('vcloud')
$dumpFilePath = "D:\\POSTGRESQLBACKUP\\vcloud\\"
$date = get-date -format MMMM-dd-yyyy-HH-mm-
# Email configuration
$SmtpServer = "1.2.3.4"
$mailFrom = "PostgresBackup@lab.local"
$mailTo = "mon@lab.local"
$mailSubject = "VCD PostgreSQL Backup logs"
$mailBody = "Transcript of executed job atteched. Powered by BakingClouds - Guillermo Ramallo"

# pg_dump path
cd "C:\Program Files (x86)\pgAdmin 4\v4\runtime\"

##### Run backup task - Don't edit below this line #####

foreach ($DB in $DBnamesarray) {
$wrapFileName = $dumpFilePath+$date+($DB+".tar")
Start-Transcript $env:HOMEPATH\$date+$DB".log"
Write-Host "Ruuning job for $DB"
.\pg_dump.exe --file "$wrapFileName" --host $DBhost --port $port --username $username --verbose --role $role --format=$format --blobs $DB
Stop-Transcript
Send-MailMessage -Attachments $env:HOMEPATH\$date+$DB".log" -SmtpServer $SmtpServer -From $mailFrom -To $mailTo -Subject $mailSubject
}