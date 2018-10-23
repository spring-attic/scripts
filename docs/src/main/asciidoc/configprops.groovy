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
@Grab('org.springframework:spring-core:5.1.1.RELEASE')

import org.springframework.core.io.support.PathMatchingResourcePatternResolver
import groovy.grape.Grape
import groovy.json.JsonSlurper

String outputFile = "configprops.adoc"

Map<String, List<String>> modules = [
  "spring-cloud-stream" : ["spring-cloud-stream"],
  "spring-cloud-bus" : ["spring-cloud-starter-bus-amqp"],
  "spring-cloud-config" : ["spring-cloud-starter-config", "spring-cloud-config-server"],
  "spring-cloud-netflix" : ["spring-cloud-starter-netflix-eureka-server", "spring-cloud-starter-netflix-eureka-client"],
  "spring-cloud-aws" : ["spring-cloud-starter-aws"],
  "spring-cloud-security" : ["spring-cloud-starter-security"],
  "spring-cloud-consul" : ["spring-cloud-starter-consul-all"],
  "spring-cloud-zookeeper" : ["spring-cloud-starter-zookeeper-all"],
  "spring-cloud-sleuth" : ["spring-cloud-starter-zipkin"],
  "spring-cloud-cloudfoundry" : ["spring-cloud-starter-cloudfoundry", "spring-cloud-cloudfoundry-discovery"],
  "spring-cloud-contract" : ["spring-cloud-starter-contract-stub-runner"],
  "spring-cloud-vault" : ["spring-cloud-vault-config", "spring-cloud-vault-config-aws", "spring-cloud-vault-config-databases", "spring-cloud-vault-config-consul", "spring-cloud-vault-config-rabbitmq"],
  "spring-cloud-gateway" : ["spring-cloud-starter-gateway", "spring-cloud-gateway-mvc", "spring-cloud-gateway-webflux"],
  "spring-cloud-stream" : ["spring-cloud-stream-dependencies"],
]

File versionsFile = new File("versions.txt")

if (versionsFile.exists()) {
  println "Found versions file with versions \n\n${versionsFile.text}\n\n"
  println "Grabbing all versions"
  versionsFile.eachLine { String line ->
    String[] split = line.split(":")
    String versionValue = split[1]
    List<String> moduleNames = modules[split[0]]
    moduleNames.each { String moduleName ->
      println "Grabbing [org.springframework.cloud:${moduleName}:${versionValue}]"
      if (moduleName.endsWith("dependencies")) {
        
      }
      Grape.grab(group: 'org.springframework.cloud', module: moduleName, version: versionValue)
    }
  }
}

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

if (names.empty) {
  throw new IllegalStateException("Will not update the table, since no configuration properties were found!")
}

new File(outputFile).text = """\
|===
|Name | Default | Description
${names.collect { it -> return descriptions[it] }.join("\n") }



|===
"""

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
