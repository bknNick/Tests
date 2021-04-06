#!/bin/bash
########################################################################CONFIGURATION HERE###############################################################
DIYmon.lib="Input the path to the .lib file here"
. $DIYmon.lib

##THRESHOLDS IN PERCENTAGES
DiscUsageThreshold=70
InodeUsageThreshold=70
FreeMemThreshold=15
FreeSwapThreshold=50

##ENABLE/DISABLE MONITORING BY COMMENTING OUT SPECIFIC FUNCTIONS HERE:
FSmonitoring
MEMmonitoring
SvcsMonitoring
#SWAPmonitoring
