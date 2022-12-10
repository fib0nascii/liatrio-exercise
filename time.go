package main

import (
	"fmt"
	"time"
)

type Payload struct {
	Message string    `json:"message"`
	Time    time.Time `json:"time"`
}

func main() {
	p := Payload{Message: "Automate all the things!", Time: time.Now()}
	fmt.Println(p)
}
