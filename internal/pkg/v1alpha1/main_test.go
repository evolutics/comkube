package v1alpha1_test

import (
	"testing"

	"github.com/evolutics/comkube/internal/pkg/dispatcher"
	"sigs.k8s.io/kustomize/kyaml/fn/framework/frameworktestutil"
)

func TestCommand(test *testing.T) {
	// TODO: Test multiple ComposeApp manifests.
	checker := frameworktestutil.CommandResultsChecker{
		Command: dispatcher.NewCommand,
		// UpdateExpectedFromActual: true,
	}
	checker.Assert(test)
}
