import os
import ConfigParser


if __name__ == "__main__" :


	print "REPORT"

	for inifile in os.listdir("ini") :

		print "analyzing " , inifile 	


		config = ConfigParser.ConfigParser()
		config.read( "ini/" + inifile )

		nconnect = config.get("RESULT","NCONNECT" )

		print nconnect	
