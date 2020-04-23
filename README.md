# CI-Tools Container

This repository contains a Multi-Stage Dockerfile for buliding a container that contains the following tools:

- docker
- kustomize 
- kubectl

## kustomize ist in einer aktuellen 3er Version installiert

In dieser neuen kustomize Version kann man mit
 
```export KUSTOMIZE_ENABLE_ALPHA_COMMANDS=true```

zusätzliche Features freischalten.


### hiermit kann man sich den unterschied zwischen der config im cluster und der lokalen config anzeigen:

```kustomize resources diff -k your/kustomize/overlay```


### Besonders interessant finde ich die Custom Setter für Recource fields.
Create a custom setter for a Resource field by inlining OpenAPI as comments.

https://github.com/kubernetes-sigs/kustomize/blob/master/cmd/config/docs/commands/create-setter.md

Und vor allem kann man sich die auch anzeigen lassen:

https://github.com/kubernetes-sigs/kustomize/blob/master/cmd/config/docs/commands/list-setters.md

https://github.com/kubernetes-sigs/kustomize/blob/master/cmd/config/docs/commands/set.md

### Deklaratives Config Management:
https://github.com/kubernetes/community/blob/master/contributors/design-proposals/architecture/declarative-application-management.md



### kstatus provides tools for checking the status of Kubernetes resources. 
The primary use case is knowing when (or if) a given set of resources in cluster has successfully reconciled an apply operation.

https://github.com/kubernetes-sigs/kustomize/tree/master/kstatus


### functions 
Da bin ich noch nich sicher ob wir das brauchen:
https://github.com/kubernetes-sigs/kustomize/blob/master/cmd/config/docs/tutorials/function-basics.md

Damit kann man generator funktionen in einen Container auslagern, dieser muss die funktion config-function bereitstellen:
z.b. einfach ein shell script in einen busybox container kopieren:
https://github.com/kubernetes-sigs/kustomize/blob/master/functions/examples/template-heredoc-cockroachdb/image


## .gitlab-ci.yml

GitLab Template for buliding this Container
