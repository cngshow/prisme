PRISME Changelog 

This changelog summarizes changes and fixes which are a part of each revision.  For more details on the fixes, refer tracking numbers 
where provided, and the git commit history.

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
