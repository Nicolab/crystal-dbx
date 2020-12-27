# Hook

DBX provides a macro to hook all queries (`exec` or `query`).

This can be done with [around_query_or_exec(&block)](https://nicolab.github.io/crystal-dbx/DBX.html#around_query_or_exec(&block)-macro) macro.

This macro allows injecting code to be run before and after the execution
of the request. It should return the yielded value. It must be called with 1
block argument that will be used to pass the `args : Enumerable`.
This macro should be called at the top level, not from a method.

```crystal
DBX.around_query_or_exec do |args|
  puts "before"
  res = yield
  puts "after"

  puts res.class
  puts "exec" if res.is_a?(DB::ExecResult)
  puts "query" if res.is_a?(DB::ResultSet)

  puts "with args:"
  pp args

  res
end
```

> Be careful of the performance penalty that each hook may cause,
  be aware that your code will be executed at each query and exec.

[around_query_or_exec(&block)](https://nicolab.github.io/crystal-dbx/DBX.html#around_query_or_exec(&block)-macro) is useful for debugging and profiling all queries.

Example to measure query execution time:

```crystal
DBX.around_query_or_exec do |args|
  start = Time.monotonic
  res = yield
  elapsed_time = Time.monotonic - start

  puts "Query execution time: #{elapsed_time}"
  res
end
```
