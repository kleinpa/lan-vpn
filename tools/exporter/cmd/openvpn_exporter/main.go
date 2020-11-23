package main

import (
	"flag"
	"log"
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/kleinpa/lan-vpn/tools/exporter/openvpn"
)

var httpAddr = flag.String("listen_address", "0.0.0.0:8080", "Address to listen on for HTTP requests.")
var openvpnStatusPath = flag.String("openvpn_status_path", "/var/lib/openvpn/status", "Path to openvpn status file")

type collector struct {
	ClientCount   *prometheus.Desc
	BytesSent     *prometheus.Desc
	BytesReceived *prometheus.Desc

	StatusPath string
}

func NewCollector(statusPath string) prometheus.Collector {
	return &collector{
		ClientCount: prometheus.NewDesc(
			"openvpn_client_count",
			"Number of current clients",
			nil,
			nil,
		),
		BytesSent: prometheus.NewDesc(
			"openvpn_client_tx_bytes",
			"",
			[]string{"client", "address"},
			nil,
		), BytesReceived: prometheus.NewDesc(
			"openvpn_client_rx_bytes",
			"",
			[]string{"client", "address"},
			nil,
		),
		StatusPath: statusPath,
	}
}
func (c *collector) Describe(ch chan<- *prometheus.Desc) {
	for _, d := range []*prometheus.Desc{
		c.ClientCount,
		c.BytesSent,
		c.BytesReceived,
	} {
		ch <- d
	}
}
func (c *collector) Collect(ch chan<- prometheus.Metric) {
	status, err := openvpn.GetStatusFromFile(c.StatusPath)
	if err != nil {
		log.Fatal(err)
	}

	for _, client := range status.Clients {
		ch <- prometheus.MustNewConstMetric(
			c.BytesSent,
			prometheus.GaugeValue,
			float64(client.BytesSent),
			client.CommonName,
			client.RealAddress,
		)
		ch <- prometheus.MustNewConstMetric(
			c.BytesReceived,
			prometheus.GaugeValue,
			float64(client.BytesReceived),
			client.CommonName,
			client.RealAddress,
		)
	}

	ch <- prometheus.MustNewConstMetric(
		c.ClientCount,
		prometheus.GaugeValue,
		float64(len(status.Clients)),
	)
}

func main() {
	flag.Parse()

	reg := prometheus.NewRegistry()
	reg.MustRegister(NewCollector(*openvpnStatusPath))

	http.Handle("/metrics", promhttp.HandlerFor(reg, promhttp.HandlerOpts{}))
	http.ListenAndServe(*httpAddr, nil)
}
