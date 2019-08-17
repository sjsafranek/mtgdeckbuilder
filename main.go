package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	DEFAULT_MAX_CONCURRENT_JOBS uint64 = 10
)

var (
	ApiClient         *http.Client
	ApiTransporter    *http.Transport
	MaxConcurrentJobs uint64 = DEFAULT_MAX_CONCURRENT_JOBS
)

func init() {
	ApiTransporter = &http.Transport{
		MaxIdleConnsPerHost: int(MaxConcurrentJobs),
		// http://craigwickesser.com/2015/01/golang-http-to-many-open-files/
		// Dial: (&net.Dialer{
		// 	Timeout: 5 * time.Second,
		// }).Dial,
		TLSHandshakeTimeout: 15 * time.Second,
		IdleConnTimeout:     60 * time.Second,

		// https://golang.org/pkg/net/http/#Transport
		// https://stackoverflow.com/questions/39813587/go-client-program-generates-a-lot-a-sockets-in-time-wait-state?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
		MaxIdleConns: int(MaxConcurrentJobs),
		// ExpectContinueTimeout: 1 * time.Second,
		// ResponseHeaderTimeout: 5 * time.Second,
	}

	ApiClient = &http.Client{
		// The default is 2, which is generally too low for our request concurrency
		// in this program, resulting in unboundded growth and eventual exhaustion
		// of all available ports. This should keep the number of detatched TIME_WAIT
		// sockets to a minimum that matches our concurrency configuration.
		Transport: ApiTransporter,
	}
}

func FetchCard(cardName string) (*Card, error) {
	var card Card

	url := fmt.Sprintf("https://api.scryfall.com/cards/named?exact=%v", cardName)
	url = strings.Replace(url, " ", "%20", -1)
	req, err := http.NewRequest("GET", url, nil)
	if nil != err {
		return &card, err
	}

	resp, err := ApiClient.Do(req)
	if err != nil {
		return &card, err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return &card, err
	}

	err = json.Unmarshal(body, &card)
	return &card, err
}

func main() {
	file, err := os.Open("temur_turbofog_superfriends.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	cmcs := make(map[float64]int64)
	color_identities := make(map[string]int64)
	colors := make(map[string]int64)
	card_types := make(map[string]int64)

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.SplitN(line, " ", 2)
		card, err := FetchCard(parts[1])
		if nil != err {
			panic(err)
		}

		num, err := strconv.ParseInt(parts[0], 10, 64)
		if nil != err {
			panic(err)
		}

		cmcs[card.CMC] += num
		for _, color := range card.ColorIdentity {
			color_identities[color] += num
		}
		for _, color := range card.Colors {
			colors[color] += num
		}

		ctypes := strings.Split(card.TypeLine, " ")
		for _, ctype := range ctypes {
			if "—" != ctype && "//" != ctype {
				card_types[ctype] += num
			}
		}

	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	fmt.Println("cmcs ", cmcs)
	fmt.Println("colors ", colors)
	fmt.Println("color_identities ", color_identities)
	fmt.Println("card_types ", card_types)
}
