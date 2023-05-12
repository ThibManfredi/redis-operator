package k8sutils

import (
	corev1 "k8s.io/api/core/v1"
	networkv1 "k8s.io/api/networking/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
)

const (
	redisClusterPort = 16379
)

func generateNetworkPolicyDef(networkPolicyMeta metav1.ObjectMeta) *networkv1.NetworkPolicy {
	protocol := corev1.ProtocolTCP

	networkPolicy := &networkv1.NetworkPolicy{
		ObjectMeta: networkPolicyMeta,
		Spec: networkv1.NetworkPolicySpec{
			PodSelector: metav1.LabelSelector{
				MatchLabels: networkPolicyMeta.Labels,
			},
			Ingress: []networkv1.NetworkPolicyIngressRule{
				{
					From: []networkv1.NetworkPolicyPeer{
						{
							PodSelector: &metav1.LabelSelector{
								MatchLabels: networkPolicyMeta.Labels,
							},
						},
					},
					Ports: []networkv1.NetworkPolicyPort{
						{
							Protocol: &protocol,
							Port: &intstr.IntOrString{
								IntVal: redisPort,
							},
						},
						{
							Protocol: &protocol,
							Port: &intstr.IntOrString{
								IntVal: redisClusterPort,
							},
						},
					},
				},
				{
					From: []networkv1.NetworkPolicyPeer{
						{
							PodSelector: &metav1.LabelSelector{
								// labels from Spec redisCluster
							},
						},
					},
					Ports: []networkv1.NetworkPolicyPort{
						{
							Protocol: &protocol,
							Port: &intstr.IntOrString{
								IntVal: redisPort,
							},
						},
					},
				},
			},
			Egress: []networkv1.NetworkPolicyEgressRule{
				{
					To: []networkv1.NetworkPolicyPeer{
						{
							PodSelector: &metav1.LabelSelector{
								MatchLabels: networkPolicyMeta.Labels,
							},
						},
					},
					Ports: []networkv1.NetworkPolicyPort{
						{
							Protocol: &protocol,
							Port: &intstr.IntOrString{
								IntVal: redisPort,
							},
						},
						{
							Protocol: &protocol,
							Port: &intstr.IntOrString{
								IntVal: redisClusterPort,
							},
						},
					},
				},
			},
			PolicyTypes: []networkv1.PolicyType{
				"Ingress",
				"Egress",
			},
		},
	}

	return networkPolicy
}
