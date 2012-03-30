/*********************************************
 * COLUMN GENERATION - GLOBAL DATA STRUCTURE
 *
 *
 * Author: Hoang Hai Anh
 * Email : hoanghaianh@gmail.com
 *
 * Updated: April 14, 2011
 *********************************************/
include "../../sysmsg.mod" ; // include this line in every global configuration file



int    TEMPVAR[ 0..100 ] = ... ;
int    running[ 0..0   ] = ... ;

/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 *                                           GLOBAL DATA STRUCTURES
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

{ string } nodeset = ... ; 

tuple edge_record {
   string id ; // name of edge
   string src; // source  
   string dst; // destination
   float  distance ; // distance 
 };

{ edge_record } edgeset = ... ;

tuple request_record {
  
  string src ;
  string dst ;
  float  demand ;
  
};   
 
{ request_record } requestset = ... ;

int nfailure = ... ;
{ string } failureset [ 1.. nfailure] = ...;

int  failureset_inside [ f1 in 1..nfailure ][ f2 in 1..nfailure ] = card( failureset[ f1 ] union failureset[ f2 ] ) == card(failureset[f2]) ;

int  acceptfailureset [ 1.. nfailure] = ... ;

float recovery[ 1 .. nfailure ] [ requestset ] = ... ;


tuple failure_request_record {

	int failure ;
	request_record request ;

};

{ failure_request_record }   set_failure_request = { < f , r > | f in 1..nfailure , r in requestset };
range	range_failure_request = 0.. ( card ( set_failure_request ) - 1 ) ;


tuple config_record {
   int    id ;
   float  cost ;
   int    provide    [ range_failure_request ];
   int    used       [ edgeset ];

   
};

{ config_record } poolset = ... ;

int enter_point[ 0..1 ] = ... ; // entry_point[ 0 ] is flag , entry_point[ 1 ] is position

float preobj[ 0..1 ] = ... ;
int   gencon[ 0..1 ] = ... ;

float dual_protect[ 1 .. nfailure ][ requestset ]  = ... ;


tuple cycle_record {

   int  used[ edgeset ] ;

}

int consider_cycle[ 0..0 ] = ... ;
{ cycle_record } poolcycle = ... ;


/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 *                                           GLOBAL FUNCTIONS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/


execute GLOBAL_FUNCTIONS {

	/* compute config's reduced cost */
	function config_reduced_cost( c ) {

		var ret = c.cost ;

		for ( var fr in set_failure_request )
			ret -=  dual_protect[ fr.failure ][ fr.request ] * c.provide[ Opl.ord( set_failure_request, fr ) ];				

		return ret ;
	}


	/* checking input data */
	function checkInput() {

		writeln("CHECKING INPUT DATA ... " );
		writeln("");
		
		// checking repeated requests
		for ( var i = 0 ; i < (requestset.size-1) ; i ++ )
		for ( var j = i+1 ; j < requestset.size ; j ++ ){
			var ri = Opl.item(requestset,i) ;
			var rj = Opl.item(requestset,j) ;

			if ( (( ri.src == rj.src ) && ( ri.dst == rj.dst )) || (( ri.src == rj.dst ) && ( ri.dst == rj.src )) ) {

				writeln("*** error : repeated request :" , ri , " <> " , rj );
				stop();
			}
		}

		for ( var e1 in edgeset )
		for ( var e2 in edgeset )
		if ( e1.id != e2.id ) {
			if ( e1.src == e2.src && e1.dst == e2.dst ) {

				writeln("*** error : repeated edge : " , e1 , " <> ", e2 ) ;
				stop() ;
			}

			if ( e1.src == e2.dst && e1.dst == e2.src ) {

				writeln("*** error : repeated edge : " , e1 , " <> ", e2 ) ;
				stop() ;
			}
		}
		
		for ( var f1 = 1 ; f1 <= nfailure ; f1 ++ )
		for ( var f2 = 1 ; f2 <= nfailure ; f2 ++ )
		if  ( f1 != f2 )
		if  ( failureset_inside[ f1 ][ f2 ]==1 && failureset_inside[ f2 ][ f1 ] ==1 ) {
			writeln("*** error : repeated failure set : " , failureset[ f1 ] , " <> " , failureset[ f2 ] );
			stop();
		} 
	
	} // end check input data

	/* check if two edges adjacent */
	function is_adj( e1 , e2 ) {

		if ( e1.id == e2.id) return false ;

		return  ( e1.src == e2.src || e1.dst == e2.dst || e1.src == e2.dst || e1.dst == e2.src ) ; 

	}

	/* return edge by id */
	function edge_by_id( id ) {

		for ( var e in edgeset )
		if ( e.id == id ) 
			return e ;
	}


	/* print configuration */
	function printConfiguration( c ) {

		var  f , r , e ;

		for ( e in edgeset ) 
		if  ( c.used[ e ] > 0 ) 
			writeln("use " , c.used[ e ] , " units on link " , e );

		writeln();
		for ( var fr in set_failure_request ) {
			if  ( recovery[ fr.failure ][ fr.request ] > 0 && c.provide[ Opl.ord( set_failure_request , fr ) ] > 0 ) {	
				write("...failure set " , failureset[ fr.failure ] , " actived :" );
				writeln(" for request " ,  fr.request , " provide : " , c.provide[ Opl.ord( set_failure_request , fr ) ] );
			}	
		} 
	}





} // end paragraph 
