
mvn archetype:generate -DgroupId=com.blue.calc -DartifactId=mycalc -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false

mvn package

mvn clean dependency:copy-dependencies package
mvn site

java -cp target/mycalc-1.0-SNAPSHOT.jar com.blue.calc.App

java -cp target/mycalc-1.0-SNAPSHOT.jar com.blue.calc.App



