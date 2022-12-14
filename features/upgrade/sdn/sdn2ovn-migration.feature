Feature: SDN update joint network CIDR migration testing

  # @author weliang@redhat.com
  @admin
  @upgrade-prepare
  @4.13 @4.12
  @vsphere-upi @openstack-upi @nutanix-upi @ibmcloud-upi @gcp-upi @baremetal-upi @azure-upi @aws-upi @alicloud-upi
  @vsphere-ipi @openstack-ipi @nutanix-ipi @ibmcloud-ipi @gcp-ipi @baremetal-ipi @azure-ipi @aws-ipi @alicloud-ipi
  @upgrade
  @network-openshiftsdn
  @proxy @noproxy @disconnected @connected
  Scenario: Check joint network CIDR after migration - prepare
    #Given the plugin is openshift-ovs-networkpolicy on the cluster
    #Given as admin I successfully merge patch resource "networks.operator.openshift.io/cluster" with:
     # | {"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"v4InternalSubnet":"100.66.0.0/16" }}}} |
    Given I store the masters in the :masters clipboard
    And the Internal IP of node "<%= cb.masters[0].name %>" is stored in the :master0_ip clipboard
    Given the joint network CIDR is patched in the node
    
   # @author weliang@redhat.com
  # @case_id OCP-54166
  @admin
  @upgrade-check
  @network-ovnkubernetes
  @4.13 @4.12
  @openstack-ipi @gcp-ipi @baremetal-ipi @azure-ipi @aws-ipi
  @openstack-upi @gcp-upi @baremetal-upi @azure-upi @aws-upi
  @upgrade
  @proxy @noproxy @disconnected @connected
  Scenario: Check joint network CIDR after migration
  Given I store the masters in the :masters clipboard
  And the Internal IP of node "<%= cb.masters[0].name %>" is stored in the :master0_ip clipboard
  Given the joint network CIDR is updateded in the node "<%= cb.masters[0].name %>"
