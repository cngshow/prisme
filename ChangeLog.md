PRISME Changelog 

This changelog summarizes changes and fixes which are a part of each revision.  For more details on the fixes, refer tracking numbers 
where provided, and the git commit history.

* 2016/11/?? - 1.32: 
    * 508 bug fixes - Defect  #'s:
      414519 - Retested local. No fix needed - The Deployment and Job Queue are 'tabs', not tables. These are considered navigation elements and can be toggled with arrow per 508 standards and works fine with JAWS
      392092 - Added H1 wrap for first level heading around branding and logo on navigation
      392088 - Added aria and title tag labels to remove any empty links on navigation 
      392094 - Removed redundant title text from app deployment table. Title tag not required when scope=col defined screen reader will catch table header and read it
      392160 - Remove onclick link from icon class logo so thta is not device dependent
      392162 - Adding fix for h1 fixed this issue due to having h2 level headings
      392171 - Added scope and captions to table in app deployment and resolved issues in both WAVE and AXE 508 tools

* 2016/11/02 - 1.31: 
    * Fixed a Manager role permission issue with role editing.

* 2016/11/01 - 1.30: 
    * See the GIT changelog for updates prior to this release.
