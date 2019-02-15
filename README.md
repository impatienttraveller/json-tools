# json-tools

[![Built with Crystal](https://img.shields.io/badge/built%20with-crystal-000000.svg?style=flat-square)](https://crystal-lang.org/)
[![Build Status](https://travis-ci.org/impatienttraveller/json-tools.svg?branch=master)](https://travis-ci.org/impatienttraveller/json-tools)
[![Releases](https://img.shields.io/github/release/impatienttraveller/json-tools.svg?style=flat-square)](https://github.com/impatienttraveller/json-tools/releases)

An implementation of [RFC-6901](https://tools.ietf.org/html/rfc6901) and [RFC-6902](https://datatracker.ietf.org/doc/rfc6902)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  json-tools:
    github: impatienttraveller/json-tools
```

## Usage

```crystal
require "json-tools"
```

Once you have a `JSON::Any` object in memory you can address any value using the `Pointer` class:

```crystal
json : JSON::Any = ...
val = Json::Tools::Pointer.new("/foo/0/bar").eval(json)
```

JSON object can be patched by using the `Patch` class:

```crystal
patch : JSON::Any = ...
json : JSON::Any = ...
patched_json = Json::Tools::Patch.new(patch).apply(json)
```

This creates a copy of the passed JSON object to work with and the original object is not altered.

## Development

Please raise a GitHub issue and document the commit with the following format:

```
[issue-x] Description
```

## Contributing

1. Fork it (<https://github.com/impatienttraveller/json-tools/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [ddcprg](https://github.com/ddcprg) Daniel del Castillo - creator, maintainer
