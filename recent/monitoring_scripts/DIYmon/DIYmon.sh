#!/bin/bash
########################################################################CONFIGURATION HERE###############################################################
DIYmon_lib="$path_to_the_lib_file"
. $DIYmon_lib

##THRESHOLDS IN PERCENTAGES
DiscUsageThreshold=70
InodeUsageThreshold=70
FreeMemThreshold=15
FreeSwapThreshold=50

##ENABLE/DISABLE MONITORING BY COMMENTING OUT SPECIFIC FUNCTIONS HERE:
FSmonitoring
MEMmonitoring
#SvcsMonitoring
#SWAPmonitoring
