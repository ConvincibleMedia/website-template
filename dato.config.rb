require_relative "./helpers"

tester()

content = { hello: "world" }
create_data_file("_data/foobar.yml", :yaml, content)
