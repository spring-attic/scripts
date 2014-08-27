@EnableCloudfoundryResource
@EnableEurekaClient
@RestController
class Demo {
  @RequestMapping("/")
  def home() { [id: UUID.randomUUID().toString(), content: "Hello"] }
}
