![Open Liberty logo](https://github.com/OpenLiberty/logos/blob/main/combomark/png/OL_logo_green_on_white.png)

# Deploying Open Liberty Getting Started sample to AWS with Knative

Use the following steps to deploy the Open Liberty Getting Started sample to AWS with Knative.  The steps assume you have the setup necessary to deploy to an AWS cluster as shown in [Deploying microservices to Amazon Web Services](https://openliberty.io/guides/cloud-aws.html#pushing-the-images-to-a-container-registry).

## Build the Application

### Build the application WAR
```
mvn package
```
### build the application container image
```
./build-og.sh
```
### Add the InstantOn layer to the application container image
```
./build-instanton.sh
```
### Run the InstantOn application locally
```
./run-instanton.sh
```
Browse the application at http://localhost:9080/

## Deploy the Application to AWS with Knative

### Create a cluster
Run the following and give the cluster a name with a command like the following to give the cluster the name `instanton-getting-started`
```
./create-cluster.sh -n instanton-getting-started
```
This can take around 15 minutes to complete.

### Configure Knative with the new cluster
Run the following command to apply the necessary resources to use Knative.  Knative will be used to scale-to-zero the deployed application in the AWS cluster.
```
./configure-knative.sh
```

### Create two repositories for the application image
Two repositories will be used on Amazon ECR in order to deploy the original container image without InstantOn and the container image with InstantOn.
```
aws ecr create-repository --repository-name getting-started
aws ecr create-repository --repository-name getting-started-instanton
```
In the output of this command, note the `repositoryUri` values. They should match the `<aws_account_id>.dkr.ecr.<region>.amazonaws.com/getting-started` and the `<aws_account_id>.dkr.ecr.<region>.amazonaws.com/getting-started-instanton` patterns. For example: 1234567890.dkr.ecr.us-east-1.amazonaws.com/getting-started-instanton. These values are needed to deploy the applications.

### Push the images to Amazon ECR
Next, authenticate to the registry using the following command so you can push or pull images using Podman.  Replase `<aws_account_id>` and `<region>` with the values from the `repositoryUri` when you created the repositories:

```
aws ecr get-login-password | sudo podman login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
```
After you are authenticated, you can tag and push the InstantOn image to the private ECR registry:

```
sudo podman tag dev.local/getting-started-instanton <aws_account_id>.dkr.ecr.<region>.amazonaws.com/getting-started-instanton
sudo podman push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/getting-started-instanton
```

### Deploy the InstantOn application
The `deployment-to-knative.sh` script can be used to deploy the InstantOn application to AWS using KNative in the cluster you just created.  The scipt takes an image name and a repository host as parameters.  For example:
```
sudo deployment-to-knative.sh -i getting-started-instanton -h <aws_account_id>.dkr.ecr.<region>.amazonaws.com
```
After this has been deployed run the following `kubectl` command to find the URL to access the application:
```
kubectl get kservice
```
The value for the URL can be used in a browser to access the application.  Before access the applications check to see if the pods associated with the application have scaled-to-zero:
```
kubectl get pods
```
The message `No resources found in default namespace.` indicates that the application has scaled-to-zero.  If you access the application using the URL from `kubectl get kservice` then Knative will spin up a new pod to service the request.  After accessing the application run the following command using the name of the image you created.  For example, if you used an image name `getting-started-instanton`:
```
kubectl logs -l app=getting-started-instanton --tail=-1
```
This will show the log from spinning up the application:
```
[AUDIT   ] CWWKZ0001I: Application io.openliberty.sample.getting.started started in 0.189 seconds.
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://getting-staa0748dbd7289d99209656da1c02f850c-deplosqxgb:9080/health/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://getting-staa0748dbd7289d99209656da1c02f850c-deplosqxgb:9080/metrics/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://getting-staa0748dbd7289d99209656da1c02f850c-deplosqxgb:9080/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://getting-staa0748dbd7289d99209656da1c02f850c-deplosqxgb:9080/ibm/api/
[AUDIT   ] CWWKC0452I: The Liberty server process resumed operation from a checkpoint in 0.285 seconds.
[AUDIT   ] CWWKF0012I: The server installed the following features: [cdi-2.0, checkpoint-1.0, distributedMap-1.0, jaxrs-2.1, jaxrsClient-2.1, jndi-1.0, json-1.0, jsonp-1.1, monitor-1.0, mpConfig-2.0, mpHealth-3.1, mpMetrics-3.0, servlet-4.0, ssl-1.0].
[AUDIT   ] CWWKF0011I: The defaultServer server is ready to run a smarter planet. The defaultServer server started in 0.363 seconds.

```
Calling `kubectl get pods` will show the state of the pod again.  If you wait for a minute or so you will notice the pod will terminate again.  Browsing the application once again will cause a new pod to get created.
