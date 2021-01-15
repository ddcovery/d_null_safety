# D null safety pattern with templates

## Disclaimer

I really don't like dealing with nulls.  I consider that normalizing null usage when not mandatory is an "anti pattern".  After dealing with it in dart/flutter and given my experience with scala i really consider this a bad solution.  

That said, I have to recognize that there is "small but substantial" differences between Dart and Typescript/Kotlin that makes the second ones integration better than the Dart one.

As You will see, my D proposals are aligned to Typescript/Kotlin ones.

### The Dart (and Flutter) antipattern

In **Dart**, **null is a must**:  everything is nullable. Dart languaje and it's famous framework **Flutter** are designed under this precept. 

This is exploited to deal with other languaje weackness (i.e.: no method overloading):  Flutter practically treat all it's constructors arguments optional (nullable).  In combination with the named parameters syntax it produces a "visual" declarative syntax which hides a horrible fact: the compiler is not protecting you against misuse of nulls


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

A more "functional" orientation could be **avoiding null references problem by design** using the **Option** / **Some** / **None** pattern.
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

### Why I talk about Dart when I want to talk about D?... 

Because languajes like Dart explode the "null" anti-pattern to the last consecuences and developers think that this is the correct way of thinking.

This pattern is extending to other "modern" languages like Typescript (javascript evolution) or Kotlin (java evolution)

Typescript:
```ts
const a = person?.father?.name?.length ?? 0;

```
Kotlin:
```kotlin
var a = person?.father?.name?.length ?: 0;
```

There is a major difference between typescript (or kotlin) and dart: **in Dart, _ALL can be null_**, in typescript an kotlin you need to declare something as nullable and compiler will help you to control situations when dealing with nullable/not nullable combilation:

```typescript
const age: number = person?.father?.age ?? 0
const length: number = person?.name?.length ?? '
```
Because "age" or "length" is not nullable, you must specify a default value at the end of the references chain.
If you try to avoid the default value, compiler will emmit an exception.

If you really need a null, you must explicitly accept than age can contain a null.

```typescript
const age: number|null = person?.father?.age
```

Any way, it seems that functional aproaching for dealing with "null" is not succeeding as inmutability or map/reduce or pattern matching (destructuring is a simple especialization of pattern matching)

This causes that new developers perceive as a "productive" way of thinking the "null safety" syntax and **D community is not an exception**

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
if( nullCheck(p).father.father ){
  writeln( format!"%s has a great grand fater"(p.name) );
}
// Or, may be, a mix of them
if(person.ns.father.ns.father.ns.name.get is null){...}
auto age = person.ns.father.ns.father.ns.age.get(0);
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
