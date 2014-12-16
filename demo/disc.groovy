package demo

@Grab('httpclient')
@Configuration
@EnableDiscoveryClient
@Log
class App implements CommandLineRunner {
  @Autowired
  DiscoveryClient client
  @Autowired
  EurekaInstanceConfigBean config
  @Autowired
  EurekaClientConfigBean eureka
  @Value('${eureka.instance.hostname:localhost}')
  String hostname
  @Override
  void run(String... args) {
    log.info("Hostname: " + config.hostname + ", " + config.ipAddress + ", " + hostname)
    log.info("Eureka: " + eureka.serviceUrl)
    try {
      def instance = client.getNextServerFromEureka("customersui", false)
      log.info("SERVICE: " + instance.homePageUrl)
    } catch (Exception e) { 
      log.severe("Cannot locate service " + e)
    }
  }
}
