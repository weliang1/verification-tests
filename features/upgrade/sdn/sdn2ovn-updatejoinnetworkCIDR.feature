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
    Given plugin is openshift-ovs-networkpolicy on the cluster
    Given as admin I successfully merge patch resource "networks.operator.openshift.io/cluster" with:
      | {"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"v4InternalSubnet":"100.66.0.0/16" }}}} |
