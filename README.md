(Work in progress!!!)

# D null safety pattern with templates

## What are we talking about

About accessing properties of an object using a reference that can be  `null` in a safe way, that is: to be sure that reference is not null after accessing the property.

i.e.:

```d

Person p;
if(p !is null) 
{
  // It is safe to access [p] reference
}
```

When a member of an object can be null too, accessing its properties require a safe chacke too

```d
class Person { string name; Person father; this(string name, Person father){ this.name = name; this.father = father; } }
auto peter = new Person( "Peter", new Person("Dad", null) );
if( peter !is null && peter.father !is null ) 
{
  // it is safe to acces [perter.father] reference
}
```

This solution takes advantage of the boolean operators "lazy" evaluation:   operators terms are evaluated left to right and, in the case of ``&&`` , if left terms evaluates to `false` it is not necessary evaluate the right side term (because ``false && true == false``)

We can use the *ternary condiciontal ``?:`` operator* to write null safe assignments:

```d
auto age = (peter !is null && peter.father !is null) ? peter.father.age : 0;

```

or, if you prefer to use ``Nullable!T`` to avoid dealing with "default" values:

```d
auto age = (peter !is null && peter.father !is null) ? nullable(peter.father.age) : nullable!int();

```

Writting guard expressions for each "dot" of the chain is tedious (a repetitive) task that modern languages tries to solve

## The ?. (null conditional) and  ?? (null coalesce) operators

Mothern languages incorporates 2 new operators: `?.` (null conditional) and `??` (null coalesce)

* `a?.b`:  if `a` has not value then complete expresion evaluates to a "not value" acording to ``b`` returning type.  This can be applied "recursively" to large references chains like `a?.b?.c?.d`  that can be read as  ``((a?.b)?.c)?.d``
* ``a ?? c``:  being `a` and `b`  of the same type, this expresion returns this type.  The returned value is ``a`` if it has a value or ``c`` if  ``a`` has not a value

What "has value" and "has not a value" means depends on each programming language:

**C#** has **reference types** (object, string, ...) and **value types** (int, bool, char, ...).

* Reference types accept the ``null`` value.
* Value types don't accept ``null`` value, but can be wrapped wit the ``Nullable<T>`` struct allowing to represent the "not value" state. When wrapped, they are called **nullable value types**

null-conditional and null-coalesce operators accept for the "left side" expresion both **reference types** and **nullable value types**

```c#
// C#
// Right side evaluates to a reference type (and value can be null)
var dad = peter?.father
// Right side evaluates to a value type (int) because the coalesce operator
int age1 = peter?.father?.age ?? 0;
// Right side has not coalesce operator.  it evaluates to Nullable<int>
int? age2 = peter?.father?.age;
// Although age2 is [Nullable<int>], complete right expression evaluates to [int] because the coalesce operator
int age3 = age2 ?? 0;
```

**Typescript** use unions of types in the form of ``type1 | type2 | ... | typeN``.  A variable can accept the ``null`` value if it is specified in the union types list.

```typescript
// typescript
// age1 doesn't accept the [null] value... the coalesce operator ensures a default value if left side expresion evaluates to null
const age1: int = peter?.father?.age ?? 0;
// age2 is defined to accept [int] or [null]:   we don't need to specified a default value.
const age2: int | null = peter?.father?.age;
```

In typescript there is another possible type:   ```undefined```.  It is applied to unexisting properties (when you access a Map by key that doesn't exist, ``undefined`` is returned).  ```undefined``` is specially useful for JSON serialization, because properties with ```undefined``` values are not serialized  (properties with ```null``` values are serializaed as ``null`` )

**Dart** variables are allways nullable regardless of its type.  It is named **null type safe** because ``null`` value doesn't propatage as an independent type like typescript.

```dart
// dart
// age1 is of type [int] and its value is not [null]
final age1 = p?.father?.father?.age ?? 0; 
// age2 is of type [int] and it's value could be [null]
final age2 = p?.father?.father?.age; 
```

**Swift** takes a different aproach: the functional paradigm one.   It uses the ``Optional`` type that is an enumeration with two cases:  ``Optional.none`` ( equivalent to the ``nil`` literal) and ``Optional.some(value)`` that wraps a value.

* The ?. operator  is named "**optional chaining operator**" because it operates on Optional types (not on value types).
* The ?? operator is named "**nil-coalescing operator**" (a default value that applies when left side evaluates to ``Optional.none``).

```swift
// swift
// age1 is of type Int
var age1 = peter?.father?.age ?? 0;  
// age2 is of type Int?  (Optional integer.  It can be Optional.none or Optional.some(x) ). 
var age2 = peter?.father?.age; 

```

* A third operator is required (because the functional paradigm aproach):  the unwrapping operator  ``!``.  It is required to extract the value contained into the optional (into the Optional.some).

```swift
let optAge = peter?.father?.age;
if(age!=nil){
  let age = optAge!;
  ...
}
```

## What about D

Because **D** has not ``?.`` neither ``??`` operators, we will propose solutions to imitate them mainly based on templates.

**What "nullable" means in ***D***?**

* Like C#, D has types that accept the ```null``` value (i.e.  ``isAssignable(T, type(null))`` is true)  and types that doesn't accept the ```null```  value.
* D incorporates the ``Nullable!T`` struct similar tu ``Nullable<T>`` in C# that __can__ be used to associate a "null state" to types that doesn't accept ```null```

In summary, **D** approach solution must deal with the ``null`` and ``Nullable!T`` in a similar whay as C# does because it's similitudes.

**What about the "optional/some/none" pattern used in swift?**

* D null state is represented with ``null``, (because C compatibility) instead on ``Optional.none``:  This article is about dealing with native D ``null``, not about adding functional paradigms to avoid the use of null when developing in ``D`` (It could be a great new article).

Although, all is said, we will use wrappers (similar to Optional) to implement the proposed solutions one of which will be based on the Wrap/flatMap/Unwrap functional aproach.

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
