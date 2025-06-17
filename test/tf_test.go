package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.ibm.com/mathewss/tf-helper/modules/terratest"
)

var relativeRootPath = "../"

func TestSandbox(t *testing.T) {
	terratest.RunTestCase(t, &Sandbox{}, &terraform.Options{
		TerraformDir: relativeRootPath,
		Vars: map[string]interface{}{
			// Generally the api key passed
			"ibmcloud_api_key":      os.Getenv("API_KEY"),
			"basename":              "sbox",
			"resource_group":        "Travis",
			"ibmcloud_ssh_key_id": "r006-5a436fdd-c993-4d8e-9e9b-28cc48adeedf",
			"region":                "us-south",
			"zones":                 "[\"us-south-1\"]",
			"logdna_integration":    true,
			"logdna_plan":           "lite",
			"sandbox_uipassword":    "Admin1234567",
			"sandbox_ui_repo_url":   "https://github.com/username/repository-name/archive/master.zip",
			"remote_allowed_ips":    "[\"10.10.10.10\"]",
                        "personal_access_token": os.Getenv("PERSONAL_ACCESS_TOKEN"),
		},
	})
}
