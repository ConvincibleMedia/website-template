require "dato"
require "pp"

# create a DatoCMS client
client = Dato::Site::Client.new("YOUR_API_READWRITE_TOKEN")
pp client.item_types.all

=begin
[
  {
    "id"             => "7149",
    "name"           => "Article",
    "singleton"      => false,
    "sortable"       => false,
    "api_key"        => "article",
    "fields"         => ["27669", "27667", "27668"],
    "singleton_item" => nil
  }
]
=end

pp client.fields.all("7149")
#   {
#     "id"          => "27667",
#     "label"       => "Title",
#     "field_type"  => "string",
#     "api_key"     => "title",
#     "hint"        => nil,
#     "localized"   => false,
#     "validators"  => {},
#     "position"    => 2,
#     "appeareance" => {"type"=>"title"},
#     "item_type"   => "7149"
#   },

client.items.create(
  item_type: "7149",
  title: "My first article!",
  content: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed eiusmod.",
  cover_image: client.upload_image("http://i.giphy.com/NXOF5rlaSXdAc.gif")
)
category = client.items.create(
  item_type: "7150"
  name: "My category"
)

article = client.items.create(
  item_type: "7149",
  title: "My first article!",
  content: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed eiusmod.",
  categories: [ category.id ]
)
client.items.create(
  item_type: "7149",
  title: {
    en: "My first article!",
    it: "Il mio primo articolo!"
  },
  content: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed eiusmod.",
  cover_image: client.upload_image("http://i.giphy.com/NXOF5rlaSXdAc.gif")
)


records = client.items.all("filter[type]" => "article")
