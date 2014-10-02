The
[spring-cloud-samples](https://github.com/spring-cloud-samples)
can be run as a demo locally by just cloning the individual projects
and running them. This project can be used to manage updating and
deploying the sample apps to cloudfoundry.

## Running Locally

Pre-requisites: Maven (3) and Java (1.7). To run the
Customers UI you also need the Spring Boot CLI. Clone the repository
and initialize submodules:

```
$ git clone https://github.com/spring-cloud-samples/scripts
$ cd scripts
$ ./build.sh
```

(You can add '-DskipTests' if you like, or just use 'mvn' directly,
once the submodules are initialized.)

You also nee Mongodb and RabbitMQ. If you don't have those, and you do
have Docker, you can run them in Docker (via [fig](http://www.fig.sh/)):

```
$ fig up
...
<mongo starts up>
<rabbit starts up>
```

the containers for the server processes write their data locally in
`./data`. Those files will be owned by root, so watch out when it
comes to remove them.

Run the apps:

```
$ ./run.sh
```

You can kill the processes using `./kill.sh`, and both scripts know how to operate on individual apps or subsets, e.g. (the default):

```
$ ./run.sh configserver eureka customers stores
```

To run the UI with the maps, get the Spring Boot CLI, and install the
platform CLI plugin, e.g. with GVM:

```
$ gvm install springboot 1.1.5.RELEASE
$ gvm use springboot 1.1.5.RELEASE
```

then get the install command plugin (backported from Boot 1.2.0):

```
$ wget http://dl.bintray.com/dsyer/generic/install-0.0.1.jar
```

install it in the Spring Boot CLI, e.g. with GVM (MacOS users that rely on brew might have to find the `/lib` directory by scanning `brew info springboot`):

```
$ cp install-0.0.1.jar ~/.gvm/springboot/1.1.5.RELEASE/lib
```

and finally install the Spring Cloud plugin:

```
$ spring install org.springframework.cloud:spring-cloud-cli:1.0.0.BUILD-SNAPSHOT
```

Then run the app

```
$ (cd customers-stores/customers-ui; spring run app.groovy)
```

## Running on Cloudfoundry

Pre-requisites: the `cf` command line, Maven (3) and Java (1.7).
Clone the repository and initialize submodules:

```
$ git clone https://github.com/spring-cloud-samples/scripts
$ cd scripts
$ ./build.sh
$ ./services_deploy.sh
$ ./demo_deploy.sh
```

The result should be a bunch of apps running in the default space for
your default org, with names prefixed by your local userid, e.g.

```
$ cf apps
...
dsyerconfigserver      started  1/1  512M  1G    dsyerconfigserver.cfapps.io
dsyereureka            started  1/1  512M  1G    dsyereureka.cfapps.io
dsyercustomers         started  1/1  512M  1G    dsyercustomers.cfapps.io
dsyerstores            started  1/1  512M  1G    dsyerstores.cfappps.io
...
```

The `configserver` and `eureka` apps will have been registered as user
provided services, and bound to the other apps:

```
$ cf services
...
name                 service        plan  bound apps   
dsyerconfigserver   user-provided        dsyercustomers, dsyereureka, dsyerstores   
dsyereureka         user-provided        dsyerconfigserver, dsyercustomers, dsyerstores   
...
```

You can check that it is all working by pinging the `eureka` app
endpoints and seeing the other apps registered. E.g. visit
[http://dsyereureka.cfapps.io/v2/apps](http://dsyereureka.cfapps.io/v2/apps)
in a browser. Other useful links for diagnosis and investigating
what's going on:

* [http://dsyerconfigserver.cfapps.io/customers/cloud](http://dsyerconfigserver.cfapps.io/customers/cloud)
* [http://dsyercustomers.cfapps.io/env](http://dsyercustomers.cfapps.io/env)
* [http://dsyerstores.cfapps.io/env](http://dsyerstores.cfapps.io/env)

The stores app comes pre-populated with a Mongo database full of
Starbucks locations. The customers app is empty to start (and uses an
in-memory database) so you have to POST some data into it, e.g.

```
$ curl -i -H "Content-Type: application/json" http://dsyercustomers.cfapps.io/customers -d @customers-stores/rest-microservices-customers/src/test/resources/customers.json
```

Then when you visit the customers app at
[http://dsyercustomers.cfapps.io/customers](http://dsyercustomers.cfapps.io/customers)
you shoudl see a customer (Ollie) and a link to nearby stores. If the
stores app did not register with eureka, or if you stop the the stores
app intentionally (`cf stop ...`), then the stores link will be
missing in the customers app (simple example of a circuit breaker).

Sometimes it is also useful to undeploy the services (and unbind them
from apps etc.), and redeploy them:

```
$ ./services_undeploy.sh
$ ./services_deploy.sh
$ ./demo_deploy.sh
```

It should all work on [Pivotal Web Services](https://run.pivotal.io),
by default, or on any Cloudfoundry instance (e.g. PCF or a local
single VM instance) if you set the `DOMAIN` environment variable to
the DNS domain that the service is running in.

To run on [bosh-lite](https://github.com/cloudfoundry/bosh-lite)

Deploy mongodb using https://github.com/cloudfoundry-community/cf-services-contrib-release

```
export DOMAIN=10.244.0.34.xip.io
export PLATFORM_HOME=/Users/sgibb/workspace/spring/spring-cloud-samples #where all spring-cloud-samples are checked out
export MONGO_URI=mongodb://192.168.50.1/stores #mongo running on host #TODO install mongo as a service
```
