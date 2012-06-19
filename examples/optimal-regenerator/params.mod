

include "../../sysmsg.mod" ; // include this line in every global configuration file



float W = ... ; 
int nitem = ... ; // number of items
int item_size[ 1..nitem ] = ... ; // size of each item
int item_demand[ 1..nitem ] = ...; // number of item that need to be satisfied

// column type
tuple pattern_record {

	int  a[ 1 ..nitem ] ; // number of each item in this pattern
};

{ pattern_record }   patternset= ... ; // set of patterns
 
 
float dual_demand[ 1..nitem ] = ... ;

float relaxobj[ 0..1 ] = ... ;

execute  {

	
		
		function printPattern( c ) {
			
			for ( var i = 1 ; i <= nitem ; i ++ )
				if ( c.a[ i ] > 0 )
					writeln("item " , i , " (width=" , item_size[i] , ")" ,  " : " , c.a[i] , " times");
		}

	

} // end paragraph 




