

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
    tfailure = 0 ;
    qfailure = 0 ;

    # create double links
	for ( i = 1 ; i <= nedge ; i ++ )
	for ( j = (i + 1) ;  j <= nedge ; j ++ )
	{

 			st_a[ nfailure ] =  i ;
            st_b[ nfailure ] =  j ; 
			
			nfailure ++ ;
	}

    # create triple links
	for ( i = 1 ; i <= nedge ; i ++ )
	for ( j = (i + 1) ;  j <= nedge ; j ++ )
    for ( k = (j + 1) ;  k <= nedge ; k ++ )
	{

 			tl_a[ tfailure ] =  i ;
            tl_b[ tfailure ] =  j ; 
			tl_c[ tfailure ] =  k ;
			tfailure ++ ;
	}

    # create quadruple links
	for ( i = 1 ; i <= nedge ; i ++ )
	for ( j = (i + 1) ;  j <= nedge ; j ++ )
    for ( k = (j + 1) ;  k <= nedge ; k ++ )
    for ( l = (k + 1) ;  l <= nedge ; l ++ )
	{
       qd_a[ qfailure ] = i ;
       qd_b[ qfailure ] = j ;
       qd_c[ qfailure ] = k ;
       qd_d[ qfailure ] = l ;

        qfailure ++ ;
 
    }



	# mixing dual failures 10 million times 

	for ( i = 1 ; i <= 10000000 ; i ++ ) {


		x = int ( rand() * nfailure  );
		y = int ( rand() * nfailure  );

		if ( x < 0 || x >= nfailure ) print "ALERT RANDOM"
		if ( y < 0 || y >= nfailure ) print "ALERT RANDOM"

		tmp = st_a[ x ] ; st_a[ x ] = st_a[ y ] ; st_a[ y ] = tmp ;
		tmp = st_b[ x ] ; st_b[ x ] = st_b[ y ] ; st_b[ y ] = tmp ;

	} 

    # mixing triple failures 10 million times
	for ( i = 1 ; i <= 10000000 ; i ++ ) {


		x = int ( rand() * tfailure  );
		y = int ( rand() * tfailure  );

		if ( x < 0 || x >= tfailure ) print "ALERT RANDOM"
		if ( y < 0 || y >= tfailure ) print "ALERT RANDOM"

		tmp = tl_a[ x ] ; tl_a[ x ] = tl_a[ y ] ; tl_a[ y ] = tmp ;
		tmp = tl_b[ x ] ; tl_b[ x ] = tl_b[ y ] ; tl_b[ y ] = tmp ;
		tmp = tl_c[ x ] ; tl_c[ x ] = tl_c[ y ] ; tl_c[ y ] = tmp ;

	} 

     # mixing quadruple failures 10 million times
	for ( i = 1 ; i <= 10000000 ; i ++ ) {


		x = int ( rand() * tfailure  );
		y = int ( rand() * tfailure  );

		if ( x < 0 || x >= tfailure ) print "ALERT RANDOM"
		if ( y < 0 || y >= tfailure ) print "ALERT RANDOM"

		tmp = qd_a[ x ] ; qd_a[ x ] = qd_a[ y ] ; qd_a[ y ] = tmp ;
		tmp = qd_b[ x ] ; qd_b[ x ] = qd_b[ y ] ; qd_b[ y ] = tmp ;
		tmp = qd_c[ x ] ; qd_c[ x ] = qd_c[ y ] ; qd_c[ y ] = tmp ;
		tmp = qd_d[ x ] ; qd_d[ x ] = qd_d[ y ] ; qd_d[ y ] = tmp ;

	} 




	for ( i =1 ; i <= nedge ; i ++ )
		print "FAILURE1 LINK" i

	
	for ( i = 0 ; i < nfailure ; i ++ )
		print "FAILURE2 LINK" st_a[ i ] "  LINK" st_b[i] 
	
	for ( i = 0 ; i < tfailure ; i ++ )
		print "FAILURE3 LINK" tl_a[ i ] "  LINK" tl_b[i] "  LINK" tl_c[i] 

    for ( i = 0 ; i < qfailure ; i ++ )
		print "FAILURE4 LINK" qd_a[ i ] "  LINK" qd_b[i] "  LINK" qd_c[i] " LINK" qd_d[ i ]





}

