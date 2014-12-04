@EnableZuulProxy
@RestController
class Demo {
    @RequestMapping("/")
    def home() { [message: "Hello"] }
}
