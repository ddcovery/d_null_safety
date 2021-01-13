# D null safety pattern with templates

This is an example of how to implement the "null safety" pattern using templates in D.
The final objective is to write thinks like:
```D
  // peter?.name?.length ?? 0 == 5
  assert( peter.d!"name".d!"length".get(0) == 5 )
  // peter?.parent?.name == "John"
  assert( peter.d!"parent".d!"name".get == "John" )
```
  
It is, basically, a monad like struct named **Dot!T** with a map method named **dot** and an final unwrapper named **get**

```D
// peter?.name == "Peter"
assert( Dot!Person(peter).dot(a=>a.name).get == "Peter" );
```

The **get** unwrapper must include a **default value** for not nullable types
  
```D
// peter?.name?.length ?? 0 == 5
Dot!string(peter).dot(a=>a.name).dot(a=>a.length).get(0) == 5;
```

Result can be obtained as Nullable!T monad instead unwrapping its value

```D
Dot!string(peter).dot(a=>a.parent).dot(a=>a.name).asNullable.isNull;
```

For a normalized notation, you can substitute the "Dot!T" constructor by the *dot* method

```D
// peter?.name?.length ?? 0 == 5
dot(peter).dot(a=>a.name).dot(a=>a.length).get(0)==5;
```

To avoid the "lambda" notation, the struct offers a the **d!** method that allows you to write the name of the property directly

```D
// peter?.name?.length ?? 0 == 5
dot(peter).d!"name".d!"length".get(0) == 5;
```

Finally, you can create the wrapper Dot!T struct and access one property directly using the "d" method.

```D
// peter?.name?.length ?? 0 == 5
peter.d!"name".d!"length".get(0) == 5
// peter?.parent?.name == "John"
peter.d!"parent".d!"name".get == "John"
```
