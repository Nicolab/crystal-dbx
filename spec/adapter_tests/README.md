# Adapter-dependent tests

The tests in this folder depend on the definition of an upstream adapter.
This makes it possible to test all adapters generically.

All spec files should end with `_tests.cr` instead of `_spec.cr`.
This allows the tests to be loaded directly into the adapter entry point
and prevents the tests in this folder from being run without defining
the adapter to use and its helpers.
