(Work in progress!!!)

# D null safety pattern with templates
## What are we talking about

Mothern languages incorporates 2 new operators: `?.` (null shortcut) and `??` (coalesce)
* `a ?. b`:  if `a` has not value (null, ...) then complete expresion evaluates to a "not value" (null, ...) acording to ``b`` returning type. When expression incorporates a larger chain  When more than one null shortcut is applied, then the 

If `b` returning type doesn' accept "not value" (null, ...) then coalesce operator must be used to dter
* `a ?? b`:  if a evaluates to not value (null, ...) then b is used.

```c#
// c#
int  age1 = peter?.father?.age ?? 0;  
int? age2 = peter?.father?.age;
```
```typescript
// typescript (explicit type)
age1:number      = peter?.father?.age ?? 0;  
age2:number|null = peter?.father?.age;       // age2 can be a number or null
```
```swift
// swift
var age1 = peter?.father?.age ?? 0;  // age1 is of type Int
var age2 = peter?.father?.age;       // age2 is of type Int?  (Optional) . 
```
```dart
// dart
final age1 = p?.father?.father?.age ?? 0; // age1 is of type int and its value is not null
final age2 = p?.father?.father?.age; // age2 is of type int, but it's value could be null
```

All of them incorporates the "null/nil shortcut operator" ``?.`` that stops evaluating the right side of the "." when left side evaluates to a null/nil/...
All of them implements the "coalesce operator" ``??`` that returns a "default" value when left side evaluates to null/nil/...

There is an small (important) differences between languages.

* Dart types are allways nullable
* typescript works with "unions" of types and ``null`` is a type itself:  you declare tat a variable is Type1 | Type2 | Type3 (i.e.:  number | null)
* C# has reference types (object, string, ...) and value types (int, bool, char, ...).  variables using reference types can be null.  variables using value types can't be null, but can use the Nullable<T> container to enable "null like" values.  
* Swift types can be Optional... Optional variables contains a value or are nil.  There is not difference between "value types" and "object types" like c#.
  
Then, the way ``?.`` opperator (and coalesce ?? operator) works is different in each case.

* In Dart, the operator will shortcut when left side evaluates to null
* In Typescript, the operator will shortcut when left side evaluates to null (or undefined)
* In C#, the operator will shortcut when left side is a "null expresion":  evaluates to a null reference, or is a Nullable<T> representing a null value.
* In switch, the operator will shorcut when left side is nil.  This is applicable only for optional values  (optional/nil pattern)

## What about D

D has not a "?.":  we want to generate something that help us to use a syntax to "shortcut" nullable expressions like "?." operator does.

¿What "nullable" is in D?

* Like C#, D has types that accept the ```null``` value and types that doesn't accept the ```null```  value.
* D incorporates the Nullable!T struct similar tu Nullable<T> in C# that can be used to associate a "null state" to types that doesn't accept ```null```

¿What about the "optional/some/none" pattern that we can find in functional programming languages?

Well, D has not "monads" in it's base library: The Optional/Some/None pattern is not implemented and Nullable!T is an allien that doesn't acept the map/flat/reduce/... operations implemented for Ranges (The abstraction used by D for iterating) in the std.algorithms module.  

We could implement our own Optional struct (that implements the Range "interface"), with an special method to "shortcut" the None value (and it will be a good new investigation project), but now I pretend to solve the actual null/Nullable! shortcut problem.


  
  
or the second kind of   (Dynamic objects, pointers...) and variables that doens't accept '''null''  that  are references that accepts the null value (objects created with new, or a pointer to (accetps the value null) or values (doesn't accept value null).  I'm not sure
D incorporates the Nullable!T similar to C# Nullable<T> 
  
  




## Disclaimer

I really don't like dealing with nulls.  I consider that normalizing null usage when not mandatory is an "anti pattern".  After dealing with it in dart/flutter and given my experience with scala i really consider this a bad solution.  

That said, I have to recognize that there is "small but substantial" differences between Dart and Typescript/Kotlin/C# that makes the second ones integration better than the Dart one.

As You will see, my D proposals must decide if they are aligned with Dart (not really), with Typescript (returning a null for nullable or default for not nullable), with C#/Swift (returning Nullable!T or a Range for std.algorithm compatibility) or, may be, a mix of them.

### The Dart (and Flutter) antipattern

In **Dart**, **null is a must**:  everything is nullable. Dart languaje and it's famous framework **Flutter** are designed under this precept. Dart "tries" to avoid null errors impossing restrictions when calling functions or constructors (not in the data definition itself)

Flutter practically treat all it's constructors arguments optionals (optional == accept null).   In combination with the named parameters and calling constructors without "new" keyword, it produces a "visual" declarative syntax:  I call this "productivity by visual syntax" nice to see but based on an unsafe code nature.

```Dart
class Person {
  final String name;
  final String surname;
  final DateTime birthdate;
  final Person father;
  Person({@required this.name, this.surname, this.birthdate, this.father});
}

Person p = Person(
  name:"Petter", 
  father: Person(
    name:"John"
  ),
);
if(p?.father?.father != null) {
  print("${p.name} has a great grand father";
}
```

A more "functional" orientation could **avoid null references problem by design** using the **Option** / **Some** / **None** pattern.
This solution forces you (because the Compiler static type checking) to work in a secure (null free) way and there is no possibility of null references exceptions.  

```Dart
class Person {
  final String name;
  final Optional<String> surname;
  final Optional<DateTime> birthdate;
  final Optional<Person> father;
  Person({@required this.name, this.surname = None(), this.birthdate = None(), this.father = None()});
}

final p = Some(Person(name:"Petter"));
if(p.flatMap( a=>a.father).flatMap(a=>a.father) is! None) {
  print("${p.name} has a great grand father";
});

// My favourite one: a pesudo pattern matching implementation :-)
p.flatMap( a=>a.father).flatMap(a=>a.father).match( 
  some:(v){  
    print("${p.name} has a great grand father named ${v.name}"; 
  }, 
  none: (){ 
    print("${p.name} has not grand father";
  }
);
```

The problem with this custom solution is that all dart/flutter libraries are "null" dependent and your effort to avoid nulls is useless.

All your code will be full of expressions like
```Dart
final text = p.map(a=>a.father).map(a=>a.father).map(a=>a.name).getOrNull();
```
And then... you will begin dealling with nulls newly.

### Why I'm talking about other languajes when I want to talk about D?... 

Because a wide range of "modern" typed languajes incorporate the "Null safety" pattern in the form of **null conditional operator _?._** and **null coalesce operator _??_ / _?:_**.  But not all of them are really dealing with **null** as we understand in languajes like D, C o C++.

* swift deals with optional/nil
* c# deals with "evaluates to null" (valid for null references and nullable value types and in modern version with nullable reference types)
```c#
// Not nullable type variable needs a default (coalesce) value
decimal length = person?.father?.name?.length ?? 0;
// Nullable variable doesn't need a default
decimal? lastTemperature = context?.temperatures?.last
// Reference variable
var peter = person?.father
```
* typescript deals with type|null (there is not a "nullable" value types or "option" wrappers), but at least you decide if a varialbe accepts or not null.

```typescript
// Not nullable variable needs a default (coalesce) value
const length:number = person?.father?.name?.length ?? 0;
// Nullable variable accepts null as a result
const lastTemperature: number|null = context?.temperatures?.last
```
* Dart variables allways contains a value or null... but you can use coalesce operator to avoid using null when calling functions with required parameters.

In summary, the new operators "?." and "??" are not, necessarily, a way to deal with ```nulls```, but a friendly way of dealing in each language with its different representations: some of them very close to the functional orientation, others totally based on "null".

Developers perceive as a "productive" way of thinking the "null safety" syntax ( ?. and ?? operators) and **D community is not an exception**.  
The main problem with D is the "heterogeneous" vision of data types:
* there is ```null``` for references.
* there is Nullable!T for value types.
* there is Nullable!T for referenceable types (i.e.: classes)... that allows to wrap a null into Nullable
```D
    Person p = null;
    auto x = Nullable!Person(p);
    assert(!x.isNull);
```
* Nullable!T is not compatible with the std.algorithm library (Nullable!T has apply, but Ranges have map, reduce, chain, join... you can not join a Range of Nullable the same way you do with Range of Ranges)


# Null safety with D

>
> Disclaimer: I'm not a D experienced developer.  This text and the examples are under construction and will change as I acquire more knowledge.
> I really will apreciate if you propose other solutions or you criticize my proposals (in a polite way :-p)
>

If you really need to deal with null references in D, you have 2 options 

* With the *if* statement

```D
if( p !is null && p.father !is null && p.father.father !is null){
  p.name.format!"%s has a great grand father".writeln();
}
```
* With any "fancy" custom template/struct/... for obtaining a "nice" way to check the nullity of a path (or a value of a path) without the need of multiple conditions:  **Exploit the power of D's compile-time templates and introspection**

```D
// Using a  wrapper struct with an explicit property access template (p!"property") and an uwrapper method (get)
if( p.d!"father".d!"father".get is null) ...
// A wrapper with an opDispatch allowing you using the name of the real properties to check it's nullity:
// (Thanks to Steven Schveighoffer)
if( nullCheck(p).father.father ){
  writeln( format!"%s has a great grand fater"(p.name) );
}
// Or, may be, a mix of them
auto age = person.ns.father.ns.father.ns.age.get(0);
auto age = person.ns.father.ns.father.ns.age.asNullable
```

Let's begin

## The  "wrap/map/unwrap" solution

The final objective is to write thinks like:
```D
  // peter?.name?.length ?? 0 == 5
  assert( peter.d!"name".d!"length".get(0) == 5 )
  // peter?.parent?.name == "John"
  assert( peter.d!"parent".d!"name".get == "John" )
```
  
It is, basically, a monad like struct named ``Dot!T`` with a *map* method named ``dot`` and an unwrapper named ``get``

```D
// peter?.name == "Peter"
assert( Dot!Person(peter).dot(a=>a.name).get == "Peter" );
assert( Dot!Person(peter).dot(a=>a.father).dot(a=>a.father).dot(a=>a.name).get is null );
```

The ``get`` unwrapper **must** include a **default value** for non nullable types
  
```D
// peter?.name?.length ?? 0 == 5
Dot!string(peter).dot(a=>a.name).dot(a=>a.length).get(0) == 5;
```

Result can be obtained as ``Nullable!T`` instead unwrapping its value

```D
Dot!string(peter).dot(a=>a.parent).dot(a=>a.name).asNullable.isNull;
```

For a normalized notation, you can use the ``dot`` factory method instead ``Dot!T`` constructor

```D
// peter?.name?.length ?? 0 == 5
dot(peter).dot(a=>a.name).dot(a=>a.length).get(0)==5;
```

To avoid the "lambda" notation, the struct offers the **d!** method member that allows you to write the name of the property directly

```D
// peter?.name?.length ?? 0 == 5
dot(peter).d!"name".d!"length".get(0) == 5;
```

Finally, you can create the ``Dot!T`` struct and access one property directly using the **``d!``** factory method (unifying the syntax withy the ``d!`` struct member).

```D
// peter?.name?.length ?? 0 == 5
peter.d!"name".d!"length".get(0) == 5
// peter?.parent?.name == "John"
peter.d!"parent".d!"name".get == "John"
```

## The "opDistpatch" solution

(This was an example proposed by Steven Schveighoffer in https://forum.dlang.org/post/rtq97c$1k5f$1@digitalmars.com)
