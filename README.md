The
[spring-platform-samples](https://github.com/spring-platform-samples)
can be run as a demo locally by just cloning the individual projects
and running them. This project can be used to manage updating and
deploying the sample apps to cloudfoundry. 

Pre-requisites: the `cf` command line, Maven (3) and Java (1.7).
Clone the repository and initialize submodules:

```
$ git clone https://github.com/spring-platform-samples/scripts
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
dsyer-configserver      started  1/1  512M  1G    dsyer-configserver.cfapps.io
dsyer-eureka            started  1/1  512M  1G    dsyer-eureka.cfapps.io
dsyer-customers         started  1/1  512M  1G    dsyer-customers.cfapps.io
dsyer-stores            started  1/1  512M  1G    dsyer-stores.cfappps.io
...
```

The `configserver` and `eureka` apps will have been registered as user
provided services, and bound to the other apps:

```
$ cf services
...
name                 service        plan  bound apps   
dsyer-configserver   user-provided        dsyer-customers, dsyer-eureka, dsyer-stores   
dsyer-eureka         user-provided        dsyer-configserver, dsyer-customers, dsyer-stores   
...
```

You can check that it is all working by pinging the `eureka` app
endpoints and seeing the other apps registered. E.g. visit
[http://dsyer-eureka.cfapps.io/v2/apps](http://dsyer-eureka.cfapps.io/v2/apps)
in a browser. Other useful links for diagnosis and investigating
what's going on:

* [http://dsyer-configserver.cfapps.io/customers/cloud](http://dsyer-configserver.cfapps.io/customers/cloud)
* [http://dsyer-customers.cfapps.io/env](http://dsyer-customers.cfapps.io/env)
* [http://dsyer-stores.cfapps.io/env](http://dsyer-stores.cfapps.io/env)

The stores app comes pre-populated with a Mongo database full of
Starbucks locations. The customers app is empty to start 9and uses an
in-memory database) so you have to POST some data into it, e.g.

```
$ curl -i -H "Content-Type: application/json" http://dsyer-customers.cfapps.io/customers -d @customers-stores/rest-microservices-customers/src/test/resources/customers.json
```

Then when you visit the customers app at
[http://dsyer-customers.cfapps.io/customers](http://dsyer-customers.cfapps.io/customers)
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
