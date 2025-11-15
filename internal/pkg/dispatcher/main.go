package dispatcher

import (
	"github.com/evolutics/comkube/internal/pkg/v1alpha1"
	"github.com/spf13/cobra"
	"sigs.k8s.io/kustomize/kyaml/errors"
	"sigs.k8s.io/kustomize/kyaml/fn/framework"
	"sigs.k8s.io/kustomize/kyaml/fn/framework/command"
	"sigs.k8s.io/kustomize/kyaml/kio"
	"sigs.k8s.io/kustomize/kyaml/kio/filters"
)

func NewCommand() *cobra.Command {
	processor := framework.ResourceListProcessorFunc(processKnownAPIGroups)
	return command.Build(processor, command.StandaloneEnabled, false)
}

func processKnownAPIGroups(resources *framework.ResourceList) error {
	filterProvider := framework.GVKFilterMap{
		"ComposeApp": map[string]kio.Filter{
			"comkube.evolutics.info/v1alpha1": &v1alpha1.App{},
		},
	}
	processor := framework.VersionedAPIProcessor{FilterProvider: filterProvider}
	if err := processor.Process(resources); err != nil {
		return errors.Wrap(err)
	}

	var err error
	resources.Items, err = filters.FormatFilter{UseSchema: true}.Filter(resources.Items)
	if err != nil {
		return errors.WrapPrefixf(err, "formatting output")
	}

	return nil
}
