- TerminologyConfig_bad.xsd, obviously, should go away.
- TerminologyConfig_notes.xml - I don't know what this is for, it isn't a valid xml file at the moment.  Should go away.


- TerminologyConfig.xml, ideally, gets removed from this folder, an instead, we depend on the master copy in 
	ISAAC/vhat-constants/src/main/resources/TerminologyConfigDefault.xml
	- I assume this file is overrideable when prisme is deployed?
	
- TerminologyData.xsd, ideally, gets removed from this folder, and instead, we depend on the master copy in 
	ISAAC/vhat-constants/src/main/resources/TerminologyData.xsd.hidden.  But why is this even in prisme???
	
- TerminologyConfig.xsd, ideally, gets removed from this folder, and instead, we depend on the master copy in 
	ISAAC/vhat-constants/src/main/resources/TerminologyConfig.xsd.hidden
	- I assume this file is overrideable when prisme is deployed?