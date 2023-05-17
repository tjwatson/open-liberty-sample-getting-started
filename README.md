![Open Liberty logo](https://github.com/OpenLiberty/logos/blob/main/combomark/png/OL_logo_green_on_white.png)

# Open Liberty Getting Started sample

## Overview
The sample application provides a simple example of how to get started with Open Liberty. It provides a REST API that retrieves the system properties in the JVM and a web based UI for viewing them. It also uses MicroProfile Config, MicroProfile Health and MicroProfile Metrics to demonstrate how to use these specifications in an application that maybe deployed to kubernetes.

## Project structure

- `src/main/java` - the Java code for the Project
  - `io/openliberty/sample`
    - `config`
      - `ConfigResource.java` - A REST Resource that exposes MicroProfile Config via a /rest/config GET request
      - `CustomConfigSource.java` - A MicroProfile Config ConfigSource that reads a json file.
    - `system`
      - `SystemConfig.java` - A CDI bean that will report if the application is in maintenance. This supports the config variable changing dynamically via an update to a json file.
      - `SystemHealth.java` - A MicroProfile Health check that reports DOWN if the application is in maintenance and UP otherwise.
      - `SystemResource.java` - A REST Resource that exposes the System properties via a /rest/properties GET request. Calls to this GET method have MicroProfile Timer and Count metrics applied.
      - `SystemRuntime.java` - A REST Resource that exposes the version of the Open Liberty runtime via a /rest/runtime GET request.
    - `SystemApplication.java` - The Jakarta RESTful Web Services Application class
  - `liberty/config/server.xml` - The server configuration for the liberty runtime
  - `META-INF` - Contains the metadata files for MicroProfile Config including how to load CustomConfigSource.java
  - `webapp` - Contains the Web UI for the application.
  - `test/java/it/io/openliberty/sample/health`
    - `HealthIT.java` - Test cases for a sample application running on `localhost`
    - `HealthUtilIT.java` - Utility methods for functional tests
- `resources/CustomConfigSource.json` - Contains the data that is read by the MicroProfile Config ConfigSource.
- `Dockerfile` - The Dockerfile for building the sample
- `pom.xml` - The Maven POM file

## Build and Run the Sample locally

Clone the project

```
git clone https://github.com/OpenLiberty/sample-getting-started.git
```

then build and run it using Liberty dev mode:

```
mvnw liberty:dev
```

if you just want to build it run:

```
mvnw package
```

## Run the Sample in a container

To run the sample using docker run:

```
docker run -p 9080:9080 icr.io/appcafe/open-liberty/samples/getting-started
```

To run the sample using podman run:

```
podman run -p 9080:9080 icr.io/appcafe/open-liberty/samples/getting-started
```


### Access the application
Open a browser to http://localhost:9080

![image](https://user-images.githubusercontent.com/3076261/117993383-4f34c980-b305-11eb-94b5-fa7319bc2850.png)

## Run the functional tests

The test cases uses [JUnit 5](https://junit.org/junit5/) and 
[Maven Failsafe Plugin](https://maven.apache.org/surefire/maven-failsafe-plugin/index.html) defined 
in [`pom.xml`](pom.xml).

> Note: Sample appplication must be running on `http://localhost` before running the test cases. 
> <br>
> See [`HealthUtilIT.java`](src/test/java/it/io/openliberty/sample/health/HealthUtilIT.java) to change 
> the change the sample application target URL.

To run the test cases against a running sample application, use the following command
```
mvnw failsafe:integration-test
```

To view the test results, look at the console output or look under 
directory  `target/failsafe-reports`

## Instanton with AWS EKS and Knative

### Build the application WAR
```
mvn package
```
### Containerize the Application with InstantOn
For demo purposes we will create two containers, one without InstantOn and one that adds a layer with InstantOn for the application.  There are two Dockerfiles for doing this.  The original `Dockerfile` which does the typical steps to containerize the Open Liberty application:
```
FROM icr.io/appcafe/open-liberty:beta-instanton
ARG VERSION=1.0
ARG REVISION=SNAPSHOT

COPY --chown=1001:0 src/main/liberty/config/ /config/
COPY --chown=1001:0 resources/ /output/resources/
COPY --chown=1001:0 target/*.war /config/apps/

RUN configure.sh
```
Then there is the `Dockerfile.instanton` which adds one more layer with an additonal step at the end to do the checkpoint at `applications`:

```
FROM icr.io/appcafe/open-liberty:beta-instanton
ARG VERSION=1.0
ARG REVISION=SNAPSHOT

COPY --chown=1001:0 src/main/liberty/config/ /config/
COPY --chown=1001:0 resources/ /output/resources/
COPY --chown=1001:0 target/*.war /config/apps/

RUN configure.sh

RUN checkpoint.sh applications
```

To build the original application container without InstantOn run the followoing:

```
./build-og.sh
```
After that completes then run the following to build the InstantOn layer:
```
./build-onestep-instanton.sh
```
When building the InstantOn image you will notice it reusing the layers created from the original application image and only adding one new layer that containers the checkpoint for the applcation.

### Run the Application Containers Locally

Now you can run the applications locally using `podman`.  When they are started you can access the application at: http://localhost:9080/

#### Running the original Application
```
./run-og.sh
```
This typically comes up in 5 seconds.

#### Running the InstantOn Application
```
./run-instanton.sh
```
This typically comes up in less than 500 milliseconds.  You can look at the `/run-instanton.sh` for the additional Linux capabilities that had to be set for the application to restore successfully.

### Setup an AWS Cluster with Knative

Next setup your AWS credentials such that you can create clusters on AWS EKS and push application images to ECS (Container registry) by following the steps from the Open Liberty InstantOn AWS blog: https://openliberty.io/blog/2023/02/20/aws-instant-on.html
After setting up your AWS account and credentials run:
```
./create-cluster.sh -n <your cluster name>
```
This will take 15 to 20 minutes to create your cluster.  After you verified your cluster is up you need to provision Knative to the cluster by running the following script:

### Deploy Knative to Your Cluster

```
./configure-knative.sh
```
### Push Your Application Images to ECR

Then push your two applications to ECR with tags you have available in ECR.  For example, with image names like this `XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/getting-started` and `XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/getting-started-instanton`

### Deploy Your Two Applications to Your Cluster

Then you would run:
```
./deployment-to-knative.sh -h XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com -i getting-started
./deployment-to-knative.sh -h XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com -i getting-started-instanton
```

### Discover Your Two Application Endpoint URLs

Once it is all deployed you use kubectl get kservice to find the endpoints URL, for example:
````
# kubectl get kservice
NAME                                 URL                                                                        LATESTCREATED                              LATESTREADY                                READY   REASON
getting-started             http://getting-started.default.x.xxx.xxx.xxx.sslip.io             getting-started-00001             getting-started-00001             True    
getting-started-instanton   http://getting-started-instanton.default.x.xxx.xxx.xxx.sslip.io   getting-started-instanton-00001   getting-started-instanton-00001   True
````
The two URLs are what you hit to bring the apps up:

http://getting-started.default.x.xxx.xxx.xxx.sslip.io

http://getting-started-instanton.default.x.xxx.xxx.xxx.sslip.io

To see the pods running or not:
```
# kubectl get pods
NAME                                                              READY   STATUS    RESTARTS   AGE
getting-started-00001-deployment-57548d6594-5cvww        1/2     Running   0          9s
getting-started-instanton-00001-deployment-5f68d4dtxwx   2/2     Running   0          16s
```
If the pods are still running you can look at the logs, for example:
```
kubectl logs getting-started-instanton-00001-deployment-5f68d4t56gb
Defaulted container "app" out of: app, queue-proxy

[AUDIT   ] CWWKZ0001I: Application io.openliberty.sample.getting.started started in 0.238 seconds.
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://tjwatson-getting-started-instanton-00001-deployment-5f68d4t56gb:9080/metrics/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://tjwatson-getting-started-instanton-00001-deployment-5f68d4t56gb:9080/health/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://tjwatson-getting-started-instanton-00001-deployment-5f68d4t56gb:9080/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://tjwatson-getting-started-instanton-00001-deployment-5f68d4t56gb:9080/ibm/api/
[AUDIT   ] CWWKC0452I: The Liberty server process resumed operation from a checkpoint in 0.335 seconds.
[AUDIT   ] CWWKF0012I: The server installed the following features: [cdi-2.0, checkpoint-1.0, distributedMap-1.0, jaxrs-2.1, jaxrsClient-2.1, jndi-1.0, json-1.0, jsonp-1.1, monitor-1.0, mpConfig-2.0, mpHealth-3.1, mpMetrics-3.0, servlet-4.0, ssl-1.0].
[AUDIT   ] CWWKF0011I: The defaultServer server is ready to run a smarter planet. The defaultServer server started in 0.364 seconds.
```

At this point you can wait for the applications to scale-to-zero.  Here Knative is configured to do that after about 30 seconds of inactivity.  Confirm you have no running pods with `kubectl get pods`.  If there are no pods running then Knative will have to startup a new pod when a new request comes in.  Now you can observe the differences in response time between the two applications.
