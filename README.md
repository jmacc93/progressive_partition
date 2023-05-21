# Progressive partitioner

This is a program / module that takes input strings and 'progressively' partitions them using multiple labeled regex patterns. Written in `dlang`

It uses pattern files that look like:
```
lineComment://\s*([^\n]*)\n

newlines:\n+
spaces:[^\n\S]+

statementDelimiter:;
parameterDelimiter:,

leftParenthesis:\(
rightParenthesis:\)

leftCurlyBracket:\{
rightCurlyBracket:\}

leftSquareBracket:\[
rightSquareBracket:\]

string:"[^"]*"

floatNumber:[+-]?(?:\d*\.)?\d+f
integerNumber:[+-]?\d+(?![\.\d])
realNumber:[+-]?(?:\d*\.)?\d+

symbol:[^\s"\.\(\)\{\}\[\]]+
```

To turn strings like:
```
fn main(args in Array(String CmdArg) CmdArgs) {
  print("Hello, world");
}
```

Into json like:
```json
[
  {
    "label": "symbol",
    "location": {"index": 0, "line": 1},
    "partition": "fn"
  },  {
    "label": "spaces",
    "location": {"index": 2, "line": 1},
    "partition": " "
  },  {
    "label": "symbol",
    "location": {"index": 3, "line": 1},
    "partition": "main"
  },  {
    "label": "leftParenthesis",
    "location": {"index": 7, "line": 1},
    "partition": "("
  },  {
    "label": "symbol",
    "location": {"index": 8, "line": 1},
    "partition": "args"
  },
  ...
]
```

See `partition_patterns.md` and `progressive_partition.md` for more details

---

There are no dependencies except the `phobos` dlang runtime library

To build the program with `dmd`, use: `dmd -lowmem -g -debug progressive_partition.d`
Run unit tests with: `dmd -g -debug -unittest progressive_partition.d && ./progressive_partition`