* Uses debian image. More stable than alpine. However, alpine image available for upgrading (do not upgrade from alpine -> debian)

* Had to increase shm size from default docker 64mb to 512.
* volumes:
  shm:
    driver: local
    driver_opts:
      type: tmpfs
      device: tmpfs
      o: "size=1g,mode=1777"

* Log into postgresql container to verify:
* cat /proc/mounts | grep shm
* added pg_maintenace to run in container. Skips two huge tables. I had a problem but this shoud be fine for quick cleanups. 
