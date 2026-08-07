function New-PodTrace {
    <#
        .SYNOPSIS
        Runs tcpdump on remote pod and writes the output to a local file.
        Open in Wireshark after the pod is killed or you kill the sniff execution
    #>
    [Alias('ksniff')]
    [CmdletBinding()]
    param(
        # Pod name to sniff
        [Parameter(Position = 0)]
        [string]$PodName,

        # Namespace of pod
        [Parameter(Position = 1)]
        [string]$Namespace

    )
    k sniff $PodName -n $Namespace -o "c:\tmp\$($PodName).tcpdump"
}