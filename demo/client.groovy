@GrabResolver('https://raw.githubusercontent.com/dickerpulli/maven-repo/master')
@Grab('de.codecentric:spring-boot-starter-admin-client:1.0.1.RELEASE')
@RestController
class App { 
  @RequestMapping('/')
  def home() { 
    [message: 'Hello World!']
  }
}