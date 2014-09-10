@EnableOAuth2Sso
@RestController
class Demo {
  @RequestMapping("/proxy")
  def home() { [id: UUID.randomUUID().toString(), content: "Hello Local"] }
}
