#It isn't here...
#our automated build process doesn't like it.  You see, we are using H2, so our automated build process runs the migrations to generate
#an embedded database and it pushes it into our war.  The build process doesn't like seeing any file under source control touched by the build...
#So you can't just run 'rake db:schema:load'.  You have to run the migrations.  But they are tiny...