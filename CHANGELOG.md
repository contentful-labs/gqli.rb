# CHANGELOG

## Unreleased
### Added
* Client constructor for GitLab. (@lukes) [#17](https://github.com/contentful-labs/gqli.rb/pull/17)

## v1.2.0
* Relax http.rb dependency (support version < 6). [#19](https://github.com/contentful-labs/gqli.rb/pull/19)
* Bump hashie dependency. [#18](https://github.com/contentful-labs/gqli.rb/pull/18)

## v1.1.0
* Added support for timeout management. [#11](https://github.com/contentful-labs/gqli.rb/pull/11)
* Added support for error response handling. [#13](https://github.com/contentful-labs/gqli.rb/pull/13)

## v1.0.0
### Added
* Added support for Mutations.
* Added validations for Mutations and Subscriptions.

## v0.6.1
### Changed
* Changed Introspection query to no longer use `on...` for directive locations and use `locations` instead.

## v0.6.0
* Add Subscription DSL support. (by @hschne) [#5](https://github.com/contentful-labs/gqli.rb/pull/5)
* Add aliases support.
* Add default client constructors for Contentful and Github.

## v0.5.0
### Added
* Add Enum support.

## v0.4.0
### Added
* Add directive support.

## v0.3.0
### Added
* Refactored validations to their own `Validation` class, which now provide better error messages upon validation failure.

## v0.2.0
### Added
* Added `__node` to be able to create nodes in case there's a name collision with a reserved keyword or a built-in method.

## v0.1.0

Initial Release

Included features:
* Create queries and fragments using the `GQLi::DSL`.
* HTTP client with automatic schema introspection and validation.
