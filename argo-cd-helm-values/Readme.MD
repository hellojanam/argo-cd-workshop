helm repo add argo https://argoproj.github.io/argo-helm

helm install argo-cd argo/argo-cd -n argo-cd --create-namespace