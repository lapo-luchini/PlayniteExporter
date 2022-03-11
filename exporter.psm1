$textFile = 'C:\Program Files\windows_exporter\textfile_inputs\playnite.prom'
$minPlay = 300

function CalculateMetrics() {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        $game
    )
    Begin {
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
        $num = 0
        $numP = 0
        $time = 0
    }
    Process {
        ++$num
        $time += $game.Playtime
        $name = $game.Name -replace '([\\"])', '\$1'
        if ($game.Playtime -ge $minPlay) {
            ++$numP
            "playnite_game_playtime_seconds{gameId=`"$($game.GameId)`",name=`"$name`"} $($game.Playtime)"
            "playnite_game_sessions{gameId=`"$($game.GameId)`",name=`"$name`"} $($game.PlayCount)"
        }
    }
    End {
        $__logger.Info("Calculated metrics: total $num played $numP playtime $time")
        "playnite_game_total $num"
        "playnite_game_played_total $numP"
        "playnite_game_playtime_seconds_total $time"
    }
}

function SaveMetrics() {
    # https://playnite.link/docs/api/Playnite.SDK.Models.Game.html
    $PlayniteApi.Database.Games | Select-Object GameId, Name, Playtime, PlayCount | Sort-Object Name, GameId | CalculateMetrics | Out-File $textFile -Encoding utf8
}

function OnApplicationStarted() { SaveMetrics }
function OnApplicationStopped() { SaveMetrics }
function OnLibraryUpdated() { SaveMetrics }
function OnGameStopped() { SaveMetrics }

function ExportLibrary() {
    param(
        $scriptMainMenuItemActionArgs
    )
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
    param(
        $menuArgs
    )
    $menuItem = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem.Description = "Export OpenMetrics"
    $menuItem.FunctionName = "ExportLibrary"
    $menuItem.MenuSection = "@"
    return $menuItem
}
