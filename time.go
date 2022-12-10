package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"time"
)

type Payload struct {
	Message string    `json:"message"`
	Time    time.Time `json:"time"`
}

var p = Payload{Message: "Automate all the things!", Time: time.Now()}

func fetchTime(c *gin.Context) {
	c.IndentedJSON(http.StatusOK, p)
}

func main() {
	router := gin.Default()
	router.GET("/time", fetchTime)
	router.Run("localhost:8080")
}
