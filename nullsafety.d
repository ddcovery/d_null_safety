module nullsafety;

import std.typecons;
import std.traits;


/**
  Template that wraps a value and allows to access it's properties in a "null safety" way.
  
  It is, basically, a Monad!T (Nullable!T) with a map method named "dot" and an final unwrapper named "get" 

  Example:  peter?.name == "Peter"
  Dot!Person(peter).dot(a=>a.name).get == "Peter";
  
  The "get" unwrapper must include a default value for not nullable types
  
  Example: 
  // peter?.name?.length ?? 0 == 5
  Dot!string(peter).dot(a=>a.name).dot(a=>a.length).get(0) == 5;
  
  Result can be obtained as Nullable!T (Monad) instead unwrapping its value
    
  Example:
  Dot!string(peter).dot(a=>a.parent).dot(a=>a.name).asNullable.isNull;
    
  For a normalized notation, you can substitute the "Dot!T" constructor by the "dot" method
  
  Example:
  // peter?.name?.length ?? 0 == 5
  dot(peter).dot(a=>a.name).dot(a=>a.length).get(0)==5;

  To avoid the "lambda" notation, the struct offers the "d" method as an alternative to "dot":

  Example:
  // peter?.name?.length ?? 0 == 5
  dot(peter).d!"name".d!"length".get(0) == 5;
  
  Finally, you can create the wrapper struct and access one property directly using the "d" method.
  
  Example:
  // peter?.name?.length ?? 0 == 5
  peter.d!"name".d!"length".get(0) == 5
  // peter?.parent?.name == "John"
  peter.d!"parent".d!"name".get == "John"
  
*/
struct Dot(T) 
{
	private	Nullable!T value; // = Nullable!T.init;

	this (T v)
	{
		static if(isAssignable!(T, typeof(null) ))
		{
			if(v !is null)
			{
				value = nullable(v);
			}
		} 
		else 
		{
			value = nullable(v);
		}
	}
	template dot(R) 
	{
		Dot!R dot( R function(T) fun)
		{
			static assert(!isAssignable!(typeof(null), R), "Sorry, fun returning type can't be typeof(null)");
			return value.isNull() ? 
				Dot!R() : 
				Dot!R(fun(value.get()));
		}	
	}
	template d(alias propName) {
		auto d()
		{
			return dot(a => a.unaryProp!propName);
		}
	}
	T get(T defaultValue)
	{
		return this.value.get(defaultValue);
	}
    
	static if(isAssignable!(T, typeof(null) ))
	{
		T get()
		{
			return value.isNull ? null : value.get;
		}
	}

	Nullable!T asNullable()
	{
		return value.isNull ? 
			Nullable!T() : 
			Nullable!T(value.get);
	}
	
}


/**
  Alternative to Dot!T() syntax.  
  It gives a uniform name syntax (constructor and accessor shares the same name)
  * Example: 
    Dot!string("hello").dot(a=>a.length).get 
    // can be written as
    dot("hello").dot(a=>a.length).get
*/
auto dot(T)(T t)
{
	return Dot!T(t);
}


/**
 Alternative to Dot!T() syntax.
 It generates the Dot!() struct and access to a property at the same time .
 Example:
   assert( "hello".d!"length".get(0) == 5 );
   // is equivalent to
   assert( "Dot!string("hello").d!"length".get(0) == 5" );"   
 */
auto d(alias propName, T)(T t)
{
	return Dot!T(t).d!propName;
}

unittest 
{
	class Person 
	{
		string name;
		Person father;
		this(string name, Person father)
		{	
			this.name=name;
			this.father=father;
		}
	}
  
	Person peter = new Person("Peter", new Person("John", null));

	// peter?.father?.name == "John"
	assert( Dot!Person(peter).dot(a=>a.father).dot(a=>a.name).get == "John");
	assert( dot(peter).dot(a=>a.father).dot(a=>a.name).get == "John");
	assert( dot(peter).d!"father".d!"name".get == "John");
	assert( peter.d!"father".d!"name".get == "John");
	// peter?.father?.name??"Unknown" == "John"
	assert( Dot!Person(peter).dot(a=>a.father).dot(a=>a.name).get("Unknown") == "John");
	assert( dot(peter).dot(a=>a.father).dot(a=>a.name).get("Unknown") == "John");
	assert( peter.d!"father".d!"name".get("Unknown") == "John");
	// peter?.father?.father?.name is null
	assert( Dot!Person(peter).dot(a=>a.father).dot(a=>a.father).dot(a=>a.name).get is null);
	assert( dot(peter).dot(a=>a.father).dot(a=>a.father).dot(a=>a.name).get is null);
	assert( peter.d!"father".d!"father".d!"name".get is null);
	// peter?.father?.father?.name ?? "Unknown" == "Unknown"
	assert( dot(peter).dot(a=>a.father).dot(a=>a.father).dot(a=>a.name).get("Unknown") == "Unknown");
	assert( peter.d!"father".d!"father".d!"name".get("Unknown") == "Unknown" );
	// peter?.father?.father?.name?.length??0 == 0
	assert( dot(peter).dot(a=>a.father).dot(a=>a.father).dot(a=>a.name).dot(a=>a.length).get(0) == 0);
	assert( peter.d!"father".d!"father".d!"name".d!"length".get(0) == 0 );  
	// peter?.father?.name?.length ?? 0 == 4
	assert( peter.d!"father".d!"name".d!"length".get(0) == 4);
	// (null as string)?.length ?? 0 == 0
	assert( dot!string(null).d!"length".get(0)==0);
	// 0??1 == 0
	assert( dot(0).get(1)==0);
	// (null as Person)?.name is null
	assert( dot!Person(null).dot(a=>a.name).get is null);
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
	// Avoid returning typeof(null) in .dot() method
	assert( dot!Person(null).dot(a=>cast(string) null).asNullable.isNull);
}


/**
  Access to a property of an element by its name.
  Example:
  "Mataró".unaryProp!"length" == "Mataró".length;
 */
template unaryProp(alias propName)
{
	static assert(is(typeof(propName) : string), "Sorry, propName must be an string");
	static assert(isValidSymbolName(propName), "Sorry, propName must be a valid symbol name");
	
	pure auto unaryProp(ElementType)(auto ref ElementType a)
	{
		return mixin("a." ~ propName);
	} 
}
unittest 
{
	assert( "hello".unaryProp!"length" == 5 );
	assert( "Mataró".unaryProp!"length" == "Mataró".length );
}

/**
  Verifies the pattern [_]*[a-zA-Z][_a-zA-Z0-9]*
*/
pure bool isValidSymbolName(string name)
{
	pure bool isDigit(char a) { return a>='0' && a<='9'; }
	pure bool isAlpha(char a) { return a>='A' && a<='Z' || a>='a' && a<='z'; }

	int i = 0;
	while(i<name.length && name[i]=='_' ) i++;
	if(i<name.length && isAlpha(name[i]) )
	{
		i++;
		while( i<name.length && (name[i]=='_' || isAlpha(name[i]) || isDigit(name[i])) ) i++;
	}
	return i==name.length;
}

unittest {
	assert( isValidSymbolName("_a"));
	assert( isValidSymbolName("a"));
	assert( isValidSymbolName("A"));
	assert( isValidSymbolName("_h1"));
	assert( isValidSymbolName("h1"));
	assert( isValidSymbolName("H1"));
	assert( isValidSymbolName("_hi2"));
	assert( isValidSymbolName("_Hi2"));
	assert( isValidSymbolName("_H_i_2"));
	assert( isValidSymbolName("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"));
	assert( !isValidSymbolName("1"));
	assert( !isValidSymbolName("_1"));
	assert( !isValidSymbolName(" a"));
	assert( !isValidSymbolName("a "));
	assert( !isValidSymbolName(" "));
	assert( !isValidSymbolName("ñ"));  
}
