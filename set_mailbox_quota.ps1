$inputpath = "$env:homeshare\VDI-UserData\Download\generic\inputs\"
$filename = "mailbox_list.csv"
$allmailboxes = Get-Content $inputpath\$filename

$defaultProhibitSendReceiveQuota = "100GB"
$defaultRecoverableItemsQuota = "30GB"
$defaultRecoverableItemsWarningQuota = "20GB"

foreach ($mailbox in $allmailboxes) {
    $mailboxsize = Get-MailboxStatistics -Identity $mailbox | select @{Name="TotalItemSizeinGB"; `
    Expression={[math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1GB),2)}} | `
     Select TotalItemSizeinGB -ExpandProperty TotalItemSizeinGB
    if ($mailboxsize -eq 0) {
        $desiredquota = 2GB 
    } elseif ($mailboxsize%1 -lt 0.5 -and $mailboxsize%1 -gt 0) {
        $desiredquota = ([math]::Round($mailboxsize)+1.5)*([math]::pow(2,30))
    } else { 
        $desiredquota = ([math]::Round($mailboxsize)+1)*([math]::pow(2,30))
    }
    $movingProhibitSendQuota = $desiredquota
    $movingIssueWarningQuota = [int64]($desiredquota*0.9)
    Set-mailbox $mailbox -UseDatabaseQuotaDefaults $false -ProhibitSendQuota $movingProhibitSendQuota `
        -ProhibitSendReceiveQuota $defaultProhibitSendReceiveQuota -RecoverableItemsQuota `
        $defaultRecoverableItemsQuota -RecoverableItemsWarningQuota $defaultRecoverableItemsWarningQuota `
        -IssueWarningQuota $movingIssueWarningQuota

    if ((Get-Mailbox -Identity $mailbox).ArchiveStatus -ne "None") {
        $archive_size = Get-MailboxStatistics -Identity $mailbox -Archive | select @{Name="TotalItemSizeinGB"; `
        Expression={[math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1GB),2)}} | `
         Select TotalItemSizeinGB -ExpandProperty TotalItemSizeinGB
        if ($archive_size%1 -lt 0.5 -and $archive_size%1 -gt 0) {
            $desiredquota = ([math]::Round($archive_size)+5.5)*([math]::pow(2,30))
        } else {
            $desiredquota = ([math]::Round($archive_size)+5)*([math]::pow(2,30))
        }
        $movingArchiveQuota = $desiredquota
        $movingArchiveWarningQuota = $desiredquota*0.9
        Set-mailbox $mailbox -UseDatabaseQuotaDefaults $false -ArchiveQuota $movingArchiveQuota -ArchiveWarningQuota `
                                                                                        $movingArchiveWarningQuota
    }       
}
