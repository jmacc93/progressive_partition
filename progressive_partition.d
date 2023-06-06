module progressive_partition;

import std.stdio : File;

import lib : escapeQuotes, isVersion;
version(assert) import lib : assertString, writeStack;

alias regextype = char; // Regex!R type R
alias captype   = string; // regex Captures!T type T

// 9e1aba66-1b03-595a-9d3f-0ac90b67d1a8

// 9ef740e7-d827-5f16-8491-af6502242dff
struct PatternFile {
  string stringForm;
  alias stringForm this;
  this(string stringForm_) {
    stringForm = stringForm_;
    if(stringForm.length == 0)
      throw new Exception("PatternFile is empty string");
  }
}
// 9ef740e7-d827-5f16-8491-af6502242dff
struct PatternString {
  string stringForm;
  alias stringForm this;
}

// 9ef740e7-d827-5f16-8491-af6502242dff
struct SourceFile {
  string stringForm;
  alias stringForm this;
  
  this(string stringForm_) {
    stringForm = stringForm_;
    if(stringForm.length == 0)
      throw new Exception("SourceFile is empty string");
  }
}
// 9ef740e7-d827-5f16-8491-af6502242dff
struct SourceString {
  string stringForm;
  alias stringForm this;
}

// 4c84de21-e715-5e25-aaf9-9623a85680ee
struct LabeledPartition {
  string label, partition;
  ulong stringIndex, lineNumber;
  
  alias value = partition; // for compatibility with range_tree_builder
}

// e4877f43-7a59-5510-8e50-5b4bbaa66b9a
struct LabeledPatterns {
  import std.regex : Regex;
  Regex!regextype systemRegex; // regex with multiple patterns suitable for std.regex.Captures.whichPattern
  string[] nameArray; // words for each regex
  
  invariant { mixin(assertString!"Empty LabeledPatterns"("nameArray.length > 0", "nameArray.length")); }
  
  this(string[string] stringRegexMap) {
    import std.regex : regex;
    nameArray = stringRegexMap.keys;
    systemRegex = regex(stringRegexMap.values);
    if(nameArray.length == 0) // release invariant
      throw new Exception("Empty LabeledPatterns");
  }
  
  // Make from string of form: "AAA:BBB\nXXX:YYY\n..."
  // c78dac63-bd0a-58de-a601-1b70a8fb4cb7
  this(string stringForm) {
    import std.string : splitLines;
    import std.regex : ctRegex, Captures, regex, matchFirst;
    static immutable auto commaRegex = ctRegex!(":");
    if(stringForm.length == 0)
      throw new Exception("Empty string used in constructor of LabeledPatterns (input is probably an empty file)");
    
    // split lines like "name:pattern" and collect the results:
    
    string[] lines = splitLines(stringForm);
    if(lines.length == 0)
      throw new Exception("Empty name-pattern string given");
    
    string[] regexPatternArray = [];
    
    foreach(untrimmedLine; lines) { // eg: untrimmedLine == "  AAA:BBB   "
      import std.string : strip;
      string line = strip(untrimmedLine); // eg: line == "AAA:BBB"
      
      if(line.length == 0)
        continue; // skip empty lines
      
      if(line[0] == '/' && line[1] == '/')
        continue; // skip comment lines
      
      // split by first ':'
      Captures!captype splitCaps = matchFirst(line, commaRegex);
      if(splitCaps.empty)
        throw new Exception("Line \"" ~ line ~ "\" has no name (should have form: 'NAME:REGEXPATTERN')");
      
      // before split
      string name = splitCaps.pre; // eg: name == "AAA"
      if(name.length == 0)
        throw new Exception("Line \"" ~ line ~ "\" has empty name (should have form: 'NAME:REGEXPATTERN')");
      
      // after split
      string regexString = splitCaps.post; // eg: regexString == "BBB"
      if(regexString.length == 0)
        throw new Exception("Line \"" ~ line ~ "\" has empty name (should have form: 'NAME:REGEXPATTERN')");
      
      //todo: check regexString has at least one capture group
      
      nameArray ~= name;
      regexPatternArray ~= regexString;
    }
    
    systemRegex = regex(regexPatternArray);
  }
}
unittest {
  auto nps = LabeledPatterns("aaa:bbb\nccc:ddd");
  
  mixin(assertString(q"(nps.nameArray == ["aaa", "ccc"])"));
  
  import std.regex : matchFirst;
  mixin(assertString(q"(matchFirst("bbb", nps.systemRegex).whichPattern == 1)"));
  mixin(assertString(q"(matchFirst("ddd", nps.systemRegex).whichPattern == 2)"));
}

ulong countNewlines(string str) {
  import std.algorithm : count;
  return count(str, '\n');
}

// 13d839ef-686a-5793-8d0c-bcc6be0e9eee

// e4f22be3-3c6b-5e09-93a0-38f86bea1865
// P is PatternFile | PatternString | LabeledPatterns | string (string same as PatternString)
// S is SourceFile | SourceString | string (string same as SourceString)
LabeledPartition[] partitionString(P, S)(P patternsArg, S sourceArg) {
  
  // compiletime switch between pattern argument types
  static if(is(P == PatternFile)) {
    alias patternsFileName = patternsArg;
    
    // load the file
    import std.file : readText; // see https://dlang.org/phobos/std_file.html#readText
    string fileContents = readText(patternsFileName);
    
    LabeledPatterns labeledPatterns = LabeledPatterns(fileContents);
  } else static if(is(P == PatternString)) {
    string patternsSourceString = patternsArg.stringForm;
    
    LabeledPatterns labeledPatterns = LabeledPatterns(patternsSourceString);
  }  else static if(is(P == string)) {
    string patternsSourceString = patternsArg;
    
    LabeledPatterns labeledPatterns = LabeledPatterns(patternsSourceString);
  } else static if(is(P == LabeledPatterns)){
    alias labeledPatterns = patternsArg;
  } else {
    static assert(0, "Bad first argument patternsArg given to partitionString");
  }
  
  // compiletime switch between source argument types
  static if(is(S == SourceFile)) {
    alias sourceFileName = sourceArg;
    
    // load the file
    import std.file : readText; // see https://dlang.org/phobos/std_file.html#readText
    SourceString source = readText(sourceFileName);
  } else static if(is(S == SourceString)) {
    string source = sourceArg.stringForm;
  } else static if(is(S == string)) {
    alias source = sourceArg;
  } else {
    static assert(0, "Bad second argument sourceArg given to partitionString");
  }
  
  string restOfSource = source;
  ulong sourceIndex = 0;
  LabeledPartition[] partitions = [];
  
  ulong currentLine = 1;
  
  import std.regex : Captures, matchFirst;
  ulong dbg_step = 0;
  while(true) {
    dbg_step++;
    Captures!captype searchResult = matchFirst(restOfSource, labeledPatterns.systemRegex);
    if(!searchResult)
      break;
    string wholeMatch = searchResult.hit;
    string firstCapture = "";
    bool didCapture = false;
    if(searchResult.length > 1) {
      firstCapture = searchResult[1];
      didCapture = firstCapture.length > 0;
    }
    
    // add unmatched stuff / stuff skipped over between last match and this one, as a partition
    // unless capture was given
    if(!didCapture && (searchResult.pre.length > 0)) {
      string prePartition = searchResult.pre;
      partitions ~= LabeledPartition("unmatchedPartition", prePartition, sourceIndex, currentLine);
      sourceIndex += prePartition.length;
    }
    
    // add the matched partition
    string partition;
    if(didCapture)
      partition = firstCapture; // first capture is the partition, ignore everything else
    else
      partition = wholeMatch; // no capture group, use everything
    string patternName = labeledPatterns.nameArray[searchResult.whichPattern-1];
    partitions ~= LabeledPartition(patternName, partition, sourceIndex, currentLine);
    
    if(partition.length == 0) {
      import std.conv;
      throw new Exception(
        "The pattern named \"" ~ patternName ~ 
        "\" is matching an empty string (returned \"" ~ partition ~ 
        "\" with length " ~ text(partition.length) ~ ")"
      );
    }
    
    // advance source location
    ulong lineCountInMatch = countNewlines(partition);
    currentLine += lineCountInMatch;
    
    ulong preLength = searchResult.pre.length;
    restOfSource = restOfSource[preLength + partition.length .. $]; // skip the partition in the source
    mixin(assertString!""("wholeMatch.length > 0", "wholeMatch.length", "wholeMatch"));
    sourceIndex += wholeMatch.length;
  }
  
  return partitions;
}
unittest {
  import std.regex;
  string[string] stringRegexMap = [
    "whitespace": "(\\s+)",
    "caps": "([A-Z]+)",
    "lil" : "([a-z]+)",
    "lpar": "\\(",
    "rpar": "\\)",
    "nums": "([0-9]+)"
  ];
  auto partitions = partitionString(LabeledPatterns(stringRegexMap), SourceString("\n\nAAAbbb(123)ccc  "));
  assertString!""(q"[partitions[0].label == \"whitespace"]", "partitions[0].label",         "partitions[0]", "partitions");
  assertString!""(q"[partitions[0].partition == "\n\n"]",    "partitions[0].partition",     "partitions[0]", "partitions");
  assertString!""(q"[partitions[0].stringIndex == 0]",       "partitions[0].stringIndex",   "partitions[0]", "partitions");
  assertString!""(q"[partitions[0].lineNumber == 1]",        "partitions[0].lineNumber",    "partitions[0]", "partitions");
  assertString!""(q"[partitions[1].label == "caps"]",        "partitions[1].label",         "partitions[1]", "partitions");
  assertString!""(q"[partitions[1].partition == "AAA"]",     "partitions[1].partition",     "partitions[1]", "partitions");
  assertString!""(q"[partitions[1].stringIndex == 2]",       "partitions[1].stringIndex",   "partitions[1]", "partitions");
  assertString!""(q"[partitions[1].lineNumber == 3]",        "partitions[1].lineNumber",    "partitions[1]", "partitions");
  assertString!""(q"[partitions[2].label == "lil"]",         "partitions[2].label",         "partitions[2]", "partitions");
  assertString!""(q"[partitions[2].partition == "bbb"]",     "partitions[2].partition",     "partitions[2]", "partitions");
  assertString!""(q"[partitions[2].stringIndex == 5]",       "partitions[2].stringIndex",   "partitions[2]", "partitions");
  assertString!""(q"[partitions[3].label == "lpar"]",        "partitions[3].label",         "partitions[2]", "partitions");
  assertString!""(q"[partitions[3].partition == "("]",       "partitions[3].partition",     "partitions[2]", "partitions");
  assertString!""(q"[partitions[3].stringIndex == 8]",       "partitions[3].stringIndex",   "partitions[2]", "partitions");
  assertString!""(q"[partitions[4].label == "nums"]",        "partitions[4].label",         "partitions[4]", "partitions");
  assertString!""(q"[partitions[4].partition == "123"]",     "partitions[4].partition",     "partitions[4]", "partitions");
  assertString!""(q"[partitions[5].label == "rpar"]",        "partitions[5].label",         "partitions[5]", "partitions");
  assertString!""(q"[partitions[5].partition == ")"]",       "partitions[5].partition",     "partitions[5]", "partitions");
  assertString!""(q"[partitions[6].label == "lil"]",         "partitions[6].label",         "partitions[6]", "partitions");
  assertString!""(q"[partitions[6].partition == "ccc"]",     "partitions[6].partition",     "partitions[6]", "partitions");
  assertString!""(q"[partitions[7].label == "whitespace"]",  "partitions[7].label",         "partitions[7]", "partitions");
  assertString!""(q"[partitions[7].partition == "  "]",      "partitions[7].partition",     "partitions[7]", "partitions");
  assertString!""(q"[partitions.length == 8]",               "partitions.length",                            "partitions");

}
unittest {
  import std.regex;
  string[string] stringRegexMap = [
    "whitespace": "\\s+",
    "string": "\"[^\"]*\""
  ];
  auto partitions = partitionString(LabeledPatterns(stringRegexMap), SourceString(q"[ "asdf"  "" "zxcv"]"));
  
  mixin(assertString!""(q"(partitions[0].label == "whitespace")"     , "partitions[0].label"      , "partitions"));
  mixin(assertString!""(q"(partitions[1].label == "string")"         , "partitions[1].label"      , "partitions"));
  mixin(assertString!""(q"(partitions[2].label == "whitespace")"     , "partitions[2].label"      , "partitions"));
  mixin(assertString!""(q"(partitions[3].label == "string")"         , "partitions[3].label"      , "partitions"));
  mixin(assertString!""(q"(partitions[4].label == "whitespace")"     , "partitions[4].label"      , "partitions"));
  mixin(assertString!""(q"(partitions[5].label == "string")"         , "partitions[5].label"      , "partitions"));
  
  mixin(assertString!""(q"(partitions[0].partition == q"[ ]")"       , "partitions[0].partition"  , "partitions"));
  mixin(assertString!""(q"(partitions[1].partition == q"["asdf"]")"  , "partitions[1].partition"  , "partitions"));
  mixin(assertString!""(q"(partitions[2].partition == q"[  ]")"      , "partitions[2].partition"  , "partitions"));
  mixin(assertString!""(q"(partitions[3].partition == q"[""]")"      , "partitions[3].partition"  , "partitions"));
  mixin(assertString!""(q"(partitions[4].partition == q"[ ]")"       , "partitions[4].partition"  , "partitions"));
  mixin(assertString!""(q"(partitions[5].partition == q"["zxcv"]")"  , "partitions[5].partition"  , "partitions"));
  
  mixin(assertString!""(q"(partitions[0].stringIndex == 0)"          , "partitions[0].stringIndex", "partitions"));
  mixin(assertString!""(q"(partitions[1].stringIndex == 1)"          , "partitions[1].stringIndex", "partitions"));
  mixin(assertString!""(q"(partitions[2].stringIndex == 7)"          , "partitions[2].stringIndex", "partitions"));
  mixin(assertString!""(q"(partitions[3].stringIndex == 9)"          , "partitions[3].stringIndex", "partitions"));
  mixin(assertString!""(q"(partitions[4].stringIndex == 11)"         , "partitions[4].stringIndex", "partitions"));
  mixin(assertString!""(q"(partitions[5].stringIndex == 12)"         , "partitions[5].stringIndex", "partitions")); 
}

static if(isVersion!"progressivePartitionMain") {
  import std.file : readText;
  import std.stdio : writeln, stdin, stdout, File;
  import lib: readEntireFile, escapeJsonHazardousCharacters, appendToExceptions;
  
  // ffe1b40e-e096-52d2-94d6-ef37b197f7d4
  int main(string[] args) { try {
    
    string patternFileName = "./patterns.txt";
    string inputFileName   = "";
    string outputFileName  = "";
    bool outputLabels    = true;
    bool outputLocations = true;
    
    import std.getopt; // https://devdocs.io/d/std_getopt for command line arguments
    auto helpInformation = getopt(
      args,
      "patterns|p",
          "Pattern file (defaults to ./patterns.txt)",
          &patternFileName,
      "input|i",
          "Input file with string to partition (defaults to stdin)",
          &inputFileName,
      "output|o",
          "Output json to file (defaults to stdout)",
          &outputFileName,
      "labels|l",
          "Whether to include the matched pattern label for each partition (defaults to true)",
          &outputLabels,
      "locations|c",
          "Whether to include origin index and line number for each partition (defaults to true)",
          &outputLocations
    ).appendToExceptions("While getting commandline options");
    
    // called with --help or -h
    if(helpInformation.helpWanted) {
      defaultGetoptPrinter("Options:", helpInformation.options);
      return 0;
    }
    
    // read patterns
    string patternSource;
    patternSource = readText(patternFileName).appendToExceptions("While reading pattern file");
    
    // read input file
    File inputFile;
    string inputSource;
    if(inputFileName.length > 0)
      inputFile = File(inputFileName, "r").appendToExceptions("While opening input file");
    else
      inputFile = stdin;
    inputSource = readEntireFile(inputFile).appendToExceptions("While reading input file");
    inputFile.close();
    
    // open output file
    File outputFile;
    if(outputFileName.length > 0)
      outputFile = File(outputFileName, "w").appendToExceptions("While opening output file");
    else
      outputFile = stdout;
    scope(exit) {
      if(outputFile != stdout)
        outputFile.close().appendToExceptions("While closing output file");
    }
    
    // partition
    LabeledPartition[] labeledPartitions = partitionString(patternSource, inputSource).appendToExceptions("While partitioning input");
    
    // write to file
    outputFile.write("[\n").appendToExceptions("While writing to outputFile");
    for(uint i = 0; i < labeledPartitions.length; i++) {
      LabeledPartition labeledPartition = labeledPartitions[i];
      outputFile.write("  {\n");
      if(outputLabels)
        outputFile.write("    \"label\": \"", labeledPartition.label, "\",\n");
      if(outputLocations) {
        outputFile.write("    \"location\": {", 
          "\"index\": ", labeledPartition.stringIndex,
          ", \"line\": ", labeledPartition.lineNumber,
          "},\n"
        );
      }
      outputFile.write("    \"partition\": \"", escapeJsonHazardousCharacters(labeledPartition.partition), "\"");
      outputFile.write("\n  }");
      if(i < labeledPartitions.length - 1)
        outputFile.write(",");
      else
        outputFile.write("\n");
    }
    outputFile.write("]");
    
    return 0;
  } catch(Exception exc) {
    writeln(exc.msg);
    return 1;
  }}
}