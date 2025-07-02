# $textFile = 'C:\Program Files\windows_exporter\textfile_inputs\playnite.prom'
$textFile = 'C:\ProgramData\scoop\apps\windows_exporter\current\textfile_inputs\playnite.prom'
$minPlay = 300

function CalculateMetrics() {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        $game
    )
    Begin {
        $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -replace '([\\"])', '\$1'
        $__logger.Info("Updating metrics for user: $user")
        "# HELP playnite_game_total Total games."
        "# TYPE playnite_game_total gauge"
        "# HELP playnite_game_played_total Total games with at least 5 minutes of play time."
        "# TYPE playnite_game_played_total gauge"
        "# HELP playnite_game_sessions Single game number of game sessions."
        "# TYPE playnite_game_sessions gauge"
        "# HELP playnite_game_playtime_seconds Single game playtime in seconds."
        "# TYPE playnite_game_playtime_seconds gauge"
        "# HELP playnite_game_playtime_seconds_total Total playtime in seconds."
        "# TYPE playnite_game_playtime_seconds_total gauge"
        $sourceStats = @{}
    }
    Process {
        $source = $game.Source
        if ([string]::IsNullOrEmpty($source)) {
            $source = "Unknown"
        }
        $name = $game.Name -replace '([\\"])', '\$1'
        if (-not $sourceStats.ContainsKey($source)) {
            $sourceStats[$source] = @{ total = 0; played = 0; time = 0 }
        }
        $sourceStats[$source].total++
        $sourceStats[$source].time += $game.Playtime
        if ($game.Playtime -ge $minPlay) {
            $sourceStats[$source].played++
            $labels = "{source=`"$source`",gameId=`"$($game.GameId)`",name=`"$name`"}"
            "playnite_game_playtime_seconds$labels $($game.Playtime)"
            "playnite_game_sessions$labels         $($game.PlayCount)"
        }
    }
    End {
        foreach ($source in $sourceStats.Keys) {
            $__logger.Info("Calculated metrics: source $source total $num played $numP playtime $time")
            $stats = $sourceStats[$source]
            $labels = "{source=`"$source`"}"
            "playnite_game_total$labels $($stats.total)"
            "playnite_game_played_total$labels $($stats.played)"
            "playnite_game_playtime_seconds_total$labels $($stats.time)"
        }
    }
}

function SaveMetrics() {
    # https://playnite.link/docs/api/Playnite.SDK.Models.Game.html
    $PlayniteApi.Database.Games | `
        Select-Object Source, GameId, Name, Playtime, PlayCount | `
        CalculateMetrics | `
        Out-File $textFile -Encoding utf8
}

function OnApplicationStarted() { param($arg1) SaveMetrics }
function OnApplicationStopped() { param($arg1) SaveMetrics }
function OnLibraryUpdated() { param($arg1) SaveMetrics }
function OnGameStopped() { param($arg1) SaveMetrics }

function ExportLibrary() {
    param($arg1)
    SaveMetrics
    # $path = $PlayniteApi.Dialogs.SaveFile("OpenMetrics|*.prom|CSV|*.csv|Formatted TXT|*.txt")
    # if ($path) {
    #     if ($path -match ".prom$") {
    #         $PlayniteApi.Database.Games | Select Name, Source, Playtime | CalculateMetrics | Out-File $path -Encoding utf8
    #     } elseif ($path -match ".csv$") {
    #         $PlayniteApi.Database.Games | Select Name, Source, ReleaseDate, Playtime, IsInstalled | ConvertTo-Csv | Out-File $path -Encoding utf8
    #     } else {
    #         $PlayniteApi.Database.Games | Select Name, Source, ReleaseDate, Playtime, IsInstalled | Format-Table -AutoSize | Out-File $path -Encoding utf8
    #     }
    #     $PlayniteApi.Dialogs.ShowMessage("Library exported successfully.");
    # }
}

function GetMainMenuItems() {
    param($arg1)
    $menuItem = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem.Description = "Export OpenMetrics"
    $menuItem.FunctionName = "ExportLibrary"
    $menuItem.MenuSection = "@"
    return $menuItem
}
