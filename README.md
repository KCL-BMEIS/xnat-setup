
## Updates 5th October 2023
 * XNAT 1.8.9.1 default
 * Jupyterhub plugin added to xnat.cfg. Default plugin versions updated.
 * update_xnat_war.sh and restore_from_pg_backup.sh scripts added 
 * Repo tidied, removed redundent files.
 * site-config updated to 1.8.9.1

## Updates 28th March 2023
 * XNAT 1.8.7.1 default, updated default plugins, updated site-config
 * Setting timezone in docker container rather than mounting, taking timezone from host
 * compgen in xnat-setup to check to see if server is restarting (else change access.log does not exist if stopped for a long period)
 * *Upgrade* now an option of the build.sh script (*./build.sh upgrade*)
 * Container names changed - *xnat-web* rather than *xnat-web1*, etc
 * *archive_path* removed from xnat.cfg.
 * Extra checks of *xnat.cfg*


## Updates 20th September 2022

 * Updated plugin version defaults, 1.8.5.1 by default.

## Updates 16th August 2022

 * Updated plugin version defaults, 1.8.5 by default.
 * site-config updated.
 * apt-get update/upgrade added to xnat image. 


## Updates 9th June 2022

 * Removed optional plugins directory as ISO datetime format no longer required - XNAT now has datetime settings built in.
 * Updated site-config settings


##  Updates 10 March 2022: XNAT V. 1.8.4.1

 * Common plugins configured in xnat.cfg - downloaded during installation rather than included in repo.
 * xnat-version added to xnat.cfg
 * pg_backup improved, small bug fixes.


## Quick Installation Instructions:

**Fill in essential fields in xnat.cfg:**
  * xnat_host - example, http://[ip address], or https://[ip address]
   * psql_pwd - create a complex password for the Postgresql backend database.


**Optional: Optimise**
 * Determine the system resources (memory, cpu cores):
    * *lscpu* - cpus x Threads per Core = Number of CPU cores
    * *lsmem* - total online memory
 * Visit https://pgtune.leopard.in.ua/#/. Optimise your postgresql settings for: postgresql V12, *Linux*, *Web Application*. Copy and paste into xnat.cfg.
 * You may want to increase tomcat resource, for example *Xms=1024, Xmx=4096*.
 * Edit docker-compose-stack.yml to increase the limits of each container accordingly (*xnat-web, xnat-db)
 
**Optional: Copy your SSL certificates into the /cert folder.**

**Optional: Place plugins not listed in xnat.cfg in the /plugins directory**


**Using docker stack:**

*cd Linux && sudo ./build.sh*

**With Othanc using docker stack:**

*cd Linux && sudo ./build.sh test*






















