$inputPath = "$env:homeshare\VDI-UserData\Download\generic\inputs\"
$fileName = "mailbox_list.csv"
$allMailboxes = Get-Content "$inputPath\$fileName"

$sizeFieldName = "TotalItemSizeInGB"

$defaultProhibitSendReceiveQuota = "100GB"
$defaultRecoverableItemsQuota = "30GB"
$defaultRecoverableItemsWarningQuota = "20GB"

foreach ($mailbox in $allMailboxes) {
    $mailboxSizeGigaBytes =
        Get-MailboxStatistics -Identity $mailbox | `
        select @{
            Name = $sizeFieldName;
            Expression = {
                [math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "") / 1GB), 2)
            }
        } | `
        Select $sizeFieldName -ExpandProperty $sizeFieldName

    if ($mailboxSizeGigaBytes -eq 0) {
        $mailboxDesiredQuotaBytes = 2GB
    } elseif ($mailboxSizeGigaBytes % 1 -lt 0.5 -and $mailboxSizeGigaBytes % 1 -gt 0) {
        $mailboxDesiredQuotaBytes = ([math]::Round($mailboxSizeGigaBytes) + 1.5) * [math]::pow(2, 30)
    } else {
        $mailboxDesiredQuotaBytes = ([math]::Round($mailboxSizeGigaBytes) + 1) * [math]::pow(2, 30)
    }

    $movingProhibitSendQuota = $mailboxDesiredQuotaBytes
    $movingIssueWarningQuota = [math]::Round($mailboxDesiredQuotaBytes * 0.9)

    Set-Mailbox $mailbox `
        -UseDatabaseQuotaDefaults $false `
        -ProhibitSendQuota $movingProhibitSendQuota `
        -ProhibitSendReceiveQuota $defaultProhibitSendReceiveQuota `
        -RecoverableItemsQuota $defaultRecoverableItemsQuota `
        -RecoverableItemsWarningQuota $defaultRecoverableItemsWarningQuota `
        -IssueWarningQuota $movingIssueWarningQuota

    $archiveDatabase = (Get-Mailbox -Identity $mailbox).ArchiveDatabase
    $archiveGuid = (Get-Mailbox -Identity $mailbox).ArchiveGuid

    $hasArchive = ($archiveGuid -ne "00000000-0000-0000-0000-000000000000") -and $archiveDatabase

    if ($hasArchive) {
        $archiveSizeGigaBytes =
            Get-MailboxStatistics -Identity $mailbox -Archive | `
            select @{
                Name = $sizeFieldName;
                Expression = {
                    [math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "") / 1GB), 2)
                }
            } | `
            Select $sizeFieldName -ExpandProperty $sizeFieldName
    } else {
        $archiveSizeGigaBytes = 0
    }

    if ($archiveSizeGigaBytes -eq 0) {
        $archiveDesiredQuotaBytes = 5GB
    } elseif ($archiveSizeGigaBytes % 1 -lt 0.5 -and $archiveSizeGigaBytes % 1 -gt 0) {
        $archiveDesiredQuotaBytes = ([math]::Round($archiveSizeGigaBytes) + 5.5) * [math]::pow(2, 30)
    } else {
        $archiveDesiredQuotaBytes = ([math]::Round($archiveSizeGigaBytes) + 5) * [math]::pow(2, 30)
    }

    $movingArchiveQuota = $archiveDesiredQuotaBytes
    $movingArchiveWarningQuota = [math]::Round($archiveDesiredQuotaBytes * 0.9)

    Set-Mailbox $mailbox `
        -UseDatabaseQuotaDefaults $false `
        -ArchiveQuota $movingArchiveQuota `
        -ArchiveWarningQuota $movingArchiveWarningQuota
}
