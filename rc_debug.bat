java -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=1044 -jar %JRUBY_JAR% -S rails console
