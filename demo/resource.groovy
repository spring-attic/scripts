// Run this app with --spring.application.name=resource
@EnableOAuth2Resource
@EnableDiscoveryClient
@RestController
class Demo {
  @RequestMapping("/")
  def home() { [id: UUID.randomUUID().toString(), content: "Hello Remote"] }
}
