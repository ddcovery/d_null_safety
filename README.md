# D null safety pattern with templates

## Disclaimer

I really don't like dealing with nulls.  I consider this need an "anti pattern".  
Languages like **Dart** (and its framework **Flutter**) **forces you to work with nulls** (i.e.: for managing "optional" funcion parameters).  The adventage is clean: with only one "constructor" or "function" you can use tens of optional parameters:

```Dart
class Person {
  final String name;
  final String surname;
  final DateTime birthdate;
  final Person father;
  Person({@required this.name, this.surname, this.birthdate, this.father});
}

Person p = Person(name:"Petter");
if(p?.father?.father != null) {
  print("${p.name} has a great grand father";
}
```

A more "functional" orientation could be

```Dart
class Person {
  final String name;
  final Optional<String> surname;
  final Optional<DateTime> birthdate;
  final Optional<Person> father;
  Person({@required this.name, this.surname = None(), this.birthdate = None(), this.father = None()});
}

final p = Person(name:"Petter");
if(Some(p).ns.father.ns.father is! None) {
  print("${p.name} has a great grand father";
});
```

Where **Option** is an iterable container (like a List) that allows you to work with it using map/reduce/...

Any way, if you really need to deal with null in D, you have 2 options

* With the *if* statement

```D
if( p !is null && p.father !is null && p.father.father !is null){
  p.name.format!"%s has a great grand father".writeln();
}
```
* With any "fancy" custom template/struct/... for obtaining a "nice" way to check the nullity of a path (or a value of a path) without the need of multiple conditions:  **Take the power of D copmpile time instrocpection**

```D
// Using a  wrapper struct with an explicit property access template (p!"father" is similar to map!"a.father") and an uwrapper method (get)
if( p.d!"father".p!"father".get is null) ...
// A wrapper with an opDispatch allowing you using the name of the real properties to check it's nullity:
if( nullCheck(p).father.father ){
  writeln( format!"%s has a great grand fater"(p.name) );
}
```

Let's begin

# The  "container/map/unwrap" solution

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

Result can be obtained as ``Nullable!T`` monad instead unwrapping its value

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

# The "opDistpatch" solution

(This was an example proposed by Steven Schveighoffer in https://forum.dlang.org/post/rtq97c$1k5f$1@digitalmars.com)
