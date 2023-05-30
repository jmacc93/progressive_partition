

# Types section
`828d38d5-1906-5bc9-a60d-82d0133982a7`

The types used are proxies for strings, and the `LabeledPartition` and `LabeledPatterns` types

---

`9ef740e7-d827-5f16-8491-af6502242dff`

These are proxies for `string` types:
`PatternFile`
`PatternString`
`SourceFile`
`SourceString`

The main idea here is that you make a new type unique to its base type, despite it being exactly equivalent to its base type. You might also add some data-specific invariants

It allows you the programmer, and the compiler, to distinguish between the same datatypes using types as labels, so you can overload functions with the same type, make it clearer what you're doing, etc

The basic pattern is like:
```D
struct MyStringProxy {
  string baseForm;
  alias baseForm this;
}
```
Then you can use it like this:
```D
MyTypeProxy x = "asdf";
writeln(x); // prints "asdf"
```

---

`4c84de21-e715-5e25-aaf9-9623a85680ee`

`struct LabeledPartition`
Contains:
* A pattern label which is from word to the left of the `:` in a pattern file, see `6e8b0a5a-b43f-5fa6-8afa-8ef311c44cef` labels in `partition_patterns.md`
* A string partition, which is a slice of a source code / input string. This is the first capture in a pattern file regex, or the whole match if there was no capture group in the first matched regex. See `817e8244-4b9d-5d49-9968-356ca34861f1` in `partition_patterns.md`
* Input string index location and line number in the input string

An array of `LabeledPartition`s is what the `partitionString` function outputs. When used as a module, you'll want to work directly with the `LabeledPartition[]` array this function produces

---

`e4877f43-7a59-5510-8e50-5b4bbaa66b9a`

`struct LabeledPatterns`
Contains:
* A regex `systemRegex` of all the patterns collected from a pattern file
* An array of all the labels `nameArray` for each of the patterns from a pattern file

The `ith` regex put into the `systemRegex` corresponds with the `ith` element of `nameArray`. After calling `std.regex.matchFirst` (which returns a `std.regex.Captures captures` object) on a string, the `captures.whichPattern` integer property of this function's return capture result is the corresponding index of the `nameArray` element of the pattern that matched. eg: If you have a line like `whitespace:\s+` in your pattern file, and that is the 9th pattern in the file, this `whitespace` pattern matched a part of your input string, and your `captures.whichPattern` returns `9` then `nameArray[9] == "whitespace"`. ie: `nameArray[captures.whichPattern]` is the name of the pattern that matched the `sytemRegex`partition_patterns.md

---

`c78dac63-bd0a-58de-a601-1b70a8fb4cb7`

`this(string)`
The constructor for a `LabeledPatterns`. You generally feed a pattern file's contents directly into this function
eg: `auto myPatterns = LabeledPatterns(readText(myPatternFile))`

# The main functionality of the program

Contains: `partitionString`, some helper functions, and the main function

`13d839ef-686a-5793-8d0c-bcc6be0e9eee`

---

`e4f22be3-3c6b-5e09-93a0-38f86bea1865`

`LabeledPartition[] partitionString(P, S)`

Where `P` can be:
* `PatternFile` -- string proxy of a pattern file path
* `PatternString` -- string proxy of an already-loaded pattern file string. ie: What you get *after* you read a `PatternFile`
* `string` -- which acts the same as a `PatternString`

And, `S` can be:
* `SourceFile` -- string proxy of a path to a file you want to partition
* `SourceString` -- string proxy of an already-loaded string that you want to partition
* `string` -- which acts the same as a `SourceString`

This function takes a pattern file or pattern string, along with the path to the file to partition, or a string to partition, and it partitions the string according to the patterns in the pattern file

It does this *progressively*: each time there is a new first match in the string, that matched partition is recorded, then the same process is used on the rest of the string. The first match is the match for the pattern regex from the pattern file that matches first, in line-order

eg: `auto myPartitions = partitionString(PatternFile("path/to/my/pattern_file.txt"), SourceString(readText("some/other/string.txt")))`

---

`ffe1b40e-e096-52d2-94d6-ef37b197f7d4`

`int main(string[] args)`

The command lines options for the program when used as a standalone program and not a module are:
* `--patterns` or `-p` -- The pattern file to load (see `partition_patterns.md` and `partition_patterns.txt` for the format) to use to partition the input string. This __defaults to__ `./patterns.txt`, ie: the file `patterns.txt` in the working directory
* `--input` or `-i` -- This is the file that will be partitioned. If not given, the program uses `stdin` as its input file
* `--output` or `-o` -- This is the `.json` file that is produced by the partitioner. If not given, the program writes to `stdout`
* `--labels` or `-l` -- Whether to include the pattern labels that matched for each partition in the output. Defaults to `true`. Note the pattern for using these switches is like: `--labels=false` and `-l=false`
* `--locations` or `-c` -- Whether to include origin index and line number for each partition in the output. Defaults to `true`. Note: like the line above, use `--locations=false` to turn it off

If `--input` / `-i` isn't given then the program uses `stdin` until `eof`, so you can just pipe your input into the partitioner
If `--output` / `-o` isn't given then the program outputs to `stdout`, so you can just redirect the output to a file

eg: `cat partition_test_string.txt | ./progressive_partition --labels=false -c=false --patterns partition_patterns.txt > partition_test_output.json`
or: `./progressive_partition --input partition_test_string.txt --patterns partition_patterns.txt --output partition_test_output.json`
or: `./progressive_partition -i partition_test_string.txt -p partition_patterns.txt -o partition_test_output.json`

The output `.json` file looks like:
```json
[
  {
    "label": "newlines",
    "location": {"index": 0, "line": 1},
    "partition": "\n"
  },  {
    "label": "symbol",
    "location": {"index": 1, "line": 2},
    "partition": "fn"
  }, ...
]
```
ie:
```json
[
  {
    "label": string,
    "location": {"index": integer, "line": integer},
    "partition": string
  },
  ...
]
```