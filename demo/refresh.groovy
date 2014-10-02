@RestController
@Log
public class Application {

  @Autowired
  Service service

  @RequestMapping('/')
  def home() { 
    [message: 'Hello ' + service.name]
  }

}

class ServiceConfiguration { 

  @Autowired
  private MyProps props

  @RefreshScope
  @Bean
  Service service() {
    log.info("*************** Hello")
    new Service(props.name)
  }

}

class Service { 
  String name = 'UNKNOWN'
  private Service() { }
  Service(String name) { 
    this.name = name
  }
}

@ConfigurationProperties('myprops')
class MyProps {
  String name
}
