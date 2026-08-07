function Deploy-PSContainer {
    [Alias('krps')]
    [CmdletBinding()]
    param()
    k run -it --rm aks-pwsh --image=mcr.microsoft.com/powershell:latest -n default
}