package main

import (
	"log"

	"github.com/evolutics/comkube/internal/pkg/dispatcher"
)

func main() {
	if err := dispatcher.NewCommand().Execute(); err != nil {
		log.Fatal(err)
	}
}
