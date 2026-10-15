#!/bin/bash
set -e

# ======================================================================
# Bug réel très classique sur kubeadm (cf. kubernetes/kubeadm#581) :
# les pods CoreDNS utilisent dnsPolicy=Default, donc ils héritent du
# /etc/resolv.conf du NŒUD (volontairement, pour éviter de se forward
# vers eux-mêmes). Si ce fichier contient "nameserver 127.0.0.1" qui
# boucle vers le cluster DNS (cas fréquent avec systemd-resolved mal
# configuré), CoreDNS détecte la boucle et plante : "Loop detected for
# zone". Avec plusieurs replicas, le symptôme devient aléatoire selon
# quel pod CoreDNS répond à la requête à l'instant T.
# ======================================================================

cp /etc/resolv.conf /etc/resolv.conf.bak
sed -i '1s/^/nameserver 127.0.0.1\n/' /etc/resolv.conf

# Force CoreDNS à relire la conf réseau du nœud
kubectl -n kube-system rollout restart deployment/coredns

# Pod témoin pour que le candidat puisse reproduire le symptôme à la demande
kubectl run dns-probe --image=busybox:1.36 --restart=Never -- sleep infinity
