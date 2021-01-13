import nullsafety;
import std.stdio;

void main()
{
  
  Person peter = new Person("Peter", new Person("John", null));

  // peter?.father?.name is "John"
  assert( peter.d!"father".d!"name".get == "John");
  // peter?.father?.name??"Unknown" is "John"
  assert( peter.d!"father".d!"name".get("Unknown") == "John");
  // peter?.father?.father?.name is null
  assert( peter.d!"father".d!"father".d!"name".get is null);
  // peter?.father?.father?.name ?? "Unknown" is "Unknown"
  assert( peter.d!"father".d!"father".d!"name".get("Unknown") == "Unknown" );
  // peter?.father?.father?.name?.length??0 is 0
  assert( peter.d!"father".d!"father".d!"name".d!"length".get(0) == 0 );
  // peter?.name?.length ?? 0 == 5
  assert( peter.d!"father".d!"name".d!"length".get(0) == 4);
  // (null as string)?.length ?? 0 == 0
  assert( dot!string(null).d!"length".get(0) == 0 );
  // 0 ?? 1 == 0
  assert( dot(0).get(1)==0);
  // (null as Person)?.name is null
  assert( Dot!Person(null).d!"name".get is null );
  assert( dot!Person(null).d!"name".get is null );
  assert( (cast(Person)null).d!"name".get is null );
  // (null as Person)?.name?.length ?? 0 == 0
  assert( dot!Person(null).dot(a=>a.name).dot(a=>a.length).get(0) == 0);
  // (null as Person)?.father?.father is null
  assert( dot!Person(null).dot(a=>a.father).get is null);
  // Unwrap nullable type
  assert( dot!Person(peter).get == peter);	
  // Unwrap not nullable type
  assert( dot!int(55).get(0) == 55);
  // Unwrap null
  assert( dot!string(null).get is null);
  // Obtain result as Monad instead getting the value... 
  assert( dot!Person(null).d!"father".d!"father".d!"father".d!"name".asNullable.isNull);   
  // Avoid returning typeof(null) when using lambda expression in .dot() method
  assert( dot!Person(null).dot(a=>cast(string) null).asNullable.isNull);
  
  writeln("all done!!!");
}

class Person 
{
	string name;
	Person father;

	this(string name, Person father){	
		this.name=name;
		this.father=father;
	}
}

