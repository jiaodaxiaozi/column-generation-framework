

BEGIN { 
	FS="[ (),]+" 
	nnode = 0
	nedge = 0 
	nreq = 0
	nfail = 0;
	rsum = 0 ;

	srand()
}

/^NODE/ {
	nodeset[ nnode ] = $2;
	nnode ++ ;
}

/^LINK/ {


	edgesrc [ nedge ] = $2 ;
	edgedst [ nedge ] = $3 ;
	edgelen [ nedge ] = 1 ;
	
	nedge ++ ;


}

/^REQUEST/ {

	rsrc [ nreq ] = $2
	rdst [ nreq ] = $3
	runit[ nreq ] = $4

	found = 0;

	for ( i = 0 ; i < nreq ; i ++ ) 
		if ( rsrc[ i ] == rdst[ nreq ] && rdst[ i ] == rsrc[ nreq ] ) 
			found = 1 ;
			
	if ( found == 0 ) {	
		rsum += runit[ nreq ];
		nreq ++ ;
	}
	
}

/^FAILURE1/ {

	ftype [ nfail ] = 1;
	f_a [ nfail ] = $2 ;
	nfail ++;

}

/^FAILURE2/ {

	ftype [ nfail ] = 2 ;
	f_a [ nfail ] = $2 ;
	f_b [ nfail ] = $3 ;
	nfail ++;
}

END {

	
	print "// NODE : "  nnode ;
	print "// EDGE : "  nedge ;
	print "// REQUEST : " nreq ;
	print "// AVE CONNECT : " ( rsum / nreq ) ;
	print "// AVE DEGREE : "  ( 2 * nedge ) / nnode ;
	print "// DUAL-FAILURE PERCENT = " percent ;
	print "// NUM DUAL-FAILURE = " int( ( nfail - nedge ) * percent / 100 )


	PRIME = "\""

	print "nodeset = { "	

		for ( i = 0 ; i < nnode ; i ++ ){
			if ( i == (nnode - 1) ) s = "" ; else s =","
			print PRIME nodeset[ i ]  PRIME s
		}

	print "};"

	
	print "edgeset = { "

		for ( i = 0 ; i < nedge ; i ++ ){
	
			if ( i == (nedge - 1) ) s = "" ; else s =","
		
			print "<" PRIME "LINK" (i+1) PRIME ","  PRIME edgesrc[ i ]  PRIME "," PRIME edgedst[ i ] PRIME ","  edgelen[ i ]  ">" s
		}		

	print " }; "

	
	print "requestset={"

	for ( i = 0 ; i  <  nreq ; i++ )
		
		print "< " PRIME rsrc[ i ] PRIME " , " PRIME rdst[ i ] PRIME " , " runit[ i ] " >,"

	print "};"


	nfailure = int ((nfail - nedge) * percent  * 0.01)  + nedge ;

	print "nfailure = " nfailure " ;" ;

	print "failureset = [ "

	for ( i = 0 ; i < nfailure ; i ++ ) {

		if ( ftype[ i ] == 2 )
			print "{ " PRIME f_a[ i ] PRIME "," PRIME f_b[ i ] PRIME " }"
		
		if ( ftype[ i ] == 1 )
			print "{ " PRIME f_a[ i ] PRIME " }"

	}	
	
	print " ]; "


}

