package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.ibm.com/mathewss/tf-helper/modules/terratest"
)

// See https://github.ibm.com/workload-eng-services/tf-template-test for an example
// and usage of the tf-helper terratest helper module

type Sandbox struct{}

// Optional Setup and TearDown methods are run before and after Test* tests are executed
// respectively for each TestCase. You may remove them if not needed. Handy for inserting terraform,
// creating resources, copying files, etc. only needed for testing.
func (tc *Sandbox) Setup()    {}
func (tc *Sandbox) TearDown() {}

// Validate VPC Stack with terraform Plan
func (tc *Sandbox) TestVpc(t *testing.T) {

	plan := terratest.GetPlan(t)

	// Get the VPC  resource you want to assert against
	sandboxVpc := terratest.GetResourcePlannedValues(t, plan, "ibm_is_vpc.sandbox-vpc")
	assert.Equal(t, "auto", sandboxVpc["address_prefix_management"])
	assert.Equal(t, false, sandboxVpc["classic_access"])

	//Get the PUBLIC GATEWAY resource you want to assert against
	publicGateway := terratest.GetResourcePlannedValues(t, plan, "ibm_is_public_gateway.gateway[0]")
	assert.Equal(t, "us-south-1", publicGateway["zone"])

	//Get the Subnets you want to assert against
	subnets := terratest.GetResourcePlannedValues(t, plan, "ibm_is_subnet.subnets[0]")
	assert.Equal(t, "us-south-1", subnets["zone"])
}

// Validate Sandbox VSIs with terraform Plan
func (tc *Sandbox) TestSandboxVSIs(t *testing.T) {
	// Get the plan (plan struct from resulting terraform plan command)
	// tf-helper will only run the plan once, so no need to worry how
	// many times you call it in your test file
	plan := terratest.GetPlan(t)

	/// Get the Application 1 VSIs details
	cxl_app1 := terratest.GetResourcePlannedValues(t, plan, "ibm_is_instance.dashboard-vm[0]")
	assert.Equal(t, "bx2d-4x16", cxl_app1["profile"])
	assert.Equal(t, "us-south-1", cxl_app1["zone"])
}

// Validate Security groups with terraform Plan
func (tc *Sandbox) TestSecurityGroups(t *testing.T) {

	plan := terratest.GetPlan(t)

	// Get the SECURITY GROUP RULE  - DEFAULT APPLICATION SSH resource you want to assert against
	sshRule := []interface{}([]interface{}{map[string]interface{}{"port_max": (float64)(22), "port_min": (float64)(22)}})
	SgRuleDefaultAppSsh := terratest.GetResourcePlannedValues(t, plan, "ibm_is_security_group_rule.dashboard_ssh_self")
	assert.Equal(t, "inbound", SgRuleDefaultAppSsh["direction"])
	assert.Equal(t, "ipv4", SgRuleDefaultAppSsh["ip_version"])
	assert.Equal(t, sshRule, SgRuleDefaultAppSsh["tcp"])

	// Get the SECURITY GROUP RULE  - DEFAULT APPLICATION SSH resource you want to assert against
	httpRule1 := []interface{}([]interface{}{map[string]interface{}{"port_max": (float64)(8080), "port_min": (float64)(8080)}})
	SgRuleDefaultApphttp1 := terratest.GetResourcePlannedValues(t, plan, "ibm_is_security_group_rule.dashboard_api_rule")
	assert.Equal(t, "inbound", SgRuleDefaultApphttp1["direction"])
	assert.Equal(t, "ipv4", SgRuleDefaultApphttp1["ip_version"])
	assert.Equal(t, httpRule1, SgRuleDefaultApphttp1["tcp"])

	// Get the SECURITY GROUP RULE  - DEFAULT APPLICATION SSH resource you want to assert against
	httpRule2 := []interface{}([]interface{}{map[string]interface{}{"port_max": (float64)(80), "port_min": (float64)(80)}})
	SgRuleDefaultApphttp2 := terratest.GetResourcePlannedValues(t, plan, "ibm_is_security_group_rule.dashboard_ui_rule")
	assert.Equal(t, "inbound", SgRuleDefaultApphttp2["direction"])
	assert.Equal(t, "ipv4", SgRuleDefaultApphttp2["ip_version"])
	assert.Equal(t, httpRule2, SgRuleDefaultApphttp2["tcp"])
}
