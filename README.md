# D null safety pattern with templates

## Disclaimer

I really don't like dealing with nulls.  I consider that normalizing null usage when not mandatory is an "anti pattern".  After dealing with it in dart/flutter and given my experience with scala i really consider this a bad solution.  

That said, I have to recognize that there is "small but substantial" differences between Dart and Typescript/Kotlin/C# that makes the second ones integration better than the Dart one.

As You will see, my D proposals are aligned to Typescript/Kotlin/C# ones.

### The Dart (and Flutter) antipattern

In **Dart**, **null is a must**:  everything is nullable. Dart languaje and it's famous framework **Flutter** are designed under this precept. Dart "tries" to avoid null errors impossing restrictions when calling functions or constructors (not in the data definition itself)

Flutter practically treat all it's constructors arguments optionals (optional == accept null).   In combination with the named parameters it produces a "visual" declarative syntax:  I name this "productivity by visual syntax" nice to see but based on an unsafe code nature.

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

Because functional aproaching for dealing with "null" is not succeeding as inmutability or map/reduce or pattern matching (destructuring in Typescript is a simple but powerful especialization of pattern matching):  a wide range of "modern" languajes incorporate the "Null safety" pattern in the form of **null conditional operator _?._** and **null coalesce operator _??_ / _?:_**

Typescript:
```ts
const a = person?.father?.name?.length ?? 0;
```

Kotlin:
```kotlin
var a = person?.father?.name?.length ?: 0;
```

There is a major difference between typescript (or kotlin or c#) and Dart: **in Dart, _ALL can be null_**, in typescript and kotlin you need to declare something explicitly as nullable and compiler will help you to control situations when dealing with nullable/not nullable combinations.  

* The "coalesce" operator is really need when you assign to a not nullable type:

```typescript
// typescript
const temperature: number = configuration?.referenceTemperature ?? 24;
const length: number = person?.name?.length ?? 0;
```
```c#
// C#
int temperature = configuration?.referenceTemperature ?? 24;
```

* If you really need a null, you must explicitly accept than age can contain a null.

```typescript
// Typescript
const lastThing: Thing|null = context?.things?.last
```
```c#
// C#
int? lastTemperature = context?.temperatures?.last
```

In summary, new developers perceive as a "productive" way of thinking the "null safety" syntax ( ?. and ?? operators) and **D community is not an exception**

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
// Using a  wrapper struct with an explicit property access template (p!"father" is similar to map!"a.father") and an uwrapper method (get)
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

## The  "container/map/unwrap" solution

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
