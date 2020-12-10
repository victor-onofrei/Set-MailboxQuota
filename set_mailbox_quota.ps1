$migration_list = @()
$inputpath = "$env:homeshare\VDI-UserData\Download\generic\inputs\mailbox_list.csv"
$allmailbox = Get-Content $inputpath

$default_ProhibitSendReceiveQuota = "100GB"
$default_RecoverableItemsQuota = "30GB"
$default_RecoverableItemsWarningQuota = "20GB"

foreach ($mailbox in $allmailbox) 
{
    $mailboxsize = Get-MailboxStatistics -Identity $mailbox | select @{name="TotalItemSizeinGB"; expression={[math]::Round( `
    ($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1GB),2)}} | select TotalItemSizeinGB -ExpandProperty TotalItemSizeinGB
    if ($mailboxsize -eq 0) {
       $desired_quota = 2GB 
    } elseif ($mailboxsize%1 -lt 0.5 -and $mailboxsize%1 -gt 0) {
       $desired_quota = ([math]::Round($mailboxsize)+1.5)*([math]::pow(2,30))
    }
    else { 
        $desired_quota = ([math]::Round($mailboxsize)+1)*([math]::pow(2,30))
    }
    $moving_ProhibitSendQuota = $desired_quota
    $moving_IssueWarningQuota = [int64]($desired_quota*0.9)
    Set-mailbox $mailbox -UseDatabaseQuotaDefaults $false -ProhibitSendQuota $moving_ProhibitSendQuota -ProhibitSendReceiveQuota $default_ProhibitSendReceiveQuota -RecoverableItemsQuota $default_RecoverableItemsQuota -RecoverableItemsWarningQuota $default_RecoverableItemsWarningQuota -IssueWarningQuota $moving_IssueWarningQuota

    if ((Get-Mailbox -Identity $mailbox).ArchiveStatus -ne "None") {
    $archivesize = Get-MailboxStatistics -Identity $mailbox -Archive | select @{name="TotalItemSizeinGB"; expression={[math]::Round( `
    ($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1GB),2)}} | select TotalItemSizeinGB -ExpandProperty TotalItemSizeinGB
    if ($archivesize%1 -lt 0.5 -and $archivesize%1 -gt 0) {
       $desired_quota = ([math]::Round($archivesize)+5.5)*([math]::pow(2,30))
    }
    else {
        $desired_quota = ([math]::Round($archivesize)+5)*([math]::pow(2,30))
    }
    $moving_ArchiveQuota = $desired_quota
    $moving_ArchiveWarningQuota = $desired_quota*0.9
    Set-mailbox $mailbox -UseDatabaseQuotaDefaults $false -ArchiveQuota $moving_ArchiveQuota -ArchiveWarningQuota $moving_ArchiveWarningQuota
    }       
}
