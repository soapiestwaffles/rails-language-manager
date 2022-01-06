## !!! ARCHIVED PROJECT !!!

This project was part of some internal tooling that I had built for a project and was in use from 2013-2017. I decided to make it standalone and release it as open-source for posterity in hopes someone else may possibly find value in it.

---
---
---

# Language Manager for Ruby on Rails

A web-based language file editor for Ruby-On-Rails projects circa 2013

## Running

* Make sure rbenv is configured for this version of Ruby. 

* `bundle install`

* Modify line 12 of lanauge_manager.rb if needed to set path to language files: 

    `PATH_TO_LANGUAGE = File.dirname(__FILE__) + "/../some-rails-project/config/locales/"`

* To start: `unicorn`

* Navigate browser to http://localhost:8080

-----

Alternate startup

* `bundle exec rackup config.ru`
