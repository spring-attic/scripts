package demo

@EnableDiscoveryClient
@RestController
class Application {
  @Autowired
  Service service
  @RequestMapping("/")
  def home() { service.getMessage() }
}

@Component
@EnableHystrix(proxyTargetClass = true)
class Service { 
  @Autowired
  Fail fail
  @HystrixCommand(fallbackMethod = 'getDefault')
  Map getMessage() {
    if (fail.isFail()) { 
      throw new RuntimeException("Fail!")
    }
    [message: "Hello"]
  }
  Map getDefault() { 
    [message: "Default"]    
  }
}

@Component
@ConfigurationProperties("fail")
class Fail {
  boolean enabled = false
  private Random random = new Random()
  boolean isFail() { 
    return enabled || random.nextDouble()>0.5
  }
}