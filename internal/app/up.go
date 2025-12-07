package app

import (
	"bytes"
	"fmt"

	"github.com/evolutics/comkube/internal/pkg/kompose"
	"github.com/evolutics/comkube/internal/pkg/kubectl"
)

type upOptions struct {
	Files                []string
	Namespace            string
	Profiles             []string
	WithDebugAnnotations bool
}

func up(options upOptions) error {
	k8sManifests, err := kompose.Convert(kompose.ConversionOptions{
		Files:                 options.Files,
		Namespace:             options.Namespace,
		Profiles:              options.Profiles,
		WithKomposeAnnotation: options.WithDebugAnnotations,
	})
	if err != nil {
		return fmt.Errorf("converting with Kompose: %w", err)
	}

	err = kubectl.Apply(kubectl.ApplyOptions{
		Config: bytes.NewReader(k8sManifests),
	})
	if err != nil {
		return fmt.Errorf("applying with kubectl: %w", err)
	}

	return nil
}
