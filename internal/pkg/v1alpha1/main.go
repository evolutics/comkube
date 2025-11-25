package v1alpha1

import (
	"bytes"
	"io"

	"github.com/evolutics/comkube/internal/pkg/kompose"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/kustomize/kyaml/errors"
	"sigs.k8s.io/kustomize/kyaml/kio"
	"sigs.k8s.io/kustomize/kyaml/yaml"
)

type App struct {
	metav1.ObjectMeta `json:"metadata"`
	Spec              Spec `json:"spec" yaml:"spec"`
}

type Spec struct {
	ComposeFileInline    any      `json:"composeFileInline" yaml:"composeFileInline"`
	ComposeFiles         []string `json:"composeFiles" yaml:"composeFiles"`
	WithDebugAnnotations bool     `json:"withDebugAnnotations" yaml:"withDebugAnnotations"`
}

func (app App) Filter(items []*yaml.RNode) ([]*yaml.RNode, error) {
	// TODO: Consider using `metadata.name` as default Compose project name.
	// TODO: Give `envs` hint if required env vars are undefined.
	// TODO: Give `mounts` hint if Compose file is missing.

	var composeFileInline io.Reader
	if app.Spec.ComposeFileInline != nil {
		rawComposeFileInline, err := yaml.Marshal(app.Spec.ComposeFileInline)
		if err != nil {
			return nil, errors.WrapPrefixf(err, "serializing inline Compose file")
		}
		composeFileInline = bytes.NewReader(rawComposeFileInline)
	}

	rawK8sManifests, err := kompose.Convert(kompose.ConversionOptions{
		ComposeFileInline:     composeFileInline,
		ComposeFiles:          app.Spec.ComposeFiles,
		Namespace:             app.Namespace,
		WithKomposeAnnotation: app.Spec.WithDebugAnnotations,
	})
	if err != nil {
		return nil, errors.WrapPrefixf(err, "converting with Kompose")
	}

	k8sManifests, err := kio.FromBytes(rawK8sManifests)
	if err != nil {
		return nil, errors.WrapPrefixf(err, "deserializing K8s manifests")
	}

	return append(items, k8sManifests...), nil
}
