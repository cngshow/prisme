PRISME Changelog 

This changelog summarizes changes and fixes which are a part of each revision.  For more details on the fixes, refer tracking numbers where provided, and the git 
commit history.

* 2017/06/?? - 4.4 - PENDING
   * Defect 527076 - added custom loading data message overlay when the table is being loaded via the AJAX call
   * fixed a jruby warning in discovery diff loading the mock data (line 116)
   * Fixed IE bug with jquery validation not catching that the reason was not entered. This is being caught on the front end and the form is no longer being submitted 
       without a reason.
   * Making user role tokens, log event tokens, service request as json token all environment specific.
   * 515342 - added version regex validation and suggested description to the GUI for source upload version.

* 2017/05/25 - 4.3
   * Making backend vuid controller reject vuids ranges greater than 1000000.
   * Added VUID_REQUESTOR role and added role navigation for vuid requestor.
   * Added user activity model and migration for admin user edit page.
   * Documenting roles api. Adding my_token path to get my role token.
   * Adding in log event url for the vuid server.
   * Cleaning apipie to use routes outside of a request and added docs for leg events.
   * Adding support for proxifying url in my_token apipie docs.
   * Updating doc to only show SSO link if production.
   * Modified range to use absolute value on VUID server request PRISME GUI

* 2017/05/12 - 4.2
    * Task 512272, 512276 - development support pagination in GUI (backend support for pagination for discovery diff) - test team, your testing strategy will be tied to 
        the demo we provided
    * Defect 515147 - DEV ISSUE : VUID Terminology Dashboard - Request Date format. Anu this is not fixed.  We are only able to replicate this sometimes in test never 
        dev.  We have put some javascript console logs to help debug this.  I am marking this ready for review.  If you can make it happen again please grab me so we 
        can see the output.
    * Defect 514246 - DEV ISSUE : VUID Terminology Dashboard - Reason for request should be mandatory and the validator is not working
    * Story 509029 - Add diff functionality to discovery. Ready for review
    * VUID_REQUESTOR role added
* 2017/05/05 - 4.1
    * VUID feature merged into this release.(501714, 501713, 501657, 501660)

* 2017/05/02 - 4.0
    * Fixing a bug that caused prisme to fail when a komet was in a bad state

* 2017/04/27 - 3.3
    * Refactor and cleanup for checksum and discovery

* 2017/04/20 - 3.2
    *  site_restriction_ignored property added to prisme.properties, so prisme.properties now has:
    #If this key is present, only sites in the csv will be executed. (comment out when done with it.)
    site_restrictor= 950, 951
    #ignore site restriction(above) on environments below
    site_restriction_ignored=PRE_PROD,PROD
    * Refactor of history page for both Checksum and Discovery added.  Now when a checksum (or discovery) is actively running
      leaving the page is not a big deal.  Reselect the sites and Domains/Subsets and return via history button
    * Buttons for viewing HL7, diffs, CSV download changed.  Currently, the diff button only does a CSV download (the diff work is incomplete)
    * Sylvia found a nasty bug (not written up) where the Checksum page on integration completely bombed out (you could not even get to the result page).
      Somehow an old migration that we never expected to be deployed was.  A new migration that will fix the malformed column name if it is present has been added.
      

* 2017/04/11 - 3.1
    * added APACHE time statistics GUI at utilities\time_stats
      Please modify the apache config as follows ( RequestHeader set  apache_time "%D,%t" ):
      -------------------NEW---------------------
      <Location /rails_prisme/>
        RequestHeader set  apache_time "%D,%t"
        ProxyPass https://vaauscttdbs80.aac.va.gov:8080/rails_prisme/
        ProxyPassReverse https://vaauscttdbs80.aac.va.gov:8080/rails_prisme/
        SetEnv proxy-sendchunks 1
      </Location>
      ------------------------------------------
      -------------------OLD---------------------
      <Location /rails_prisme/>
        ProxyPass https://vaauscttdbs80.aac.va.gov:8080/rails_prisme/
        ProxyPassReverse https://vaauscttdbs80.aac.va.gov:8080/rails_prisme/
        SetEnv proxy-sendchunks 1
      </Location>
            ------------------------------------------
    * defect 427019. Test notes are included in Jazz.
    * defects 486465 and 486454 - Testers will need to update their prisme.properties file and set the disallow_local_signups_on for their testing environment (example: INTEGRATION and TEST)
        The following URLs will reject the user from going directly to the page when the local login on that environment is not allowed:

        http://localhost:3000/rails_prisme/users/sign_up
        
        You will only be able to see the Login button on the log in page. There is no Sign Up functionality in excluded environments.
        
    * JRuby upgrade branch  from 9.0.4 to 9.1.8 (March 28th 2017)
        * JRuby now depends on Secure Random, but on quiet linux boxes, secure random is known to block for long periods of time.  
            One solution would be to use this workaround on the linux boxes, '-Djava.security.egd=file:/dev/./urandom' into /etc/init.d/tomcat
            but this disables secure random for the entire JVM, potentially leading to security holes with encryption libraries. 
        
        An alternate solution, is to use a tool like 'haveged' http://www.issihosts.com/haveged/ to ensure that the entropy pool on the linux
        box it always sufficient, so that Secure Random doesn't block.
        * install haveged:
        * yum install haveged
        * chkconfig haveged on
        * service haveged start 
        * to check your entropy: cat /proc/sys/kernel/random/entropy_avail
        * restart tomcat (to clear out old JRuby libs)
    * Ban / remove more jaxb libraries to attempt to resolve the intermittent deployment issue 
        
* 2017/03/21 - 3.0.1
    * Revert changes related to PRISME.war display name, which had unintended consequences
    * Rebuild of Release 3

* 2017/03/20 - 3.0
    * updated to fix defect 469188 (508 compliance) for services and admin user edit keyboard functionality
    * removed a jaxb jar that is involved in database build intermittent failures
    * issue 476172 - refactored internal errors to route to utilities controller for git, nexus, and other configuration errors
    * deleted unused files from source control
    * added display name to PRISME.war so it shows up in tomcat
    * Defect 462564 -- Prisme Undeploy - "OK message repeats multiple times instead of one.
    * Defect 482682 Server Error in Integration Environment with the New Database builder in Terminology browser
    * Reversioning from 1.61
    * Production build for Release 3

* 2017/03/16 - 1.60
    * fixed double submit in the GUI for: source package upload, database builder and terminology converter - 476184
    * added migration for removing duplicate ssoi users and unique constraint on ssoi_user_name to the model.
    * defect 469184 - changed the span to a button so that it can receive focus and be execued using the keyboard.
    * Instructions for modifying password in oracle on a devbox when your password expires.

* 2017/03/15 - 1.59
    * added new prisme_err.log, only error and fatal events are sent here.
    * modified checksum result display gui
    * modified discovery result display gui
    * added excel export to discovery, click the green check on the discovery result page.
    * 439585, 439610, 439620, 439593 -- Test team there are comments in Jazz for each of these.

* 2017/03/08 - 1.58
    * Migration and corresponding models in support of discovery
    * Refactoring Checksum to include GUI pages and controller methods for discovery
    * Menuing for both checksum and discovery

* 2017/03/02 - 1.57  
   * Changed validations for db_builder - Task 465866
   * 468082, prisme name change

* 2017/02/16 - 1.56  
   * Checksum - added polling for current checksum requests - tasks 392943, 460348 , 439585 , 439581
   * Fixing regression bug I introduced durring waruuid feature.  Prisme would tell you Tomcat was down or misconfigured when it should tell you no apps were on it.

* 2017/02/09 - 1.55  
   * Checkpoint for checksum GUI. It needs to be wired to the back end once the API is available
   * Added a komet_c.war filter to the prisme.properties file and included code to filter out these wars in the app_deployer if the running environment not specified in the properties file

* 2017/02/03 - 1.54  
   * 439581 GUI - Present list of selectable sites/groups for checksum.  To test: you need to be able to modify the back-end yml file (site_data.yml/group_data.yml) 
       and ensure the gui keeps up after prisme restarts.  The gui is not yet wired to the back end. 
   * 439584 GUI - Display list of selectable subsets for checksum. To test: you need to be able to modify the back-end xml file (TerminologyConfig.xml) and ensure 
       the gui keeps up after prisme restarts.  The gui is not yet wired to the back end. 
   * 452506 - Environment is displayed on prisme next to the version in the footer.
   * 456256 - Add uuid to prisme.properties.  To test: Deploy an Isaac instance.  Name the Isaac during the deploy.  Deploy a Komet instance and bind it to the 
       previous isaac instance you just deployed.  Name the Komet.  On the home page the Komet should tell you it's Isaac (by name).
   * 456257 - Allow Naming Isaac's/Komet.  See above.  Should you stop an Isaac that a Komet relies on there is currently no warning message
   
* 2017/01/26 - 1.53  
   * Git content url changes added.  With this change the db seed files must be rerun!!  Nil pointers will result if they aren't!
   * Komet get the aitc environment hash from prisme and displays the environment next to the version
   * prisme displays environment next to version in the footer.
   * In the config directory is a file called ait_environments.yml.  This file is a candidate for placement in /app/prismeData.

* 2017/01/19 - 1.52  
   * Backend Group support added.  Explanation here: https://vadev.mantech.com:4848/git/commit/rails_prisme.git/eae42b62aa26e9e83298f8c6d4a4152d59ed9497
   * Password recovery instructions

* 2017/01/12 - 1.51  
   * isaac contexts branch is merged in

* 2017/01/12 - 1.50  
   * Added in sync code to keep site table in sync with site_data.yml
   * Backend site work should be working now...  If I modify a couple sites I might get some log output.
   * Existing sites must be modified via the UI.

* 2017/01/05 - 1.49
   * Added in database code to build site table
   * created model code for site table
   * first pass at populating site table during initialization.  Pass assumes existence of site crud gui.  W/o it changes will be made to current impl.
   * home page only allows admins to see isaac rest.

* 2016/12/29 - 1.48
   * Added PRISME super user initialization code allowing AITC to create a super user in case they have lost their credentials
   * Adding in more logging to find source of true zip error (no prisme.properties)
   * The prisme_admin.log file rats out who starts/stops/undeploys things via prisme
   * Show log events property (prisme.properties) now defaults to true.  Log events GUI is available for all admins to see.
   * Added DB Builder validation checking Nexus artifacts as well as the computed GIT tag.
   
* 2016/12/13 - 1.46
    * regression fix on db builder summary page
    * point at latest ISAAC so db builder builds pull in up-to-date metadata

* 2016/12/07 - 1.45
    * regression fix on db builder

* 2016/12/07 - 1.44
    * added in lots of logging at the always level to chase the strange prisme.properties missing bug.
    * Fixed bug 428871 and removed UUID from Jenkins config file

* 2016/12/06 - 1.43
    * added log event tabpage on the home page with admin authentication and a prisme property to hide/show the information
    * Updated isaac / DB builder libraries to pick up isaac bug fixes

* 2016/12/04 - 1.42
    * update isaac dependencies, which will correct a serious performance issue regression in the DB builder.

* 2016/12/02 - 1.41:
    * Common code added to support both prisme and Komet's ability to log events to the event logger.
    * Front end GUI page being added for admins only, allowing admins to acknowledge and view events. (partially complete)
    * Log events controller added. Log events model added.  Baseline of log event views added.

* 2016/11/30 - 1.40:
    * 508 scan - fix fix out-of-sequence heading and javascript event handler.
    * 508 scan - fix out-of-sequence heading, broken, missing and/or duplicate labels when error are shown on form, missing fieldset and legend, unlabeled button, and javascript event handler.
    * 508 scan - fix javascript event handler and out-of-sequence heading.
    * 508 scan - fix broken labels

* 2016/11/29 - 1.39:
    * Just upstream dependency changes (ISAAC, rails_common)
    * 508 Bug Fix: Admin Service Provisioning: color contrast issues on destroy button - update to application.scss, add new btn-danger style


* 2016/11/28 - 1.38:
    * Backend work for future functions, updating dependency stack on isaac.
    * fixed job queue table loading bug. The id was changed with 508 changes which broke the table

* 2016/11/22 - 1.37:
    * navigation - 508 fix for redundant title error appearing in WAVE test tool
    * index files, aesthetic tweaks due navigation updates , buttons need some space above to not be flush with nav
    * 508 fix: index on Terminology Source Package Dashboard add scope=col so table can be read in JAWS
    * joq queue update css to utilize consistent table style

* 2016/11/22 - 1.36:
    * Fixing a bug in the database builder

* 2016/11/18 - 1.35:
   * 508 WAVE tool bug fixes - Defect  #'s:
         - 392182 - _app_deployment_table.html.erb Update font color and background for error message contrast issue
         - 392180, 392182 -  Related to this h2 heading missing and contrast issue also appeared running local, updated to h4 and change fore/back ground colors on _deployments.html.erb and _job_queue.html.erb
   * Fix and auth bug with deployment functionality
   * Fix 413945 - sct extension validation issue
   * Display metadata from komet about the DB komet is connected to
   * Improved session timeout handling (show dialog before timeout)

* 2016/11/09 - 1.34:
    * Added a tooltip to show the description of a tomcat server instance

* 2016/11/08 - 1.33:
    * Fix a regression bug with the logout button

* 2016/11/08 - 1.32: 
    * 508 bug fixes - Defect  #'s:
      - 414519 - Retested local. No fix needed - The Deployment and Job Queue are 'tabs', not tables. These are considered navigation elements and can be toggled 
          with arrow per 508 standards and works fine with JAWS
      - 392092 - Added H1 wrap for first level heading around branding and logo on navigation
      - 392088 - Added aria and title tag labels to remove any empty links on navigation 
      - 392094 - Removed redundant title text from app deployment table. Title tag not required when scope=col defined screen reader will catch table header and read it
      - 392160 - Remove onclick link from icon class logo so that is not device dependent
      - 392162 - Adding fix for h1 fixed this issue due to having h2 level headings
      - 392171 - Added scope and captions to table in app deployment and resolved issues in both WAVE and AXE 508 tools

* 2016/11/02 - 1.31: 
    * Fixed a Manager role permission issue with role editing.

* 2016/11/01 - 1.30: 
    * See the GIT changelog for updates prior to this release.
