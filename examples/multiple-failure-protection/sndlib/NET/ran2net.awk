

BEGIN { 
	FS="[ (),]+" 
	nnode = 0
	nedge = 0 
	nreq = 0
	nfail = 0;
	rsum = 0 ;

    nf1 = 0 ;
    nf2 = 0 ;
    nf3 = 0 ;
    nf4 = 0 ;

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
    nf1 ++ ;

}

/^FAILURE2/ {

	ftype [ nfail ] = 2 ;
	f_a [ nfail ] = $2 ;
	f_b [ nfail ] = $3 ;
	nfail ++;
    nf2++ ;
}

/^FAILURE3/ {

	ftype [ nfail ] = 3 ;
	f_a [ nfail ] = $2 ;
	f_b [ nfail ] = $3 ;
    f_c [ nfail ] = $4 ;
	nfail ++;
    nf3 ++ ;
}

/^FAILURE4/ {

	ftype [ nfail ] = 4 ;
	f_a [ nfail ] = $2 ;
	f_b [ nfail ] = $3 ;
    f_c [ nfail ] = $4 ;
    f_d [ nfail ] = $5 ;
	nfail ++;
    nf4 ++ ;
}





END {


    take1 = nedge ;
    take2 = int( nf2 * dpercent / 100 ) ;

	
	print "// NODE : "  nnode ;
	print "// EDGE : "  nedge ;
	print "// REQUEST : " nreq ;
	print "// AVE CONNECT : " ( rsum / nreq ) ;
	print "// AVE DEGREE : "  ( 2 * nedge ) / nnode ;

	print "// DUAL-FAILURE PERCENT = " dpercent ;
	print "// NUM DUAL-FAILURE = " take2 ;

    print "// NUM TRIPLE-FAILURE = " take3;
    print "// NUM QUADRUPLE-FAILURE = " take4 ;

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


	nfailure = take1 + take2 + take3 + take4 ;

	print "nfailure = " nfailure " ;" ;

	print "failureset = [ "

	for ( i = 0 ; i < nfail ; i ++ ) {

		if ( ftype[ i ] == 4 && take4 ){

			print "{ " PRIME f_a[ i ] PRIME "," PRIME f_b[ i ] PRIME "," PRIME f_c[i] PRIME "," PRIME f_d[i] PRIME  " }"
            take4 -- ;
		}


		if ( ftype[ i ] == 3 && take3 ){

			print "{ " PRIME f_a[ i ] PRIME "," PRIME f_b[ i ] PRIME "," PRIME f_c[i] PRIME  " }"
            take3 -- ;
		}


		if ( ftype[ i ] == 2 && take2 ){

			print "{ " PRIME f_a[ i ] PRIME "," PRIME f_b[ i ] PRIME " }"
            take2 -- ;
		}

		if ( ftype[ i ] == 1 && take1 ){
		
        	print "{ " PRIME f_a[ i ] PRIME " }"
            take1 --;            

        }
	}	
	
	print " ]; "


}

