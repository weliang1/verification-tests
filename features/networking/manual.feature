Feature: Multus-CNI related scenarios

  # @author bmeng@redhat.com
  # @case_id OCP-21855
  @flaky
  @admin
  @destructive
  @4.12 @4.11 @4.10 @4.9 @4.8 @4.7 @4.6
  @vsphere-ipi @openstack-ipi @gcp-ipi @baremetal-ipi @azure-ipi @aws-ipi @alicloud-ipi
  @vsphere-upi @openstack-upi @gcp-upi @baremetal-upi @azure-upi @aws-upi @alicloud-upi
  @upgrade-sanity
  @singlenode
  @proxy @noproxy @connected
  @network-ovnkubernetes @network-openshiftsdn
  @ppc64le @heterogeneous @arm64 @amd64
  @critical
  Scenario: OCP-21855:SDN Create pods with muliple cni plugins via multus-cni - macvlan + host-device
    # Make sure that the multus is enabled
    Given the master version >= "4.1"
    And the multus is enabled on the cluster
    And an 4 character random string of type :hex is stored into the :nic_name clipboard
    Given the default interface on nodes is stored in the :default_interface clipboard
    And evaluation of `node.name` is stored in the :target_node clipboard
    # Create the net-attach-def via cluster admin
    Given I have a project with proper privilege
    Given I obtain test data file "networking/multus-cni/NetworkAttachmentDefinitions/macvlan-bridge.yaml"
    When I run oc create as admin over "macvlan-bridge.yaml" replacing paths:
      | ["metadata"]["namespace"] | <%= project.name %>                                                                                                                                                                                                                                                                    |
      | ["spec"]["config"]        | '{ "cniVersion": "0.3.1", "type": "macvlan", "master": "<%= cb.default_interface %>","mode": "bridge", "ipam": { "type": "host-local", "subnet": "10.1.1.0/24", "rangeStart": "10.1.1.100", "rangeEnd": "10.1.1.200", "routes": [ { "dst": "0.0.0.0/0" } ], "gateway": "10.1.1.1" } }' |
    Then the step should succeed
    Given I obtain test data file "networking/multus-cni/NetworkAttachmentDefinitions/host-device.yaml"
    When I run oc create as admin over "host-device.yaml" replacing paths:
      | ["metadata"]["namespace"] | <%= project.name %>                                                              |
      | ["spec"]["config"]        | '{"cniVersion": "0.3.1", "type": "host-device", "device": "<%= cb.nic_name %>"}' |
    Then the step should succeed

    # Prepare the net link on the node which will be attached to the pod
    When I run command on the "<%= cb.target_node %>" node's sdn pod:
      | sh | -c | ip link add <%= cb.nic_name%> link <%= cb.default_interface %> type macvlan mode private |
    Then the step should succeed
    Given I register clean-up steps:
    """
    I run command on the "<%= cb.target_node %>" node's sdn pod:
       | sh | -c | ip link del <%= cb.nic_name%> |
    the step should succeed
    """

    # Create the pod which consumes both hostdev and macvlan custom resources
    Given I obtain test data file "networking/multus-cni/Pods/2interface-macvlan-hostdevice.yaml"
    When I run oc create over "2interface-macvlan-hostdevice.yaml" replacing paths:
      | ["spec"]["nodeName"] | "<%= cb.target_node %>" |
    Then the step should succeed
    Given I register clean-up steps:
    """
    I run the :delete client command with:
      | object_type | pod                         |
      | l           | name=macvlan-hostdevice-pod |
    the step should succeed
    all existing pods die with labels:
      | name=macvlan-hostdevice-pod |
    """
    And a pod becomes ready with labels:
      | name=macvlan-hostdevice-pod |

    # Check that there are two additional interfaces attached to the pod
    When I execute on the pod:
      | ip | -d | link |
    Then the output should contain "net1"
    And the output should contain "net2"
    And the output should contain "macvlan mode bridge"
    And the output should contain "macvlan mode private"
    When I execute on the pod:
      | bash | -c | ip -f inet addr show net2 |
    Then the output should match "10.1.1.\d{1,3}"
    And the expression should be true> IPAddr.new(@result[:response].match(/\d{1,3}\.\d{1,3}.\d{1,3}.\d{1,3}/)[0])

 

  # @author anusaxen@redhat.com
  # @case_id OCP-22504
  @flaky
  @admin
  @4.14 @4.13 @4.12 @4.11 @4.10 @4.9 @4.8 @4.7 @4.6
  @vsphere-ipi @openstack-ipi @nutanix-ipi @ibmcloud-ipi @gcp-ipi @baremetal-ipi @azure-ipi @aws-ipi @alicloud-ipi
  @vsphere-upi @openstack-upi @nutanix-upi @ibmcloud-upi @gcp-upi @baremetal-upi @azure-upi @aws-upi @alicloud-upi
  @upgrade-sanity
  @singlenode
  @network-ovnkubernetes @network-openshiftsdn
  @proxy @noproxy
  @s390x @ppc64le @heterogeneous @arm64 @amd64
  @hypershift-hosted
  @critical
  Scenario: OCP-22504:SDN The multus admission controller should be able to detect that the pod is using net-attach-def in other namespaces when the isolation is enabled
    Given I create 2 new projects
    # Create the net-attach-def via cluster admin
    Given I obtain test data file "networking/multus-cni/NetworkAttachmentDefinitions/macvlan-bridge.yaml"
    When I run oc create as admin over "macvlan-bridge.yaml" replacing paths:
      | ["metadata"]["name"]      | macvlan-bridge-25657    |
      | ["metadata"]["namespace"] | <%= project(-1).name %> |
    Then the step should succeed
    And admin checks that the "macvlan-bridge-25657" network_attachment_definition exists in the "<%= project(-1).name %>" project  
    Given I use the "<%= project(-2).name %>" project
    # Create a pod in new project consuming net-attach-def from 1st project
    Given I obtain test data file "networking/multus-cni/Pods/generic_multus_pod.yaml"
    When I run oc create over "generic_multus_pod.yaml" replacing paths:
      | ["metadata"]["name"]                                       | multus-pod              |
      | ["metadata"]["annotations"]["k8s.v1.cni.cncf.io/networks"] | macvlan-bridge-25657    |
      | ["spec"]["containers"][0]["name"]                          | multus-pod              |
    #making sure the created pod complains about net-attach-def and hence stuck in ContainerCreating state
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pods       |
      | name     | multus-pod |
    Then the step should succeed
    And the output should contain:
      | cannot find a network-attachment-definition |
      | ContainerCreating                           |
  
   
  # @author anusaxen@redhat.com
  # @case_id OCP-24466
  @admin
  @destructive
  @4.14 @4.10 @4.9 @4.8 @4.7
  @vsphere-ipi @openstack-ipi @gcp-ipi @baremetal-ipi @azure-ipi @aws-ipi
  @vsphere-upi @openstack-upi @gcp-upi @baremetal-upi @azure-upi @aws-upi
  @upgrade-sanity
  @inactive
  Scenario: OCP-24466:SDN CNO manager macvlan configured manually with DHCP
    Given the multus is enabled on the cluster
    And I store the masters in the :master clipboard
    Given I store the ready and schedulable workers in the :nodes clipboard
    #Obtaining master's tunnel interface name, address and worker's interface name,address
    Given the vxlan tunnel name of node "<%= cb.master[0].name %>" is stored in the :mastr_inf_name clipboard
    And the vxlan tunnel address of node "<%= cb.master[0].name %>" is stored in the :mastr_inf_address clipboard
    Given the vxlan tunnel name of node "<%= cb.worker[0].name %>" is stored in the :workr_inf_name clipboard
    And the vxlan tunnel address of node "<%= cb.worker[0].name %>" is stored in the :workr_inf_address clipboard
    #Configuing tunnel interface on a worker node
    Given I use the "<%= cb.worker[0].name %>" node
    And I run commands on the host:
      | ip link add mvlanp0 type vxlan id 100 remote <%= cb.mastr_inf_address %> dev <%= cb.workr_inf_name %> dstport 14789 |
      | ip link set up mvlanp0                                                                                              |
      | ip a add 192.18.0.10/15 dev mvlanp0                                                                                 |
    Then the step should succeed
    #Cleanup for deleting worker interface
    Given I register clean-up steps:
    """
    the bridge interface named "mvlanp0" is deleted from the "<%= cb.worker[0].name %>" node
    """
    #Configuing tunnel interface on master node
    Given I use the "<%= cb.master[0].name %>" node
    And I run commands on the host:
      | ip link add mvlanp0 type vxlan id 100 remote <%= cb.workr_inf_address %> dev <%= cb.mastr_inf_name %> dstport 14789 |
      | ip link set up mvlanp0                                                                                              |
      | ip a add 192.18.0.20/15 dev mvlanp0                                                                                 |
    Then the step should succeed
    #Cleanup for deleting master interface
    Given I register clean-up steps:
    """
    the bridge interface named "mvlanp0" is deleted from the "<%= cb.master[0].name %>" node
    """
    #Confirm the link connectivity between master and worker
    When I run commands on the host:
      | ping -c1 -W2 192.18.0.20 |
    Then the step should succeed
    Given I use the "<%= cb.worker[0].name %>" node
    And I run commands on the host:
      | ping -c1 -W2 192.18.0.10 |
    Then the step should succeed

    #Configuring DHCP service on master node
    Given a DHCP service is configured for interface "mvlanp0" on "<%= cb.master[0].name %>" node with address range and lease time as "192.18.0.100,192.18.0.120,24h"
    #Cleanup for deconfiguring DHCP service on target node
    Given I register clean-up steps:
    """
    a DHCP service is deconfigured on the "<%= cb.master[0].name %>" node
    """
    Given I have a project with proper privilege
    #Patching simplemacvlan config in network operator config CRD
    And as admin I successfully merge patch resource "networks.operator.openshift.io/cluster" with:
      | {"spec": {"additionalNetworks": [{"name": "testmacvlan","namespace": "<%= project.name %>","simpleMacvlanConfig": {"ipamConfig": {"type": "dhcp"},"master": "mvlanp0"},"type": "SimpleMacvlan"}]}} |
    #Cleanup for bringing CRD to original
    Given I register clean-up steps:
    """
    as admin I successfully merge patch resource "networks.operator.openshift.io/cluster" with:
      | {"spec":{"additionalNetworks": null}} |
    """
    #Creating pod under test project to absorb above net-attach-def
    Given I obtain test data file "networking/multus-cni/Pods/generic_multus_pod.yaml"
    When I run oc create over "generic_multus_pod.yaml" replacing paths:
      | ["metadata"]["namespace"]                                  | <%= project.name %>      |
      | ["metadata"]["annotations"]["k8s.v1.cni.cncf.io/networks"] | testmacvlan              |
      | ["spec"]["nodeName"]                                       | <%= cb.worker[0].name %> |
    Then the step should succeed
    And the pod named "test-pod" becomes ready
    When I execute on the pod:
      | ip | a |
    Then the output should contain "192.18.0"
