@RibbonClient("foo")
class Client implements CommandLineRunner {
  @Autowired
  RestTemplate restTemplate
  @Override
  void run(String... args) {
    println restTemplate.getForObject("http://foo/", String)
  }
}