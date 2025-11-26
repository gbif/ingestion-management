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
$Mail.Subject = "GBIF - $datasettitle ingestion paused due to occurrenceID changes"
$Mail.HTMLBody = @"
<html>
<head>
<title>GBIF Dataset Inquiry</title>
</head>
<body>
    <p>Hello,</p>
	<p></p>
    <p>I am contacting you from the GBIF Secretariat about the dataset $datasettitle : <a href=https://www.gbif.org/dataset/$datasetkey>https://www.gbif.org/dataset/$datasetkey</a>.</p>
    <p></p>
	<p>We noticed that the occurrenceIDs were changed. We have temporarily paused the ingestions of this dataset.</p>
    <p></p>
	<p>As you might already know, when an occurrence record has a new occurrenceID for a given dataset, our system considers it to be a new occurrence. This means that it will be given a new gbifid and a new occurrence URL (like this one: <a href="https://www.gbif.org/occurrence/1252968762">https://www.gbif.org/occurrence/1252968762</a>) and the old gbifid and URL will be deprecated.</p>
    <p>In this case, this means that the occurrence URLs would be deprecated when ingesting the newest versions of these datasets.</p>
    <p></p>
	<p>We would like to check with you if those changes were intentional. Do you know if this is the case? Please let us know, thanks! We are happy to resume the dataset ingestion.</p>
    <p>Note that some users rely on those occurrence URLs and gbifids (like <a href="https://bionomia.net">https://bionomia.net</a> for example). In an attempt to improve the stability of the occurrence URLs and gbifids, we have implemented a warning system to detect these type of changes in datasets (see this news item). If the data publisher can provide us with a list of old and new occurrenceIDs per record, we can avoid the identifier and URL changes. Could that be an option?</p>
    <p></p>
	<p>If you know that the occurrenceIDs were changed intentionally, then you can consult this guide : <a href="https://github.com/gbif/ingestion-management/wiki/Advice-for-publishers">https://github.com/gbif/ingestion-management/wiki/Advice-for-publishers</a></p>
    <p></p>
	<p>Please let us know if you have any question. Thanks!</p>
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
