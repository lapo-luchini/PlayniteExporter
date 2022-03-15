# PlayniteExporter

Playnite exporter in Prometheus/OpenMetrics format.

## How to use

1. install [Windows Exporter](https://github.com/prometheus-community/windows_exporter)
2. give yourself write access to this folder: `C:\Program Files\windows_exporter\textfile_inputs`
3. checkout this repository under Playnite's extensions folder: `C:\Users\User\AppData\Local\Playnite\Extensions\PlayniteExporter`
4. scrape from your [Victoria Metrics](https://victoriametrics.com/) or other Prometheus-compatible TSDB
5. import the [example dashboard](https://grafana.com/grafana/dashboards/15916) in your Grafana
