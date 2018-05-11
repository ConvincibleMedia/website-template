# Static Website Template

This is the basic template for a #JAMStack-style static website from Convincible, using:

* Jekyll to build pages by running Markdown/YAML through Liquid templates
* DatoCMS to feed Jekyll with source content and settings
* Grunt to process assets
  * Bundle together CSS and JS declaratively
  * Compile SASS to CSS, and run Autoprefixer
  * Minify CSS and JS
* Netlify as the intended CI and CDN for deployment

The aim of this architecture is to create websites that:

* Have highly optimised, valid, pure HTML/CSS/JS code
* Load super fast
* Have high compatibility with most browsers/systems
* Integrate with DatoCMS for a simple editing experience

## FYI

* .ruby-version = 2.4.3 = latest build of Ruby that comes already installed with Netlify (for faster builds)
* helpers.rb provides helper functions to both DatoCMS and Jekyll's plugins
* _redirects is read by Netlify to create alias URLs
* Jekyll's _config.yml contains per-project hard-coded constants that can't change - anything user-changeable is written into _data instead
* Head.JS is used to load all scripts. Non-vendor scripts are written in jQuery.
* As much as possible, JavaScript is not required for the site to work in the browser.
