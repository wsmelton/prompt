function CanUsePredictionSource {
return (! [System.Console]::IsOutputRedirected) -and (IsVirtualTerminalProcessingEnabled)
}