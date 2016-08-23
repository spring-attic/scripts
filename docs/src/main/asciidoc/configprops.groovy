/**
 * Run this file with groovy and collect the result as an asciidoctor source file:
 * <pre>
 * $ groovy configprops.groovy | egrep -v PathMatchingResourcePatternResolver | tee configprops.adoc
 * </pre>
 */

@Grab('org.codehaus.groovy:groovy-json:2.4.3')
@Grab('org.springframework.cloud:spring-cloud-starter-eureka:1.1.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-starter-sleuth:1.0.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-netflix-eureka-server:1.1.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-starter-config:1.1.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-starter-bus-amqp:1.1.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-starter-stream-rabbit:1.0.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-starter-consul-all:1.0.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-starter-zookeeper-all:1.0.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-starter-security:1.1.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-starter-cloudfoundry:1.0.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-cloudfoundry-discovery:1.0.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-cluster-autoconfigure:1.0.0.BUILD-SNAPSHOT')
@Grab('org.springframework.cloud:spring-cloud-starter-contract:1.0.0.BUILD-SNAPSHOT')

import org.springframework.core.io.support.PathMatchingResourcePatternResolver
import org.springframework.core.io.Resource
import groovy.json.JsonSlurper

def resources = new PathMatchingResourcePatternResolver().getResources("classpath*:/META-INF/spring-configuration-metadata.json")

TreeSet names = new TreeSet()
def descriptions = [:]
resources.each { it ->
  if (it.url.toString().contains("cloud")) {
    def slurper = new JsonSlurper()
    slurper.parseText(it.inputStream.text).properties.each { val ->
      names.add val.name
      descriptions[val.name] = new ConfigValue(val.name, val.description, val.defaultValue)
    }
  }
}
println "|==="
println "|Name | Default | Description"
println ""
names.each { it ->
  println descriptions[it]
  println ""
}
println "|==="


class ConfigValue {
  String name
  String description
  Object defaultValue
  ConfigValue(){}
  ConfigValue(String name, String description, Object defaultValue) {
    this.name = name
    this.description = description
    this.defaultValue = defaultValue
  }
  String toString() {
    def value = defaultValue==null?'':"${defaultValue}"
    "|${name} | ${value} | ${description?:''}"
  }
}
