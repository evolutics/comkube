package main

import (
	"log"
	"os"

	"github.com/evolutics/comkube/internal/app"
)

func main() {
	err := app.Main(os.Args)
	if err != nil {
		log.Fatal(err)
	}
}
