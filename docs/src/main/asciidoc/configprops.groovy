/**
 * Run this file with groovy and collect the result as an asciidoctor source file:
 * <pre>
 * $ groovy configprops.groovy | egrep -v PathMatchingResourcePatternResolver | tee configprops.adoc
 * </pre>
 */

@GrabResolver(name='milestone', root='http://repo.spring.io/milestone/')
@Grab('org.codehaus.groovy:groovy-json:2.5.0')
@Grab('org.codehaus.groovy:groovy-nio:2.5.0')
@Grab('org.codehaus.groovy:groovy-xml:2.5.0')
@Grab('org.springframework.cloud:spring-cloud-stream:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-bus-amqp:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-config:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-config-server:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-netflix-eureka-server:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-netflix-eureka-client:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-aws:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-security:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-consul-all:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-zookeeper-all:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-sleuth:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-cloudfoundry:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-cloudfoundry-discovery:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-contract-stub-runner:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-vault-config:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-vault-config-aws:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-vault-config-databases:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-vault-config-consul:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-vault-config-rabbitmq:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-starter-gateway:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-gateway-mvc:2.0.0.RELEASE')
@Grab('org.springframework.cloud:spring-cloud-gateway-webflux:2.0.0.RELEASE')

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
