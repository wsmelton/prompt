function Get-PopeyeReport {
    if (Get-Command popeye -ErrorAction SilentlyContinue) {
        try {
            $env:POPEYE_REPORT_DIR = $env:temp
            popeye -A -c -o 'html'
        }
        catch {
            throw "Issue running popeye: $($_)"
        }
    }
}