$inputPath = "$env:homeshare\VDI-UserData\Download\generic\inputs\"
$fileName = "mailbox_list.csv"
$allMailboxes = Get-Content "$inputPath\$fileName"

$sizeFieldName = "TotalItemSizeInGB"

$defaultProhibitSendReceiveQuota = "100GB"
$defaultRecoverableItemsQuota = "30GB"
$defaultRecoverableItemsWarningQuota = "20GB"

foreach ($mailbox in $allMailboxes) {
    $mailboxSize =
        Get-MailboxStatistics -Identity $mailbox | `
        select @{
            Name = $sizeFieldName; `
            Expression = {
                [math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "") / 1GB), 2)
            }
        } | `
        Select $sizeFieldName -ExpandProperty $sizeFieldName

    if ($mailboxSize -eq 0) {
        $desiredQuota = 2GB
    } elseif ($mailboxSize % 1 -lt 0.5 -and $mailboxSize % 1 -gt 0) {
        $desiredQuota = ([math]::Round($mailboxSize) + 1.5) * [math]::pow(2, 30)
    } else {
        $desiredQuota = ([math]::Round($mailboxSize) + 1) * [math]::pow(2, 30)
    }

    $movingProhibitSendQuota = $desiredQuota
    $movingIssueWarningQuota = [int64]($desiredQuota * 0.9)

    Set-Mailbox $mailbox `
        -UseDatabaseQuotaDefaults $false `
        -ProhibitSendQuota $movingProhibitSendQuota `
        -ProhibitSendReceiveQuota $defaultProhibitSendReceiveQuota `
        -RecoverableItemsQuota $defaultRecoverableItemsQuota `
        -RecoverableItemsWarningQuota $defaultRecoverableItemsWarningQuota `
        -IssueWarningQuota $movingIssueWarningQuota

    if ((Get-Mailbox -Identity $mailbox).ArchiveStatus -ne "None") {
        $archiveSize =
            Get-MailboxStatistics -Identity $mailbox -Archive | `
            select @{
                Name = $sizeFieldName; `
                Expression = {
                    [math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "") / 1GB), 2)
                }
            } | `
            Select $sizeFieldName -ExpandProperty $sizeFieldName

        if ($archiveSize % 1 -lt 0.5 -and $archiveSize % 1 -gt 0) {
            $desiredQuota = ([math]::Round($archiveSize) + 5.5) * [math]::pow(2, 30)
        } else {
            $desiredQuota = ([math]::Round($archiveSize) + 5) * [math]::pow(2, 30)
        }

        $movingArchiveQuota = $desiredQuota
        $movingArchiveWarningQuota = $desiredQuota * 0.9

        Set-Mailbox $mailbox `
            -UseDatabaseQuotaDefaults $false `
            -ArchiveQuota $movingArchiveQuota `
            -ArchiveWarningQuota $movingArchiveWarningQuota
    }
}
