== README

You need to first get JRuby, here is the link to the 64 bit msi installer:

https://s3.amazonaws.com/jruby.org/downloads/9.1.8.0/jruby_windows_x64_9_1_8_0.exe

Get JRuby's complete jar file.  You can put it anywhere you want just remember where you put it!
I put it in the directory where JRuby is installed.

https://s3.amazonaws.com/jruby.org/downloads/9.1.8.0/jruby-complete-9.1.8.0.jar

In rails root you will find a file called setup.bat.template.
Move this file to setup.bat, then you will need to modify the following environment variables:

GEM_HOME : (this is in line 2, make sure you create the directory you reference)<br>
JAVA_HOME : (Line 4)<br>
JRUBY_JAR: (This references JRuby's complete jar file.  Line 8)<br>

From a dos shell make sure you are in rails root (you can see the app directory right?), and run:
```
setup.bat
```

Now that your environment is setup you need to install bundler:
```
gem install bundler
```

Install your bundle!
```
bundle install
```

<hr>
<h1>RAILS_COMMON - git submodule</h1>
We have moved the prop loader and logging code into a git repository at https://github.com/VA-CTT/rails_common.git so that the code can be shared with komet_tooling and the PRISME project

To pull the latest code do the following:
1) VCS -> Update Project - from within RubyMine
2) open a terminal and navigate to rails_prisme/lib
3) git submodule add https://vadev.mantech.com:4848/git/r/rails_common.git
4) run 'git reset' so the rails_common directory isn't new source.

You should now see an rails_common directory under the lib directory.

In RubyMine you may see a message concerning rails_common being under source control. If/when you do, click the add root button. This will allow you to make changes within the rails_prisme project to the code in rails_common and commit those changes as well.
<br>

Now you need to run (after installing maven)
```
jars.bat
```
This will set up the ISAAC stuff and downloads all of the necessary jars

run:

```
startup.bat
```

To bring up the server

BTW, on windows you will have to install:<br><br>
**Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files**
<br><br>Google has plenty of help for this install on your jdk/jre.

<br>
<hr>
<h1>Password Recovery</h1>
In every war file there is the following file: WEB-INF/config/prisme_super_user.yml
Copy this file to /app/prismeData, then edit it (self explanatory).  Restart prisme and log in.

<br>
<hr>
<h1>Oracle Setup</h1>

1 - Download Oracle Express Edition for Oracle 12g at:  http://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html 
    Unzip the package and run the SETUP application. This will set up the database as a service and establish your system password for the database.

2 - Download SQL Developer from Oracle at:  http://www.oracle.com/technetwork/developer-tools/sql-developer/downloads/index.html
    This tool will allow you to connect to our Oracle database instances including your local express database. Unzip this file and locate the sqldeveloper application in the root directory to launch the tool.

3 - Launch SQL Developer and connect to your local Express edition as **system** at the default port **1521** with the SID as **xe**.

4 - Run the following commands to create the PRISME users changing the **some_password** to a secure password.
```
-- USER SQL
CREATE USER PRISME_DEV IDENTIFIED BY some_password ;
-- ROLES
GRANT "DBA" TO PRISME_DEV ;
GRANT "CONNECT" TO PRISME_DEV ;

-- USER SQL
CREATE USER PRISME_TEST IDENTIFIED BY some_password ;
-- ROLES
GRANT "DBA" TO PRISME_TEST ;
GRANT "CONNECT" TO PRISME_TEST ;

-- USER SQL
CREATE USER PRISME_PROD IDENTIFIED BY some_password ;
-- ROLES
GRANT "DBA" TO PRISME_PROD ;
GRANT "CONNECT" TO PRISME_PROD ;
```

5 - Create the PRISME_PROFILE for setting up session connections and connection idle_time.

```
--create a profile and assign it to users
CREATE PROFILE PRISME_PROFILE
    LIMIT SESSIONS_PER_USER 500
    IDLE_TIME UNLIMITED;
    
ALTER USER PRISME_DEV PROFILE PRISME_PROFILE;
ALTER USER PRISME_TEST PROFILE PRISME_PROFILE;
ALTER USER PRISME_PROD PROFILE PRISME_PROFILE;

--ALTER PROFILE PRISME_PROFILE 
--  LIMIT IDLE_TIME UNLIMITED;

--select * from user_resource_limits a 
--where a.resource_name in ('IDLE_TIME','CONNECT_TIME');
```

6 - Update the oracle_database.yml file in the PRISME application to reflect the connection to Oracle using the users and passwords established above in the respective environments.

```
default: &default
  adapter: oracle_enhanced
  database: xe
  pool: 1000

development:
  <<: *default
  url: jdbc:oracle:thin:@localhost:1521:xe
  username: PRISME_DEV
  password: some_password

follow the bouncing ball for the rest...

```

7 - Open up a terminal rails console in the rails root directory for PRISME (this step does not apply when setting up AITC boxes)
```
rails console
```

This should run the migrations creating all of the tables in your configured Oracle database based on your Rails environment. If you can open the rails console successfully then you are good to go.

8 - On AITC boxes, move the oracle_database.yml file to /app/prismeData if you are using Oracle. Otherwise the H2 database will be the default.

What if you want to use H2?
The standard database.yml file is configured for the H2 database that was migrated into your war.  If you are deploying to a standard AITC box, just"
```
cd /app/prismeData
mv oracle_database.yml oracle_database.yml.bak
```
the standard database.yml file (h2) will be used.
**Caution** -- if you see in the prismeData directory both a production and test h2 database you have to know which one has your data. You can set which one is used
by looking for the string 'production' and 'test' in the WEB-INF/web.xml file and changing it to whatever is appropriate.

If do not have a prismeData directory on your system, after your deploy stop the app.  Enter into the WEB-INF directory of your deploy. in the config directory you will see
oracle_database.yml.  Move it to a bak and restart.


<br>
<h1>Start up PRISME</h1>
You can now bring up the server:

```
startup.bat
```

Your rails server will come listening on port 3000.  Just hit:<BR>
(Be aware that the server will show a harmless exception when it comes up.)

http://localhost:3000

<h2>Load Service and Service Properties for your environment</h2>
There is seed data for the following environments:
<ol>
    <li>LOCALHOST - http://localhost:port/rails_prisme/utilities/seed_services?db=localhost</li>
    <li>VA_DEV_DB - http://path_to_prisme:port/rails_prisme/utilities/seed_services?db=va_dev_db</li>
    <li>AITC_DEV_DB - http://path_to_prisme:port/rails_prisme/utilities/seed_services?db=aitc_dev_db</li>
    <li>AITC_SQA_DB - http://path_to_prisme:port/rails_prisme/utilities/seed_services?db=aitc_sqa_db</li>
    <li>AITC_TEST_DB - http://path_to_prisme:port/rails_prisme/utilities/seed_services?db=aitc_test_db</li>
</ol>

<p>If any of the data specifying the locations or credentials for any of these environments change then we will need to update the seed files accordingly. If, after running for your environment, you are not connecting to a given service then go into services and update the url(s) and user credentials and re-test.</p> 


<hr>
<a href="#roles">Roles</a>
<h1>Fetching roles from PRISME</h1>

Prisme can easily display the roles for all users registered with the system.

For example,  hitting the following url:
```
http://localhost:3000/roles/get_roles?id=cshupp@gmail.com&password=cshupp@gmail.com
```

Will show the roles in html format.  We note that only two cgi parameters are required (id, and password).

To get them in JSON format we can do the following (note the .json):
```
http://localhost:3000/roles/get_roles.json?id=cshupp@gmail.com&password=cshupp@gmail.com
```

Or (note the additional 'format' cgi parameter):
```
http://localhost:3000/roles/get_roles?format=json&id=cshupp@gmail.com&password=cshupp@gmail.com
```

Modifying the request header to 'application/json' will also work.

Below is a sample java application which shows how to parse the json.  The results might look like:

http://localhost:3000/roles/get_roles.json?id=cshupp%40gmail.com&password=cshupp%40gmail.com<br>
Role 0 is super_user<br>
Role 1 is read_only<br>
Role 2 is editor<br>
Role 3 is reviewer<br>

```
package examples.prisme.roles.json;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class RoleFetchSample {
	
	private static final String JSON_ROLES = "http://localhost:3000/roles/get_roles.json";
	
	public String fetchJSON(String user, String password) throws Exception {
		String userEncoded = URLEncoder.encode(user, "UTF-8");
		String passwordEncoded = URLEncoder.encode(password, "UTF-8");
		String urlString = JSON_ROLES + "?id=" + userEncoded + "&password=" + passwordEncoded;
		System.out.println(urlString);
		URL prismeRolesUrl = new URL(urlString);
		HttpURLConnection urlConnection = null;
		StringBuilder result = new StringBuilder();
		try {
			urlConnection = (HttpURLConnection) prismeRolesUrl.openConnection();
			BufferedReader r = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()));
			String line = null;
			while ((line = r.readLine()) != null) {
				result.append(line);
			}
		} finally {
			urlConnection.disconnect();
		}
		return result.toString();
	}
	
	public void parseRoleJSON(String jsonString) throws JSONException {
        JSONArray rolesArray = new JSONArray(jsonString);
        int length = rolesArray.length();
        for (int i = 0; i < length; i++) {
        	JSONObject obj = rolesArray.getJSONObject(i);
        	String role = obj.getString("name");
        	System.out.println("Role " + i + " is " + role);
        }
	}
	
	public static void main(String[] args) throws Exception{
		RoleFetchSample r = new RoleFetchSample();
		r.parseRoleJSON(r.fetchJSON("cshupp@gmail.com", "cshupp@gmail.com"));
	}

}

```

<hr>
<h1>Special routes</h1>
If you are on the homepage, appending the following to your url:<br>

**/utilities/warmup**

will take you to prisme's warmup page.  You would call this whenever you restart the Apache SSOI server (not Prisme).
This will open a page that will, via ajax, motivate 500 http(s) requests to get Apache's workers warm and toasty. 
Obviously, this will not work if you hit prisme locally.  Prisme must be hit through SSOI.
This page has another nice feature.  The page it reloads 500 times show all the header information
prisme gets from SSOI (including any others).  If you want to snoop on SSOI head here.

Appending:<br>

**/utilities/time_stats**

This page will show you two statistics:<br><br>

<ol>
    <li>Request Time in Apache -- How much time elapsed between apache getting the request from your browser to apache placing the headers on the wire.
    If this time is large, SSOI may be to blame.</li>
    <li>Time from Apache to Rails -- The time Apache received the request to the time rails recieved it.  It does not include the time Rails spent rendering the page. If the other statistic is small suspect network latency.</li>


 


