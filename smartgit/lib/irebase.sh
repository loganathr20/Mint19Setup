#!/bin/bash
"${SMARTGIT_JAVA_HOME}/bin/java" -XX:+UseParallelGC -XX:ParallelGCThreads=1 -Xms1m -Xmx64m -cp "${SMARTGIT_CLASSPATH}" -Dsmartgit.logging=false -Djava.net.preferIPv4Stack=true com.syntevo.smartgit.SgRebaseInteractiveMain "$@"
exit $?
