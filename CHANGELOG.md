# Changelog

## [Unreleased]

### Added

- Add .gitattributes file

## [1.6.3] - 2024-04-13

### Removed

- dependency to gg\_install\_gg, remove ./check script
- dependency to gg\_install\_gg, remove ./check script
- dependency pana

## [1.6.2] - 2024-04-09

### Removed

- 'Pipline: Disable cache'

## [1.6.1] - 2024-04-09

### Changed

- Rework changelog + repository URL in pubspec.yaml
- 'Github Actions Pipeline'
- 'Github Actions Pipeline: Add SDK file containing flutter into .github/workflows to make github installing flutter and not dart SDK'

## 1.6.0 - 2024-01-01

- Update minimum SDK version
- Update check scripts & VSCode settings
- Fix warnings

## 1.5.2 - 2024-01-01

- Fix a bug when moving list items

## 1.5.0 - 2024-01-01

- Add `changeStream` providing detailed information about changes
- Add `GgListValue` incl. `add`, `removeAt`, `remove`, `insertAfter`, `insertBefore`, `move`.
- Add `isOk` callback to prevent assignments in the wrong range.
- Add `syncStream` to get a synchronous stream of events

## 1.3.6 - 2024-01-01

- Add `sync` and `unsync` to sync multiple values with each other.
- Add `forceUpdate` to send the current value to listeners again

## 1.2.0 - 2024-01-01

- `reset` can be called to set value back to seed

## 1.1.0 - 2024-01-01

- `GgValue.stream.map` was added.
- In many cases, consumers of `GgValue` should only read but not write. To
enforce this, `GgReadOnlyValue` is introduced.
- Instead of `Stream<T>`, `GgValue<T>` returns a `GgValueStream<T>`, which offers
direct access to the last set value.
- `GgValue.stream.map` was added.
- Added `set jsonDecodedValue` to assign values decoded from json
- Added `get jsonDecodedValue` to assign values decoded from json
- Renamed `toString` constructor parameter into `stringify`.
- Added `toString()` method.
- Added optional `name` constructor parameter
- String processing is working for dynamic types also
- Fixed: Once `dispose` was called, instances of `GgValue` will not emit any
updates anymore.

## 1.0.2 - 2024-01-01

- When used with custom types, no `parse` and `toString` function needs to be
specified. An exception will by thrown only `stringValue` is used.

## 1.0.1 - 2024-01-01

- Parse an generate bool strings
- Updated documentation
- Provided example

## 1.0.0 - 2024-01-01

- Parse strings into GgValue
- Turn GgValue into strings

## 0.0.9+4 - 2024-01-01

- Moved source code to [https://github.com/inlavigo/gg\_value](https://github.com/inlavigo/gg_value)

## 0.0.9+2 - 2024-01-01

- Fixed dart package conventions.

## 0.0.9+1 - 2024-01-01

- Initial version.

[Unreleased]: https://github.com/inlavigo/gg_value/compare/1.6.3...HEAD
[1.6.3]: https://github.com/inlavigo/gg_value/compare/1.6.2...1.6.3
[1.6.2]: https://github.com/inlavigo/gg_value/compare/1.6.1...1.6.2
[1.6.1]: https://github.com/inlavigo/gg_value/compare/1.6.0...1.6.1
