package main

import (
	"github.com/gin-gonic/gin"
	"time"
)

type Payload struct {
	Message string    `json:"message"`
	Time    time.Time `json:"time"`
}

var p = Payload{Message: "Automate all the things!", Time: time.Now()}

func fetchTime(c *gin.Context) {

}

func main() {
	router := gin.Default()
	router.GET("/time", fetchTime)
}
