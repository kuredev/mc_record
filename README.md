# McRecord
McRecord is an ORM for MicroCMS API like ActiveRecord written in Ruby.

https://document.microcms.io/content-api/get-list-contents

# Usage

## Configure MicroCMS API

Configure MicroCMS to use API.
https://document.microcms.io/manual/create-api

## Installation

Create a Gemfile like below, and `bundle install`.

```ruby
gem "mc_record"
```

## Implementation

Create a Ruby source file like below.

```ruby
require "mc_record"

# Credentials
McRecord::Base.config(
  service_domain: "[Domain Name]",
  api_key: "[API Key]",
  end_point: "[End Point]"
)

# Define a class that inherits `McRecord::Base`
class Content < McRecord::Base
end

# Examples
content = Content.find("[ID]") # => Content

# MicroCMS API fields can be read/written as attributes of defined classes.
puts content.name
content.category = ""

# Other Methods.
Content.all # => Array<Content>
Content.where(category: "[Name of Category]") # => Array<Content>
```

# Supported features


The following methods are supported.

- all
- find
- where

# Future Issues.

It looks like Active Record, but doesn't offer the complexities of Active Record::Relation.
For example, it does not support method chaining, lazy loading, etc.
