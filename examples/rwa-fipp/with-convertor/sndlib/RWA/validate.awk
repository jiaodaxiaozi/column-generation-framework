


BEGIN { FS="[ (),]+" 
 nnode = 0 ;
 nreq  = 0 ;	
 request_repeated = 0 ;
 edge_repeated = 0 ;
 nedge = 0 ;
}

/^NODE/ {
 nnode = nnode + 1
}

/^EDGE/ {

  for ( i = 1 ; i <= nedge ; i ++ )
  if (( efrom[ i ] == $3 ) && ( eto[ i ] == $4 )) {
		edge_repeated = i;
  } 

  nedge ++ ;
  efrom[ nedge ] = $3 ;
  eto  [ nedge ] = $4 ;
  
}

/^REQUEST/ {

	for ( i = 1 ; i <= nreq ; i ++ )
	if (( rfrom[ i ] == $2 ) && ( rto[ i ] == $3 )) {
			request_repeated = i;
	} 

	rfrom[ nreq + 1 ] = $2 ;
	rto[ nreq + 1 ]   = $3 ;
	nreq ++ ;


}

END {
 
	if ( request_repeated > 0 )
		print "alert : ** request is repeated **" 

	if ( edge_repeated > 0 )	
		print "alert : ** edge is repeated **" 
}
