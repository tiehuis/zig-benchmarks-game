[The Computer Language Benchmarks Game](https://benchmarksgame-team.pages.debian.net/benchmarksgame/) in Zig.

```
zig build
./run
```

## Dependencies

 - zig (master branch)
 - bash
 - pcre
 - gmp

NOTE: Running the full set of tests will use about 1GiB of hard drive space. Run
`zig build clean` to clear all build artifacts.
