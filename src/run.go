package main

import (
    "bufio"
    "fmt"
    "flag"
    "os/exec"
	"strings"
	//"io/ioutil"
    "regexp"
    "bytes"
    "strconv"
	"net/http"
	"encoding/json"
)

func IsValidEthAddress(address string) bool {
	if !strings.HasPrefix(address, "0x") {
		return false
	}
	if len(address) != 42 {
		return false
	}
	isHex := regexp.MustCompile(`^0x[0-9a-fA-F]{40}$`)
	return isHex.MatchString(address)
}
func main() {
    miner := flag.String("miner", "", "miner address")
    pool := flag.String("p", "", "pool 1-4")
    flag.Parse()
    if *miner == "" {
        fmt.Println("Miner address not provided.  Example: ./emc_cuda_pool -miner 0x12345678912345678912 -p 1")
        return
    }
    if *pool == "" {
        fmt.Println("pool not provided.  Example: ./emc_cuda_pool -miner 0x12345678912345678912 -p 1")
        return
    }
    minerAddress := *miner
    poolindexstr := *pool
    poolindex, err := strconv.Atoi(poolindexstr)
    resp, err := http.Get("https://bj.ipant.xyz/pool.json")
    if err != nil {
        fmt.Println("Error fetching pool.json:", err)
        return
    }
    defer resp.Body.Close()
    type Pool struct {
        Index int    `json:"index"`
        URL   string `json:"url"`
    }

    var data struct {
        Pools []Pool `json:"pools"`
    }
    err = json.NewDecoder(resp.Body).Decode(&data)
    if err != nil {
        fmt.Println("Error decoding pool.json:", err)
        return
    }

    var url string
    for _, poolstr := range data.Pools {
        if  poolstr.Index == poolindex {
            url = poolstr.URL
            break
        }
    }


    fmt.Println("Miner Address:", minerAddress)
    fmt.Println("pool :", url)
    if !IsValidEthAddress(minerAddress){
        fmt.Println("Mineraddress incorrect, please check!")
        return
    }
    cmd := exec.Command("./guaguagua_linux","-p",poolindexstr) 
    fmt.Println("CUDA is runing!!!!!!!")
    stdout, err := cmd.StdoutPipe()
    if err != nil {
        fmt.Println("Error creating StdoutPipe:", err)
        return
    }

    err = cmd.Start()
    if err != nil {
        fmt.Println("Error starting command:", err)
        return
    }

    scanner := bufio.NewScanner(stdout)
    for scanner.Scan() {
		separator := ":"
		index := strings.Index(scanner.Text(), separator)
		hash := scanner.Text()[index+1:] 
		fmt.Println("hash:",hash,"     FIND !!!")
		params := map[string]interface{}{"solution": hash,"miner":minerAddress}
		data, err := json.Marshal(params)
		if err != nil {
			fmt.Println("Error marshalling data:", err)
		}
		resp, err := http.Post(url, "application/json", bytes.NewBuffer(data))
		if err != nil {
			fmt.Println("Error sending POST request:", err,resp)
		}else{
            fmt.Println("hash:",hash,"  TX sent!!!")
        }

        //fmt.Println(scanner.Text()) //  
    }

    err = cmd.Wait()
    if err != nil {
        fmt.Println("Error waiting for command:", err)
        return
    }
}
