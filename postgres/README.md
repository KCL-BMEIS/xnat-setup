* Uses debian image. More stable than alpine. However alpine image available for upgrading (do not upgrade from alpine -> debian)
* For Linux, huge pages should be set to 'off'

* Had to increase shm size from default docker 64mb to 512.
*     tmpfs:
      - /dev/shm:size=1g
* NOTE: shm_size: does not work for swarm
* Log into postgresql container to verify:
* cat /proc/mounts | grep shm

