class: center, bottom


.middle[![Kubernetes](http://localhost:8000/images/kubernetes.png)]

# Kubernetes for Developers


---


# Objective

Learn how you can use Kubernetes to deploy, scale and maintain applications without worrying about how the cluster works
and how all the pieces fit together.


--

### Why?
--

1. The most used container orchestrator in the market

--

1. It rocks!

--

1. It will make you a better developer


---

# How

Extreamly hands-on. We'll learn by trying

--

Incremental learning. One concept at a time

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

???
Rancher Labs: includes a Kubernetes distribution in its Rancher container management platform.
Pivotal: for its PKS product
Red Hat: OpenShift product
CoreOS: Tectonic
IBM: IBM Cloud Container Service
Oracle: a Kubernetes installer for Oracle Cloud Infrastructure and released Kubernetes on Oracle Linux.
Google: Google Cloud Kubernetes Enginer
Microsoft: Azure Kubernetes

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

WHAT IS A SCHEDULER :17:51 -  20:27
https://www.youtube.com/watch?v=u_iAXzy3xBA

---

# Let's setup minikube

- VirtualBox = https://www.virtualbox.org/wiki/Downloads
- kubectl = https://kubernetes.io/docs/tasks/tools/install-kubectl/
- minikube = https://kubernetes.io/docs/tasks/tools/install-minikube/


---

# WTF is a Pod?

- A group of one or more containers with shared storage/network and inter-process communication (IPC).

- Kubernetes primitive. The Smallest unit of work of k8s.

???

Containers within a pod share an IP address and port space, and can find each other via localhost

Containers in a Pod share the same IPC namespace, which means they can also communicate with each other using standard inter-process communications such as SystemV semaphores or POSIX shared memory.

---

# Hello World!

Let's run a pod :)

```
kubectl run -it busybox --image=busybox -- sh
```

???
What's going on

1 - Request sent to API
2 - Scheduler decisions

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
    app: nginx-app
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

# Multi Container Pod

- Shared storage
- Inter-process communication
- Shared network ip

???
https://medium.com/google-cloud/understanding-kubernetes-networking-pods-7117dd28727
https://www.ianlewis.org/en/almighty-pause-container

docker inspect --format '{{.HostConfig.NetworkMode}}' k8s_POD_writer_default_db11115b-14e2-11e8-8873-080027f2ca33_0

---

# Kubernetes Dashboard

```
minikube addons enable dashboard
```

Run:
```
kubectl proxy
```

Open http://127.0.0.1:8001/ui

???
Addons are pods and services that implement cluster features

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
# Kubernetes DNS Service

Kubernetes DNS schedules a DNS Pod and Service on the cluster, and configures the kubelets to tell individual containers to use the DNS Service’s IP to resolve DNS names

Every Service defined in the cluster (including the DNS server itself) is assigned a DNS name.

Service A record:

```
SERVICE_NAME.NAMESPACE_NAME.svc.cluster.local
```

Pod A record:

```
POD_IP.NAMESPACE_NAME.pod.cluster.local
```

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

Explain that kube-proxy is the node component that makes it possible to reach app

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

for node in $(kubectl get nodes -o template --template="{{range .items}} {{range .status.addresses}} {{if or (eq .type \"ExternalIP\") }} {{.address}} {{end}} {{end}} {{end}}"); do
  ssh -i ~/Documents/AvenueCode/ac-useast1-dev-shared.pem admin@$node nc -v localhost 31506
done

---

---
class: top, middle
layout: false
# How do I keep track of these ports? 

--

# Should I use one load balancer per app? 

???
Explain the idea of HAProxy outside cluster with consul tempalte

dynamic HAProxy in front of k8s confd/based on etcd

---
# Ingress

An Ingress is a collection of rules that allow inbound connections to reach the cluster services.

--

It can be configured to give services externally-reachable URLs, load balance traffic, terminate SSL, offer name based virtual hosting, and more.

--

An Ingress controller is responsible for fulfilling the Ingress, usually with a loadbalancer, though it may also configure your edge router or additional frontends to help handle the traffic in an HA manner.

---
# Ingress Example

```yml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: test
  annotations:
    ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: foo.bar.com
    http:
      paths:
      - path: /checkout
        backend:
          serviceName: checkout-svc
          servicePort: 80
      - path: /orders
        backend:
          serviceName: orders-svc
          servicePort: 80
      - path: /products
        backend:
          serviceName: catalog-svc
          servicePort: 80
```
---
# Ingress Controller

An app that will watch Ingress API and build the rules, serving as a sort of a fancy reverse proxy

--

**Common Implementations**

- HAProxy
- Google Ingress
- Nginx Ingress
- Traefik


???
minikube addons enable ingress

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
        imagePullPolicy: Always
        env:
        - name: APP_ENV
          value: Production
        ports:
        - containerPort: 8001
```

???
kubectl scale --replicas=5 rs/hello-k8s

kubectl get pods --watch

scale up/down showing the canary

while true; do curl http://192.168.99.100:31721/version; sleep 1; done

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

???
kubectl delete -f replicaset/

1. kubectl get rs -w
2. while :; do; kubectl rollout status deployment/hello-k8s-deployment; sleep 1; done
3. kubectl apply -f deployment/deployment-hello-k8s.yml
4. kubectl apply -f deployment/canary/

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

???
kubectl rollout pause deployment hello-k8s-deployment
kubectl rollout resume deployment hello-k8s-deployment

---

# Using Deployment for Canary Release strategy

How we could use the deployment workload to implement a canary release process?

--

Simple, let's create two deployments and use different labels!

???

1. kubectl apply -f deployment/canary/service.yml
1. kubectl apply -f deployment/canary/deployment.yml
1. kubectl apply -f deployment/canary/deployment-canary.yml
1. scale canary
1. rollout stable version to the new version
1. delete the canary deploymen

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

---
# Where k8s stores my config?

Inside ETCD

Kubernetes components are stateless and store cluster state in etcd.

--

etcd is a strong, consistent, and highly-available key value store which Kubernetes uses for persistent storage of all of its API objects. 

etcd usually runs as a real service inside all master hosts.

So yes, your configmap will be written inside ETCD! You're safe :)

---

# Don't tell me you keep your db password in scm

If you have sensitive information, you shouldn't use a **configmap**

--

Kubernetes has a built-in solution to host sensitive information.

---

# Secrets

A Secret is an object that contains a small amount of sensitive data such as a password, a token, or a key.

Such information might otherwise be put in a Pod specification or in an image; putting it in a Secret object allows for
more control over how it is used, and reduces the risk of accidental exposure.

--

Like Configmap's a secret can be mounted as a volume or env vars.


???
Create a secret via yaml. Show how to encode/decode

Create a generic secret:

kubectl create secret generic envs --from-env-file vars.env
kubectl create secret generic my-dirty-little-secret --from-file some-file --from-file some-other-file

---
class: top, middle
layout: false

# Storage

---

# Volumes

Volume as a way to mount non ephemeral data into a container.

At its core, a volume is just a directory, possibly with some data in it, which is accessible to the containers in a pod. How that directory comes to be, the medium that backs it, and the contents of it are determined by the particular volume type used.


???

Show volumes example

---

# Persistent Volume

The PersistentVolume subsystem provides an API for users and administrators that abstracts details of how storage is provided from how it is consumed. To do this we introduce two new API resources: PersistentVolume and PersistentVolumeClaim.

--

**PersistentVolume(PV)**

A piece of storage in the cluster that has been provisioned by an administrator.

PVs are volume plugins like Volumes, but have a lifecycle independent of any individual pod that uses the PV.

--

**PersistentVolumeClaim(PVC)**

A request for storage by a user.

Pods consume node resources and PVCs consume PV resoures. Pods can request specific levels of resources (CPU and Memory). Claims can request specific size and access modes (e.g., can be mounted once read/write or many times read-only).

---
# Provisioning PV

Two types

**Static**

A cluster administrator creates a number of PVs. They carry the details of the real storage which is available for use by cluster users.

--

**Dynamic**

When none of the static PVs the administrator created matches a user’s PersistentVolumeClaim, the cluster may try to dynamically provision a volume specially for the PVC. This provisioning is based on **StorageClasses**

---
# Lifecycle


1. A user creates a PVC, with a specific size

--

1. A control loop watches for PVC matching a PV if possible

--

1. Volume is mounted in a pod that requested the PVC

--

1. After pod deletion the PVC is deleted. Triggering the recyling policy

---

# Recycling

Recycling policy: Retain, Recycle, Delete

**Retain**

PV is not deleted the volume is considered "released". The PV can't be used again without manual intervention

--

**Recycle**

PV is not deleted but erased (rm -rf *). The PV is marked as available to new PVC

--

**Delete**

Removes the PV and the storage.

???
1 - Create static pv & pvc and pod
2 - Show dynamic example / Storage class
3 - Download storageclass and show then


---

class: top, middle
layout: false

# If everything is ephemeral, looks like there's no way to run my database in k8s, right?

--

# Actually, we can!

---
# StatefulSet

Like a Deployment, a StatefulSet manages Pods that are based on an identical container spec. Unlike a Deployment, a StatefulSet maintains a sticky identity for each of their Pods. These pods are created from the same spec, but are not interchangeable: each has a persistent identifier that it maintains across any rescheduling.

StatefulSets are valuable for applications that require one or more of the following.

 - Stable, unique network identifiers.
 - Stable, persistent storage.
 - Ordered, graceful deployment and scaling.
 - Ordered, graceful deletion and termination.
 - Ordered, automated rolling updates


???

1 - Create statefulset
1 - Show what happens when a statefulset is deleted
1 - Create the statefulset again show that the pvc will be still marked for us
1 - Add content to the volumes
1 - Create mongodb statefulset

---
class: top, middle
layout: false

# Health Checks. You should have one!

???
Show the problem
Deploy app that takes time to start to explain why we need probes
Scale the app to 4 pods to show that during the deployment you might have downtime

kubectl scale --replicas=4 deployment/slow-app
kubectl get pods -l app=slow -w
while :; do; curl http://192.168.99.100:31830/pod; echo "" ; sleep 1; done

---
# Pod Lifecycle

#### Phases

**Pending**
Scheduling not done, might be still downloading images, waiting for a node to accept the workload.

--

**Running**
Bound to a node, all containers created

--

**Succeeded**
All containers terminated in success and will not be restarted

--

**Failed**
All Containers in the Pod have terminated, and at least one Container has terminated in failure. Non zero status code

--

**Unknown**
For some reason the state of the Pod could not be obtained, typically due to an error in communicating with the host of the Pod.


---

# Probe

A Probe is a diagnostic performed periodically by the kubelet on a Container. To perform a diagnostic, the kubelet calls a Handler implemented by the Container

--

**ExecAction**

Executes a specified command inside the Container. The diagnostic is considered successful if the command exits with a status code of 0.

--

**TCPSocketAction**

Performs a TCP check against the Container’s IP address on a specified port. The diagnostic is considered successful if the port is open.

--

**HTTPGetAction**

Performs an HTTP Get request against the Container’s IP address on a specified port and path. The diagnostic is considered successful if the response has a status code greater than or equal to 200 and less than 400.

---
class: top, middle
layout: false

# Implementing Readness and Liveness Probe

???
Using the good-deployment.yml define the probes, scale to 4
read the logs of one of the apps and send a curl request meanwhile

---
class: top, middle
layout: false

# Quality of Service

---
# Requests & Limits

When you specify a Pod, you can optionally specify how much CPU and memory each Container needs. 

When Containers have resource requests specified, the scheduler can make better decisions about which nodes to place Pods on

--

**Resource Types**

**CPU**

Measure in cpu units where 1=1vCPU

CPU is always requested as an absolute quantity, never as a relative quantity; 0.1 is the same amount of CPU on a single-core, dual-core, or 48-core machine.


**Memory**

Measured in bytes, can be expressed in different formats:

```
128974848, 129e6, 129M, 123Mi
```

---
# Requests & Limits

**Requests**

A soft limit, when you define a request value you're describing that you need at least this amount to operate. The system will guarantee this amount.

Scheduling decisions are based on requests!

**Limits**

A hard limit, when you define a limit you're defining the maximum amount that the system will allow you to use

---

# What happens when they exceed their limits?

It depends whether the resource is compressible or incompressible

--

**CPU**

Pods will be throttled if they exceed their limit. If limit is unspecified, then the pods can use excess CPU when available.

--

**Memory**

 Pods will get the amount of memory they request, if they exceed their memory request, they could be killed (if some other pod needs memory).

 When Pods use more memory than their limit, a process that is using the most amount of memory, inside one of the pod's containers, will be killed by the kernel.


If k8s runs out of CPU or memory resources (where sum of limits > machine capacity). Ideally, it should kill containers **that are less important**.

---

# QoS Classes

**Guaranteed**

When you specify limits + requests and their value is equal.

Pods are considered **top-priority** and are guaranteed to not be killed until they exceed their limits.

**Example**

**Requests**
Memory=128Mi
CPU=0.2

**Limits**
Memory=128Mi
CPU=0.2

---
# QoS Classes

**Burstable**

When you specify requests and optionally limits for one or more resources across one or more containers, and they are not equal

When limits are not specified, **they default to the node capacity**.

They have a **minimal resource guarantee**, but can use more resources when available.

Under system memory pressure, these containers are more likely to be killed once they exceed their requests **if there are no pods with less priority**

**Example**

**Requests**
Memory=128Mi
CPU=0.1

**Limits**
Memory=256Mi
CPU=0.2

---
# QoS Classes

**Best Effort**

If requests and limits are not set for all of the resources, across all containers, then the pod is classified as Best-Effort.

They have a **minimal resource guarantee**, but can use more resources when available.

Pods will be treated as lowest priority. Processes in these pods are the first to get killed if the system runs out of memory.

???
Deploy an application, change the requests && limits and show it operating
Show how slow the app can be when it's throtled

---
# Horizontal Pod Autoscaling

Horizontal Pod Autoscaler automatically scales the number of pods in a deployment or replica set based on observed CPU utilization (or, with beta support, on some other, application-provided metrics).

???
minikube addons enable heapster
slow-app
kubectl autoscale deployment slow-app --cpu-percent=40 --min=1 --max=6

send traffic

kubectl run -i --tty load-generator --image=busybox /bin/sh
while true; do wget -q -O- http://slow-app.default.svc.cluster.local/pod; done

brew update && brew install vegeta

echo "GET  http://192.168.99.100:31830/" | vegeta attack -rate=10 -duration=120s | tee results.bin | vegeta report
---

# Cron Jobs
# Deamon Set?