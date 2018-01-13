class: center, bottom


# Kubernetes - the Easy way

---


# Objective

Learn how Kubernetes works


Approach:

- Kubernetes Architecture

--

### Why?
--

1. The most used container orchestrator in the market
--

1. It rocks!
--


---

# How

Extreamly hands-on. We learn by trying

Incremental

???
Not at lot of concepts in the first day. Only the necessary

---
# What is a Container Orchestrator

- Manage my container, I don't care where!

--

- Scale if I ask you to scale

--

- Honor the contract (App x Orchestrator)

--

- Make good use of hardware resources

---

# What is Kubernetes

Kubernetes is an open-source platform designed to automate deploying, scaling, and operating application containers.

With Kubernetes, you are able to quickly and efficiently respond to customer demand:

- Deploy your applications quickly and predictably.
- Scale your applications on the fly.
- Roll out new features seamlessly.
- Limit hardware usage to required resources only

---
class: top, right, fit-image
layout: false
background-image: url(http://localhost:8000/images/kube-arch-0.jpg)

---
class: top, right, fit-image
layout: false
background-image: url(http://localhost:8000/images/kube-node.svg)

???

Kubelet = Watch APIServer && Execute workload assigned to it's node
Docker = Container runtime solution

---

# Let's setup minikube

Do minikube setup

---

# WTF is a Pod?

- A group of one or more containers with shared storage/network.

- Smallest unit  of work of k8s.

???

Containers within a pod share an IP address and port space, and can find each other via localhost

---

# Hello World!

Let's run a pod :)

```
kubectl run -it busybox --image=busybox -- sh
```

---

# Pod Facts

- Pods are ephemeral!

They won’t survive scheduling failures, node failures, or other evictions, such as due to lack of resources, or in the case of node maintenance.

We should **never** create pods directly for our apps!

---

# Creating a Pod using a manifest

Everything inside Kubernetes can be created/updated/deleted using a YAML manifest

Let's go back to our nginx pod.

```yml
echo "
apiVersion: v1
kind: Pod
metadata:
  name: nginx-app
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx
      ports:
        - containerPort: 80
" | kubectl create -f -
```

???
kubectl get pod/nginx-app -o yaml
kubectl port-forward
kubectl exec -it
Copy custom index.html
kubectl cp nginx_index.html nginx-app-54688d7d54-l62lz:/usr/share/nginx/html/index.html

---

# Kubernetes Dashboard

```
minikube addons enable dashboard
```

Run:
```
kubectl proxy
```

Open http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#!/

---

# Micro services and Kubernetes

Think about different micro-services. They are separate entities, therefore need to be placed into separate pods.

We don't want to setup the communication pod x pod, right?

--

Looks like we need a different object!

--

A **service**.

???


---

# Services

A Kubernetes Service is an abstraction which defines a logical set of Pods and a policy by which to access them - sometimes called a micro-service.

--

Think of a Service as the virtual entrypoint of a piece of your application or like some kind of built-in load balancer.

--

A service can also be used to expose application to the outside world.

We can't access our nginx container, only with port-forward!

To expose our app inside kubernetes we'll also need to define a service.

---

# Service Example

```yml
kind: Service
apiVersion: v1
metadata:
  name: nginx-app
spec:
  selector:
    app: nginx-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```
---

# Service Types

**ClusterIP**

Exposes the service on a cluster-internal IP. Choosing this value makes the service only reachable from within the cluster.

--

**NodePort**

Exposes the service on each Node’s IP at a static port (the NodePort).

A ClusterIP service, to which the NodePort service will route, is automatically created.

--

**LoadBalancer**

Exposes the service externally using a cloud provider’s load balancer. NodePort and ClusterIP services, to which the external load balancer will route, are automatically created.

--

**ExternalName**

Maps the service to the contents of the externalName field (e.g. foo.bar.example.com), by returning a CNAME record with its value. No proxying of any kind is set up.

---
# Let's create a NodePort Service

```yml
kind: Service
apiVersion: v1
metadata:
  name: nginx-app
spec:
  type: NodePort
  selector:
    app: nginx-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

Find minikube IP:

```
minikube ip
```

???
http://127.0.0.1:8001/api/v1/proxy/namespaces/default/services/nginx-app/#!/

http://192.168.99.100:30839/

---

ExternalName:
```yml
kind: Service
apiVersion: v1
metadata:
  name: my-service
  namespace: prod
spec:
  type: ExternalName
  externalName: my.database.example.com
```

---

# Scaling :)

So far we've been running our app in a single pod.

How do we scale?

Of course, we need a new object !

---
# Replica Set

A ReplicaSet ensures that a specified number of pod replicas are running at any one time. In other words, a ReplicaSet makes sure that a pod or a homogeneous set of pods is always up and available.

```yml
apiVersion: apps/v1beta2
kind: ReplicaSet
metadata:
  name: hello-k8s
  labels:
    app: hello-k8s
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-k8s
  template:
    metadata:
      labels:
        app: hello-k8s
    spec:
      containers:
      - name: hello-k8s
        image: bernardovale/hello-k8s:1.0
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        env:
        - name: APP_ENV
          value: Production
        ports:
        - containerPort: 8001
```

???
kubectl scale --replicas=5 rc/hello-k8s
kubectl get pods --watch

scale up/down showing the canary
while :; do curl http://192.168.99.100:31232/version; sleep 1; done

---
# There must be a better way

Rolling out a new version using ReplicaSets wasn't the coolest thing ever.

Imagine managing this rollout process among several apps, it ain't cool!

That's why we need another object!

--

A **Deployment**!

---
# Deployment

A Deployment controller provides declarative updates for Pods and ReplicaSets.

You describe a desired state in a Deployment object, and the Deployment controller changes the actual state to the desired state at a controlled rate.

---
1. kubectl get rs -w
2. while :; do; kubectl rollout status deployment/hello-k8s-deployment; sleep 1; done
3. kubectl apply -f specs/deployment/deployment-hello-k8s.yml

---
# Shit Happens, how can we rollback?

Deployment by default tracks history of all rollouts.

```
kubectl rollout history deployment/hello-k8s-deployment
```

Let's rollback our deployment!

???
kubectl rollout history deployment/hello-k8s-deployment
kubectl rollout history deployment/hello-k8s-deployment --revision 2
kubectl rollout undo deployment/hello-k8s-deployment
or
kubectl rollout undo deployment/hello-k8s-deployment  --to-revision=2

---
# Deployment Strategy

**MaxSurge**

The maximum number of Pods that can be created over the desired number of Pods

**MaxUnavailable**

The maximum number of Pods that can be unavailable during the update process.

---

# Using Deployment for Canary Release strategy

How we could use the deployment workload to implement a canary release process?

--

Simple, let's create two deployments and use different labels!

---

# Decopling Configuration from your app

Twelve-factor app:

III Config: Store config in the environment

---

# ConfigMap

ConfigMaps allow you to decouple configuration artifacts from image 
content to keep containerized applications portable.

--

Based on your needs a configmap can be injected in runtime as:

  - Env variables
  - Files

???
simple file: kubectl create configmap hello-k8s-prod --from-file settings-prod.cfg

Show an example with a directory:

create configmap hello-k8s-prod --from-file config_dir

Show env_var example