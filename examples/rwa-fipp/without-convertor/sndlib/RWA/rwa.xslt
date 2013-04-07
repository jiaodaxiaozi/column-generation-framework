<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sndlib="http://sndlib.zib.de/network">
<xsl:output method="text" encoding="iso-8859-1"/>

<xsl:strip-space elements="*" />

<xsl:variable name='newline'><xsl:text>
</xsl:text></xsl:variable>
<xsl:variable name='tc'><xsl:text>"</xsl:text></xsl:variable>


<xsl:variable name='divisor' select="/sndlib:network/sndlib:networkStructure/@divisor" /> 

<xsl:template  match="/sndlib:network/sndlib:networkStructure" >  
NWAVELENGTH =  <xsl:value-of select="@nwavelength" /> ;

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
<xsl:text>NODESET = { </xsl:text>
<xsl:for-each select="sndlib:node">
<xsl:value-of select="$newline" />
<xsl:value-of select="$tc"/><xsl:value-of select="@id"/><xsl:value-of select="$tc"/>
</xsl:for-each>
<xsl:value-of select="$newline" />
<xsl:text> };  </xsl:text>
</xsl:template> 
<!-- LINKS -->

<xsl:template  match="sndlib:links" >  
<xsl:text>EDGESET = { </xsl:text>
<xsl:for-each select="sndlib:link">
<xsl:value-of select="$newline" />
<xsl:text>&lt; </xsl:text> <xsl:value-of select="$tc"/><xsl:value-of select="@id"/>1<xsl:value-of select="$tc"/> , <xsl:value-of select="$tc"/><xsl:value-of select="sndlib:source"/><xsl:value-of select="$tc"/> , <xsl:value-of select="$tc"/><xsl:value-of select="sndlib:target"/><xsl:value-of select="$tc"/> <xsl:text> &gt;</xsl:text> 
<xsl:value-of select="$newline" />
<xsl:text>&lt; </xsl:text> <xsl:value-of select="$tc"/><xsl:value-of select="@id"/>2<xsl:value-of select="$tc"/> , <xsl:value-of select="$tc"/><xsl:value-of select="sndlib:target"/><xsl:value-of select="$tc"/> , <xsl:value-of select="$tc"/><xsl:value-of select="sndlib:source"/><xsl:value-of select="$tc"/> <xsl:text> &gt;</xsl:text> 
</xsl:for-each>
<xsl:text> };  </xsl:text>
</xsl:template> 

<!-- DEMAND -->
<xsl:template  match="sndlib:demands" >  
<xsl:text>DEMAND = { </xsl:text>
<xsl:for-each select="sndlib:demand">
<xsl:value-of select="$newline" />
<xsl:text>&lt; </xsl:text>
<xsl:value-of select="$tc"/><xsl:value-of select="sndlib:source"/><xsl:value-of select="$tc"/> , <xsl:value-of select="$tc"/><xsl:value-of select="sndlib:target"/><xsl:value-of select="$tc"/> , <xsl:value-of select="ceiling( sndlib:demandValue div $divisor )"/>
<xsl:text>&gt; </xsl:text>
</xsl:for-each>
<xsl:text> }; </xsl:text>
</xsl:template> 


</xsl:stylesheet>
