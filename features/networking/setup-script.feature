  Feature: setup cluster scripts
  
  # @author weliang@redhat.com
  # @case_id OCP-44445
  @admin
  @destructive
  @inactive
  @network-ovnkubernetes @network-openshiftsdn @ipsec
  @4.12 @4.11
  @vsphere-ipi @openstack-ipi @gcp-ipi @baremetal-ipi @azure-ipi @aws-ipi
  @vsphere-upi @openstack-upi @gcp-upi @baremetal-upi @azure-upi @aws-upi
  @proxy @noproxy @disconnected @connected
  @singlenode
  Scenario: OCP-40569:SDN Allow enablement/disablement ipsec at runtime
    Given the env is using "OVNKubernetes" networkType
    Given I store all worker nodes to the :workers clipboard
    Given the default interface on nodes is stored in the :default_interface clipboard
    #Enable ipsec through CNO
    Given as admin I successfully merge patch resource "networks.operator.openshift.io/cluster" with:
      | {"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"ipsecConfig":{}}}}} |
    Given I have a project
    Given I obtain test data file "networking/pod-for-ping.json"
    When I run oc create over "pod-for-ping.json" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.workers[1].name %> |
      | ["metadata"]["name"] | pod-worker1               |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=hello-pod |
    And evaluation of `pod.ip_url` is stored in the :test_pod_worker1 clipboard

    Given I obtain test data file "networking/pod-for-ping.json"
    When I run oc create over "pod-for-ping.json" replacing paths:
      | ["spec"]["nodeName"]                 | <%= cb.workers[0].name %>                                                                                          |
      | ["metadata"]["name"]                 | pod-worker0                                                                                                        |
      | ["spec"]["containers"][0]["command"] | ["bash", "-c", "for f in {0..3600}; do curl <%= cb.test_pod_worker1 %>:8080 ; --connect-timeout 5; sleep 1; done"] |
    Then the step should succeed
    #Above command will curl "hello openshift" traffic every 1 second to worker1 test pod which is expected to cause ESP traffic generation across those nodes
    And a pod becomes ready with labels:
      | name=hello-pod |

    
    Given 15000 seconds have passed
