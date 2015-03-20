require 'asciidoctor'
require 'erb'

options = {:mkdirs => true, :safe => :unsafe, :attributes => ['linkcss', 'allow-uri-read'], :type => 'book'}

guard 'shell' do
  watch(/^[A-Za-z][^#]*\.adoc$/) {|m|
    print "*********** " + m.inspect
    Asciidoctor.render_file('src/main/asciidoc/spring-cloud.adoc', options.merge(:to_dir => 'target/generated-docs'))
  }
end