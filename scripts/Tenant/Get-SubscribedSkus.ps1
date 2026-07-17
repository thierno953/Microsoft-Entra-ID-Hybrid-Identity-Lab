Get-MgSubscribedSku |
Select-Object `
SkuPartNumber,
ConsumedUnits,
@{
Name="EnabledUnits"
Expression={$_.PrepaidUnits.Enabled}
}