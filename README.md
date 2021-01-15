# D null safety pattern with templates

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
* Dart variables allways contains a value or null... but you can use coalesce operator to avoid using null when calling with a required parameter.

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
