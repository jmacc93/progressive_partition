


`9716cf05-325c-5f2c-9de3-9f784c0966d1`

`bool iff(bool a, bool b)`
Equivalent to the logical expression $a \Leftrightarrow b$, which is equivalent to $\lnot a \vee b$ ie `!a || b`. Only true if both `a` and `b` have the same values, ie: `a == b`

---

`01efa8ec-74ed-5334-933c-c48a49e4bc83`

`T echo(T)(T value)`
Takes `value` which can be anything, prints the value, then returns the value. Can be inserted directly into any expression to print a value
eg: `echo(echo(1) + echo(2))`
Which prints 1, then prints 2, then prints 3

---

`0afc45ec-1e3f-55b0-95c7-9b41cbf15f0b`

`writeStack()`
Prints the current stack to the console
eg: `foo(); writeStack(); assert(0);`
Use when you know the program is going to crash

---

`9fd54247-bbce-5385-955d-4a39d3429a5f`

`string assertString(string msg = "")(string stringToAssert, string variableName1, string variableName2, ...)`
This is to assert an expression while also printing the value of various things to the console, along with a stack trace. Its meant to be used with CTFE and mixin statements. ie: `mixin(str)` where `str` was produced by a function at compile time, and in this case `str` is the result of calling `assertString`
This is essentially just a very verbose assert whose parameters have to be strings
eg: `mixin(assertString!"x is greater than y"("x < y", "x", "y"))`

---

`e1c33342-b5d6-5501-9014-077f6bb433e0`

`void tracedAssert(bool assertionValue, string msg = "")`
An assert + stack trace. Use exactly like a regular assert
ie: `assert(x < 5, "x >= 5")` is equivalent to `tracedAssert(x < 5, "x >= 5")`

---

`0a8baa0e-bb69-577d-938e-6dac82dc91f3`

`void dbgln()`
Prints the current line, module, and function the `dbgln` statement appears in
eg:
```D
f(); // executes
dbgln; // prints the line, module, function
g(); // error here, but you can't see that
dbgln; // this doesn't print, so you know the problem was g
h();
```
Can be quickly thrown down to print which lines are being executed without going into a debugger

---

`b16a1820-bc95-54bf-adda-3c0b3bcaff0c`

`mixin(dbgwritelnFulLMixin("someVar", "someOtherVar", ...))`
This prints the current line, module, and function and prints the name and value of each of the variables given

`mixin(dbgwritelnMixin("someVar", "someOtherVar", ...))`
Same as above but only prints the line. This is useful because you avoid the visual span from the other version

eg:
```D
int x = 5
float y = 7.1
mixin(dbgwritelnMixin("x", "y"))
```
Prints something like:
```
3:
  x == 5
  y == 7.1
```

---

`b167010c-423d-5eeb-b24a-b64cc10b7a4c`

`void dbgwrite(args...)`
Acts just like `std.stdio.writeln` but writes the line its on as well. Use when debugging

---

`687579a2-fb95-5903-af0c-e31735688bec`

Here are some ANSI escape code strings for styling output text
`redFg`, `blueFg`, `greenFg`
`redBg`, `blueBg`, `greenBg`
`boldTxt`

Turn these off using:
`noStyle`

eg:
`writeln(redFg, "Error!", noStyle)`

---

`c54fc86c-1f0f-51ed-b1ef-fb26e533dc4f`

`enum bool isNullable(T)`
This is primarily a helper for `Maybe` to determine if a type can be assigned a value of `null`
eg: `isNullable!(int*)` is `true`, `isNullable!MyStruct` is `false`, and for classes its `true`, for value types its `false`, etc

Theres also `enum bool isNullInit(T)` which is `true` if `T` is initially `null` and `false` if `T` isn't initialized to `null`

---

`dbb7e8b4-dc97-5875-b78a-67c7d6d5e9c8`

`Maybe!T`
Is equivalent to `T` if a `T` variable can be set to `null` (which is canonically the invalid type)
And, is `T` plus a validity indicator if `T` isn't nullable. The validity indicator (which is the `valid` property) is a standing for a `null` value when `T` is something that can't be set to `null`

eg:
```D
Maybe!int maybeFoundValue = searchForAndReturnInvalidIfCouldntFind(list, someValue);
if(maybeFoundValue.valid)
  writeln("Found the value: ", maybeFoundValue.value);
else
  writeln("Didnt find value");
```

---

`107b6052-6d0e-5d72-a977-a2f974e53b34`

`Stack!T`
This is essentially equivalent to `T[]` but adds:
* `Maybe!T popSafe()` -- return the top of the stack or an invalid `Maybe!T`
* `bool isEmpty()`
* `T pop()` -- the unsafe version of `popSafe` always either crashes the program or returns the top of the stack. Use `isEmpty` to determine if you should call this function
* `void push(T value)` -- add a value to the top of the stack

---

`b76550a2-c711-530b-8a4f-fe39f17476d6`

`T[] intersect(T[] list1, T[] list2)`
Returns the elements in common between the two input lists

eg: `intersect([1, 2, 3], [2, 3, 4]) == [2, 3]`

---

`da26d3a3-a730-59c3-8aa9-77cd3c28dc0e`

`T[] swap(T[] array, ulong i, ulong j)`
Makes a copy of `array` with `array[i]` and `array[j]` switched. ie: The output is `array` but the jth location is `array[i]` and the ith location is `array[j]`

eg: `swap([0, 5, 0, 0], 1, 2) == [0, 0, 5, 0]`

---

`17a6edf7-f8a8-55f5-ae03-b8da7620e7a1`

`Maybe!ulong findIndex(T[] array, T valueToFind)`
Finds the index of `valueToFind` in `array` and returns it wrapped in a `Maybe!ulong` (a maybe of an index), OR, if the function doesn't find `valueToFind` it returns a `Maybe!(ulong).invalid` -- ie: a `Maybe!ulong` with a `false` value for its `valid` property

eg: `findIndex([1, 2, 3], 2) == 1`, with `findIndex([1, 2, 3], 2).valid == true` and `findIndex([1, 2, 3], 10).valid == false`

---

`aa009fe4-2327-54ce-a8f8-075f3a45f623`

`ref T[] removeIndex(ref T[] array, ulong indexToRemove)`
Removes `array[indexToRemove]` from `array`. Returns a reference to `array`, so it can be chained. This is *in-place*, so `array` is modified

eg: For `array = [1, 2, 3]`, `removeIndex(array, 1)` makes `array == [1, 3]`

---

`69159255-e312-5d36-8b49-73bd26b827da`

`NonemptyString` this is a proxy for `string` with an invariant that prevents it from being empty
As with all string proxies, its primary effect is to inform the programmer what the string should be like

`89bd62f7-571e-5e64-ab15-587500581c8a`

`enum NonemptyString[] makeNonempty(string[] array)`
Turns a regular string array into a `NonemptyString` array at compile-time. Afaict, this has to be used to turn string array literals to `NonemptyString` array literals
eg: `NonemptyString[] myStrings = makeNonempty!["abc", "xyz", "qwe"]`

The more general version of `makeNonempty` is `literalAs`, which applies to any types

---

`443af432-a1eb-5e49-94cd-942d123fb1c7`

`enum T[] literalAs(T, R[] array)`
Tries to cast each element of `array` into type `T` and returns the equivalent `T[]` at compile-time. Afaict, this has to be used for all proxy types' array literals
eg: `MyCustomInt[] intArray = literalAs!(MyCustomInt, [1, 2, 3])`

---

`e44747b8-5e5d-57b6-a099-4904d0c22d8f`

`DebugEmpty` is nothing, and is intended as a replacement for debug values when not in release builds. Theoretically it takes up no memory and does nothing

`enum auto debugValue(value)`
Returns `value` in debug builds and returns `DebugEmpty` in non-debug builds
eg: `auto varToUseOnlyInDebugBuilds = debugValue!123`

`DebugType(T)`
Acts like `T` in debug builds and `DebugEmpty` in non-debug builds. Behaves just like `debugValue` above but for types

---

`530ab49f-e5cf-5531-96e5-5f440a83a3ed`

`alternates(() {...}, () {...}, ...)`
This function runs each of the function bodies in sequence and stops after one of them succeeds. The idea is that if there is an error in one of the function bodies then it runs the next function body. If there isn't an error in the first function then that is the only one ran, otherwise it goes onto the next, and so on

This absorbs all `Exception`s in its functions' bodies, so keep that in mind

eg:
```D
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
assert(whichSucceeded == 3)
```
