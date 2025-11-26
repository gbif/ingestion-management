$datasettitle = $args[0]
$datasetkey = $args[1]
$email = $args[2]

# Check if Outlook is running
$outlookProcess = Get-Process Outlook -ErrorAction SilentlyContinue

if ($null -eq $outlookProcess) {
    # Outlook is not running, start it
    try {
        Start-Process "OUTLOOK.EXE"
        Write-Host "Outlook has been started."
    } catch {
        Write-Error "Failed to start Outlook. Please make sure Outlook is installed."
    }
} else {
    # Outlook is already running
    Write-Host "Outlook is already running."
}


$Outlook = New-Object -ComObject Outlook.Application
# check sending account 
$namespace = $Outlook.GetNameSpace("MAPI")
$defaultAccount = $namespace.Accounts | Where-Object { $_.SmtpAddress -eq $Outlook.Session.Accounts.Item(1).SmtpAddress }
$defaultAccount.DisplayName

$Mail = $Outlook.CreateItem(0)
$Mail.Recipients.Add("$email")
$Mail.SentOnBehalfOfName = "helpdesk@gbif.org"
$mail.CC = "helpdesk@gbif.org"  # CC recipient
$Mail.Subject = "GBIF - $datasettitle successful occurrenceId migration"
$Mail.HTMLBody = @"
<html>
<head>
<title>occurrenceId migration successful</title>
</head>
<body>
    <p>Hello,</p>
	<p></p>
    <p>The occurrenceIds for the $datasettitle : <a href=https://www.gbif.org/dataset/$datasetkey>https://www.gbif.org/dataset/$datasetkey</a> have been successfully migrated.</p>
    <p></p>
	<p>The new version of your dataset will now retain its old gbifids. </p>
    <p></p>
    <p>No further action is required on your part. </p>
    <p></p>
	<p>Thank you for helping with occurrenceId and gbifid stability!</p>
    <p>All the best,</p>
	<p>John Waller<br>
       Data Analyst<br>
       GBIF Secretariat<br>
       Universitetsparken 15<br>
       2100 Copenhagen<br>
       Denmark<br>
       e-mail: <a href="mailto:jwaller@gbif.org">jwaller@gbif.org</a>
    </p>
</body>
</html>
"@
# $Mail.HTMLBody
# $datasettitle
# $datasetkey
# $email
$Mail.Save()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null

# $Mail.Send()
