<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sndlib="http://sndlib.zib.de/network">
<xsl:output method="text" encoding="iso-8859-1"/>

<xsl:strip-space elements="*" />

<xsl:variable name='newline'><xsl:text>
</xsl:text></xsl:variable>

<xsl:template  match="/sndlib:network/sndlib:networkStructure" >  

<xsl:value-of select="$newline" />
<xsl:apply-templates select="sndlib:nodes" /> 
<xsl:value-of select="$newline" />
<xsl:apply-templates select="sndlib:links" /> 
<xsl:value-of select="$newline" />
<xsl:apply-templates select="sndlib:demands" /> 
<xsl:value-of select="$newline" />
</xsl:template> 



<!-- NODES -->

<xsl:template  match="sndlib:nodes" >  
<xsl:for-each select="sndlib:node">
<xsl:value-of select="$newline" />
<xsl:value-of select="concat('NODE ',@id,' ( ', sndlib:coordinates/sndlib:x , ' ' , sndlib:coordinates/sndlib:y , ' )' )"/>
<xsl:text> </xsl:text>
</xsl:for-each>
</xsl:template> 


<!-- LINKS -->

<xsl:template  match="sndlib:links" >  
<xsl:for-each select="sndlib:link">
<xsl:value-of select="$newline" />
<xsl:value-of select="concat('EDGE ',@id,'1 ( ', sndlib:source , ' ' , sndlib:target , ' )' )"/>
</xsl:for-each>
</xsl:template> 

<!-- DEMAND -->
<xsl:template  match="sndlib:demands" >  
<xsl:for-each select="sndlib:demand">
<xsl:value-of select="$newline" />
<xsl:value-of select="concat('REQUEST ', sndlib:source , ' ' , sndlib:target , ' ' , sndlib:demandValue  ) "/>
</xsl:for-each>
</xsl:template> 


</xsl:stylesheet>
