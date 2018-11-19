# CHANGELOG

## Unreleased

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
