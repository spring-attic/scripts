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
Starbucks locations. The customers app is empty to start 9and uses an
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
