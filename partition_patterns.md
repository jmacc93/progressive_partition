
Pattern files have the following basic form:
```
label1:regex1
label2:regex2
...
```

But each line can be a little more flexible than that, here are some example line forms in a pattern file: 
* `  ` -- ie: A line with nothing on it. These can be used to space stuff out and group related `label:regex` lines
* `label:regex` -- This is the basic form and probably represents the most common line
* `   label: regex   ` -- Same as above but with more spaces. The starting and ending line spaces are ignored. This form might be used to group relevant patterns
* `// comment text` -- Comments  are lines starting with `//` symbols
* `   //   comment text   ` -- Again, beginning and ending spaces are ignored on comment lines
* etc

When the progressive partitioner is partitioning a string, the first regex match, counting from the top of the pattern file, is what is recorded as the next partition. So, if you have something like:
```
myFirstPattern:asdf
mySecondPattern:asdf
```
The first pattern will always match the substring `asdf` and the second pattern will never match. This is also the case for the following:
```
myFirstPattern:f\(\w
mySecondPattern:f\(\w\)
```
Since the first pattern is a subpattern of the second pattern, and it always matches when the second pattern matches, the second pattern will never match and the first pattern will always be what is used

If only one pattern matches, and it matches with some string before it that wasn't involved in the match, then that unmatched string is recorded with the `unmatchedPartition` label, and then the matched partition is recorded. eg, If the following is an entire pattern file:
```
whitespace:\s+
```
Then only whitespace partitions will be recorded. So if you used this pattern file on the string `xxx yyy zzz`, then you'll get the following output:
```json
[
  {
    "label": "unmatchedPartition",
    "location": {"index": 0, "line": 1},
    "partition": "xxx"
  },  {
    "label": "whitespace",
    "location": {"index": 3, "line": 1},
    "partition": " "
  },  {
    "label": "unmatchedPartition",
    "location": {"index": 4, "line": 1},
    "partition": "yyy"
  },  {
    "label": "whitespace",
    "location": {"index": 7, "line": 1},
    "partition": " "
  },  {
    "label": "unmatchedPartition",
    "location": {"index": 8, "line": 1},
    "partition": "zzz"
  },  {
    "label": "whitespace",
    "location": {"index": 11, "line": 1},
    "partition": "\n"
  }
]
```
Notice that because there isn't a pattern for non-whitespace substrings, the `xxx`, `yyy`, and `zzz` substrings are recorded as `unmatchedPartition`

If there is a capture group in a pattern's regex, then when that pattern matches the capture group will be what is recorded

See `partition_patterns.txt` as an example partition file

