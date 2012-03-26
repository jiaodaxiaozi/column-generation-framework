

BEGIN { 
	FS="[ (),]+" 
	nnode = 0
	nedge = 0 
	nreq = 0


	srand()
}

/^NODE/ {

	print $0
}

/^EDGE/ {

	nedge ++ ;

	print "LINK" nedge " " $3 "  " $4 

}

/^REQUEST/ {

	print $0

}

END {



	# create failure set

	nfailure = 0 ;


	for ( i = 1 ; i <= nedge ; i ++ )
	for ( j = (i + 1) ;  j <= nedge ; j ++ )
	{

 			st_a[ nfailure ] =  i ;
                	st_b[ nfailure ] =  j ; 
			
			nfailure ++ ;
	}


	# mixing dual failures 1 million times 

	for ( i = 1 ; i <= 5000000 ; i ++ ) {


		x = int ( rand() * nfailure  );
		y = int ( rand() * nfailure  );

		if ( x < 0 || x >= nfailure ) print "ALERT RANDOM"
		if ( y < 0 || y >= nfailure ) print "ALERT RANDOM"

		tmp = st_a[ x ] ; st_a[ x ] = st_a[ y ] ; st_a[ y ] = tmp ;
		tmp = st_b[ x ] ; st_b[ x ] = st_b[ y ] ; st_b[ y ] = tmp ;

	} 


	for ( i =1 ; i <= nedge ; i ++ )
		print "FAILURE1 LINK" i

	
	for ( i = 0 ; i < nfailure ; i ++ )
		print "FAILURE2 LINK" st_a[ i ] "  LINK" st_b[i] 

}

