package openvpn_test

import (
	"os"
	"testing"

	"github.com/kleinpa/lan-vpn/tools/exporter/openvpn"
)

func TestGetStatus(t *testing.T) {
	f, err := os.Open("testdata/status3")
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()

	openvpn.ReadStatus(f)
}
