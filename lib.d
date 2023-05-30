module lib;

// 364c8f85-49a7-54cb-955b-d8c44091a701 #todo

template from(string mod) {
  mixin("import from = " ~ mod ~ ";");
}
unittest {
  string res = from!"std.array".replace("xyyx", "y", "x");
  mixin(assertString(q"[ res == "xxxx" ]"));
}

// 107b6052-6d0e-5d72-a977-a2f974e53b34
struct Stack(T) {
  T[] arrayForm;
  alias arrayForm this;
  
  Maybe!T popSafe() {
    if(arrayForm.length > 0)
      return Maybe!T(pop());
    else
      return Maybe!T.invalid;
  }
  bool isEmpty() {
    return arrayForm.length == 0;
  }
  T pop() {
    T ret = arrayForm[$-1];
    arrayForm.length--;
    return ret;
  }
  void push(T value) {
    arrayForm ~= value;
  }
}

// dbb7e8b4-dc97-5875-b78a-67c7d6d5e9c8
struct Maybe(T) {
  alias This = typeof(this);
  
  T value;
  alias value this;
  
  static if(isNullable!T) { // a pointer
    // Maybe!T in pointer mode is just its value
    
    bool valid() { return value !is null; }
    
    static This invalid() {
      return This();
    }
    
    
  } else { // not a pointer
    // Maybe!T in not-pointer mode is its value plus a proxy for a null state
    
    this(T value_) {
      value = value_;
      valid = true;
    }
    
    bool valid = false;
    
    static This invalid() {
      return This();
    }
    
    static immutable string maybeTypeStringStart = "Maybe!" ~ T.stringof ~ "(";
    static immutable string maybeTypeStringInvalid = "Maybe!" ~ T.stringof ~ ".invalid";
    string toString() {
      import std.conv : to;
      if(valid)
        return maybeTypeStringStart ~ value.to!string ~ ")";
      else
        return maybeTypeStringInvalid;
    }
  }
}
unittest {
  class Cla { int x; }
  auto cla = new Cla;
  Maybe!Cla maybeCla;
  mixin(assertString("!maybeCla.valid"));
  maybeCla = cla;
  mixin(assertString("maybeCla.valid"));
}

// 69159255-e312-5d36-8b49-73bd26b827da
struct NonemptyString {
  string stringForm;
  alias stringForm this;
  
  invariant {
    mixin(assertString("stringForm.length > 0", "stringForm.length", "stringForm"));
  }
}
// 89bd62f7-571e-5e64-ab15-587500581c8a
enum NonemptyString[] makeNonempty(string[] array) = (){
  NonemptyString[] ret = [];
  foreach(string str; array)
    ret ~= NonemptyString(str);
  return ret;
}();

// 443af432-a1eb-5e49-94cd-942d123fb1c7
enum T[] literalAs(T, alias array) = (){
  T[] ret;
  foreach(elem; array)
    ret ~= cast(T)elem;
  return ret;
}();

// e44747b8-5e5d-57b6-a099-4904d0c22d8f
struct DebugEmpty { }
enum auto debugValue(alias value) = (){
  debug {
    return value;
  } else {
    return DebugEmpty();
  }
}();
template DebugType(T) {
  debug
    alias DebugType = T;
  else
    alias DebugType = DebugEmpty;
}

// 9716cf05-325c-5f2c-9de3-9f784c0966d1
bool iff(bool a, bool b) {
  return (a == b);
}

// 01efa8ec-74ed-5334-933c-c48a49e4bc83
T echo(T)(T value, uint line = __LINE__) {
  import std.stdio;
  writeln(line, " echo: ", value);
  return value;
}

// 0afc45ec-1e3f-55b0-95c7-9b41cbf15f0b
enum bool writeAllStackLines = false;
void writeStack() {
  import core.runtime;
  import core.stdc.stdio;
  
  auto trace = defaultTraceHandler(null);
  foreach(line; trace) {
    if(writeAllStackLines || line.ptr[0] != '?')
      printf("%.*s\n", cast(int)line.length, line.ptr);
  }
  defaultTraceDeallocator(trace);
}

// 9fd54247-bbce-5385-955d-4a39d3429a5f
string assertString(string msg = "", ulong line = __LINE__)(string expr, string[] otherStrings...) {
  import std.conv : to;
  string escapedExpr = norEscapeQuotes(expr);
  string ret = "import std.stdio;
  if(!(" ~ expr ~ ")){ // " ~ (line+2).to!string ~ "
    writeln(\"=== Assertion failure, printing stack ===\"); // " ~ (line + 3).to!string ~ "
    writeStack(); // " ~ (line+4).to!string ~ "
    writeln(\"Assertion failure on line " ~ boldTxt ~ line.to!string ~ noStyle ~ " for " ~ redFg ~ escapedExpr ~ noStyle ~ "\"); // " ~ (line+5).to!string ~ "
    writeln(\"Other values:\"); // " ~ (line+6).to!string ~ "\n";
  int lineOffset = 0;
  foreach(string str; otherStrings) {
    lineOffset++;
    string escapedStr = norEscapeQuotes(str);
    ret ~= "writeln(\"  " ~ greenFg ~ escapedStr ~ noStyle ~ " == \", " ~ str ~ "); // " ~ (line + 6 + lineOffset).to!string ~"\n";
  }
  return ret ~ "assert(false, \"" ~ msg ~ "\"); // " ~ (line + lineOffset + 7).to!string ~"\n}";
}
unittest {
  mixin(assertString("1 == 1"));
  mixin(assertString(q"[ ("a" ~ "b") == "ab" ]"));
}

// e1c33342-b5d6-5501-9014-077f6bb433e0
void tracedAssert(bool res, string msg = "") {
  if(res)
    return;
  writeStack();
  assert(res, msg);
}

// 0a8baa0e-bb69-577d-938e-6dac82dc91f3
void dbgln(int line = __LINE__, string mod = __MODULE__, string fn = __PRETTY_FUNCTION__) {
  import std.stdio : writeln;
  writeln(line, " (", mod, ":  ", fn, ")");
}

// b16a1820-bc95-54bf-adda-3c0b3bcaff0c
string dbgwritelnFullMixin(int line = __LINE__, string mod = __MODULE__, string fn = __PRETTY_FUNCTION__)(string[] args...) {
  import std.conv : to;
  string ret = "import std.stdio : writeln;\n";
  ret ~= "writeln(\"" ~ 
    line.to!string ~ 
    " (" ~ mod ~ 
    "  " ~ fn ~ 
    "):\");\n";
  foreach(string str; args) {
    ret ~= "writeln(\"  " ~ str ~" == \", " ~ str ~");\n";
  }
  return ret;
}
// b16a1820-bc95-54bf-adda-3c0b3bcaff0c
string dbgwritelnMixin(int line = __LINE__)(string[] args...) {
  import std.conv : to;
  string ret = "import std.stdio : writeln;\n";
  ret ~= "writeln(\"" ~ line.to!string ~ ":\");\n";
  foreach(string str; args) {
    ret ~= "writeln(\"  " ~ greenFg ~ str ~ noStyle ~" == \", " ~ str ~");\n";
  }
  return ret;
}

// b167010c-423d-5eeb-b24a-b64cc10b7a4c
void dbgwrite(int line = __LINE__, Args...)(Args args) {
  import std.stdio : writeln;
  writeln(line, ": ", args);
}

// 687579a2-fb95-5903-af0c-e31735688bec
immutable string redFg    = "\033[31m";
immutable string greenFg  = "\033[32m";
immutable string blueFg   = "\033[34m";
immutable string redBg    = "\033[41m";
immutable string greenBg  = "\033[42m";
immutable string blueBg   = "\033[44m";
immutable string boldTxt  = "\033[1m";
immutable string noStyle  = "\033[0m";

// c54fc86c-1f0f-51ed-b1ef-fb26e533dc4f
enum bool isNullable(T) = __traits(compiles, T.init is null);
enum bool isNullInit(T) = () {
  static if(__traits(compiles, T.init is null))
    return (T.init is null);
  else
    return false;
} ();

// b76550a2-c711-530b-8a4f-fe39f17476d6
T[] intersect(T)(const(T[]) list1, const(T[]) list2) {
  T[] ret;
  foreach(T e1; list1) {
    foreach(T e2; list2) {
      if(e1 == e2)
        ret ~= e1;
    }
  }
  return ret;
}
unittest {
  int[] list1 = [1, 2, 3];
  int[] list2 = [3, 4, 5];
  int[] inter = intersect(list1, list2);
  mixin(assertString("inter.length == 1", "inter.length", "inter"));
}
unittest {
  int[] list1 = [1, 2, 3];
  int[] list2 = [4, 5, 6];
  int[] inter = intersect(list1, list2);
  mixin(assertString("inter.length == 0", "inter.length", "inter"));
}

// da26d3a3-a730-59c3-8aa9-77cd3c28dc0e
T[] swap(T)(T[] array, ulong index1, ulong index2) {
  T[] ret = array.dup;
  ret[index2] = array[index1];
  ret[index1] = array[index2];
  return ret;
}
unittest {
  int[] array = [1, 2, 3, 4];
  int[] newArray = array.swap(1, 2);
  mixin(assertString("newArray == [1, 3, 2, 4]", "array"));
}

// 17a6edf7-f8a8-55f5-ae03-b8da7620e7a1
Maybe!ulong findIndex(T)(T[] array, T valueToFind) {
  import std.stdio : writeln;
  for(ulong i = 0; i < array.length; i++) {
    if(array[i] == valueToFind)
      return Maybe!ulong(i);
  }
  return Maybe!ulong.invalid;
}
unittest {
  int[] list = [0, 1, 2, 3, 4, 5];
  Maybe!ulong foundIndex = list.findIndex(2);
  mixin(assertString("foundIndex.valid", "foundIndex"));
  mixin(assertString("foundIndex == 2", "foundIndex"));
  foundIndex = list.findIndex(10);
  mixin(assertString("!foundIndex.valid", "foundIndex"));
}

// aa009fe4-2327-54ce-a8f8-075f3a45f623
ref T[] removeIndex(T)(ref T[] array, ulong indexToRemove) in {
  mixin(assertString!"Index out of bounds"("indexToRemove < array.length", "indexToRemove", "array.length"));
} do {
  for(ulong i = indexToRemove; i < array.length-1; i++)
    array[i] = array[i+1];
  array.length--;
  return array;
}
unittest {
  int[] list = [0, 1, 2, 3, 4, 5];
  list.removeIndex(3);
  mixin(assertString("list.length == 5", "list.length", "list"));
  mixin(assertString("list == [0, 1, 2, 4, 5]", "list.length", "list"));
}
unittest {
  int[] list = [0, 1];
  list.removeIndex(0);
  mixin(assertString("list.length == 1", "list.length", "list"));
  mixin(assertString("list == [1]", "list.length", "list"));
}
unittest {
  int[] list = [0];
  list.removeIndex(0);
  mixin(assertString("list.length == 0", "list.length", "list"));
  mixin(assertString("list == []", "list.length", "list"));
}

// 530ab49f-e5cf-5531-96e5-5f440a83a3ed
alias voidDelegate = void delegate();
void alternates(voidDelegate[] altList...) {
  foreach(voidDelegate alt; altList) {
    try {
      alt();
      return;
    } catch(Exception exc) {
      continue;
    }
  }
}
// 041116ff-ca09-5804-8414-76374782899f
unittest {
  int whichSucceeded = -1;
  alternates(() {
    throw new Exception("Error 1!");
    whichSucceeded = 1;
  }, () {
    throw new Exception("Error 2!");
    whichSucceeded = 2;
  }, () {
    whichSucceeded = 3;
  }, () {
    whichSucceeded = 4;
  });
  mixin(assertString("whichSucceeded == 3", "whichSucceeded"));
}


string readEntireFile(from!"std.stdio".File file) {
  string retString;
  foreach(ubyte[] chunk; file.byChunk(1024))
    retString ~= cast(string)chunk;
  return retString;
}

string norEscapeQuotes(string stringToEscape) { // no-regex version of escapeQuotes
  import std.array : replace;
  return stringToEscape.replace("\"","\\\"");
}
string escapeQuotes(string stringToEscape) {
  import std.regex : ctRegex, replaceAll;
  static auto quoteRegex = ctRegex!"\"";
  return stringToEscape.replaceAll(quoteRegex, "\\$&");
}