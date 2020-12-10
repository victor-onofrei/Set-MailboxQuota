$migration_list = @()
$input_path = "$env:homeshare\VDI-UserData\Download\generic\inputs\"
$file_name = "mailbox_list.csv"
$all_mailboxes = Get-Content $input_path\$file_name

$default_ProhibitSendReceiveQuota = "100GB"
$default_RecoverableItemsQuota = "30GB"
$default_RecoverableItemsWarningQuota = "20GB"

foreach ($mailbox in $all_mailboxes) {
    $mailbox_size = Get-MailboxStatistics -Identity $mailbox | select @{Name="TotalItemSizeinGB";`
        Expression={[math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1GB),2)}}`
        | Select TotalItemSizeinGB -ExpandProperty TotalItemSizeinGB
    if ($mailbox_size -eq 0) {
        $desired_quota = 2GB 
    } elseif ($mailbox_size%1 -lt 0.5 -and $mailbox_size%1 -gt 0) {
        $desired_quota = ([math]::Round($mailbox_size)+1.5)*([math]::pow(2,30))
    } else { 
        $desired_quota = ([math]::Round($mailbox_size)+1)*([math]::pow(2,30))
    }
    $moving_ProhibitSendQuota = $desired_quota
    $moving_IssueWarningQuota = [int64]($desired_quota*0.9)
    Set-mailbox $mailbox -UseDatabaseQuotaDefaults $false -ProhibitSendQuota $moving_ProhibitSendQuota `
        -ProhibitSendReceiveQuota $default_ProhibitSendReceiveQuota -RecoverableItemsQuota `
        $default_RecoverableItemsQuota -RecoverableItemsWarningQuota $default_RecoverableItemsWarningQuota `
        -IssueWarningQuota $moving_IssueWarningQuota

    if ((Get-Mailbox -Identity $mailbox).ArchiveStatus -ne "None") {
        $archive_size = Get-MailboxStatistics -Identity $mailbox -Archive | select @{Name="TotalItemSizeinGB"; `
        Expression={[math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1GB),2)}}`
        | Select TotalItemSizeinGB -ExpandProperty TotalItemSizeinGB
        if ($archive_size%1 -lt 0.5 -and $archive_size%1 -gt 0) {
            $desired_quota = ([math]::Round($archive_size)+5.5)*([math]::pow(2,30))
        } else {
            $desired_quota = ([math]::Round($archive_size)+5)*([math]::pow(2,30))
        }
        $moving_ArchiveQuota = $desired_quota
        $moving_ArchiveWarningQuota = $desired_quota*0.9
        Set-mailbox $mailbox -UseDatabaseQuotaDefaults $false -ArchiveQuota $moving_ArchiveQuota -ArchiveWarningQuota `
                                                                                        $moving_ArchiveWarningQuota
    }       
}
