package openvpn

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"strings"
	"time"
)

type ClientRecord struct {
	CommonName         string
	RealAddress        string
	VirtualAddress     string
	VirtualIPv6Address string
	BytesReceived      int64
	BytesSent          int64
	ConnectedSince     time.Time
	Username           string
	ClientID           string
	PeerID             string
	DataChannelCipher  string
}

type OpenvpnStatus struct {
	Clients []ClientRecord
}

func GetStatusFromFile(statusPath string) (OpenvpnStatus, error) {
	f, err := os.Open(statusPath)
	if err != nil {
		return OpenvpnStatus{}, err
	}
	defer f.Close()
	return ReadStatus(f)
}

func ReadStatus(in io.Reader) (OpenvpnStatus, error) {
	status := OpenvpnStatus{}

	reader := bufio.NewReader(in)
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			return status, err
		}
		line = strings.TrimSpace(line)

		if strings.HasPrefix(line, "CLIENT_LIST") {
			ss := strings.Split(line, "\t")
			if len(ss) < 12 {
				return status, fmt.Errorf(
					"CLIENT_LIST line does not contain the expected number of fields")
			}

			c := ClientRecord{}
			c.CommonName = ss[1]
			c.RealAddress = ss[2]
			c.VirtualAddress = ss[3]
			c.VirtualIPv6Address = ss[4]
			if x, err := strconv.ParseInt(ss[5], 10, 64); err != nil {
				return status, err
			} else {
				c.BytesReceived = x
			}
			if x, err := strconv.ParseInt(ss[6], 10, 64); err != nil {
				return status, err
			} else {
				c.BytesSent = x
			}
			if x, err := strconv.ParseInt(ss[8], 10, 64); err != nil {
				return status, err
			} else {
				c.ConnectedSince = time.Unix(x, 0)
			}
			c.Username = ss[9]
			c.ClientID = ss[10]
			c.PeerID = ss[11]
			c.DataChannelCipher = ss[12]

			status.Clients = append(status.Clients, c)
		} else if strings.HasPrefix(line, "HEADER") {
		} else if strings.HasPrefix(line, "ROUTING_TABLE") {
		} else if strings.HasPrefix(line, "TITLE") {
		} else if strings.HasPrefix(line, "TIME") {
		} else if strings.HasPrefix(line, "GLOBAL_STATS") {
		} else if strings.HasPrefix(line, "END") {
			return status, nil
		} else {
			log.Printf("Unexpected line: %q", line)
		}
	}
}
