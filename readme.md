A static website using:

* Jekyll to build pages by running Markdown/YAML through Liquid templates
* DatoCMS to feed Jekyll with source files
* Grunt to process assets
  * Bundle together CSS and JS declaratively
  * Compile SASS to CSS, and run Autoprefixer
  * Minify CSS and JS
* Netlify as CI and CDN for deployment

## FYI

* .ruby-version = 2.4.3 = latest build of Ruby that comes already installed with Netlify (for faster builds)
* helpers.rb provides helper functions to both DatoCMS and Jekyll's plugins
* _redirects is read by Netlify to create alias URLs
