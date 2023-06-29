# Slurm Docker Cluster

This is a multi-container Slurm cluster using docker-compose.  The compose file
creates named volumes for persistent storage of MySQL and Postgres data files as well as
Slurm state and log directories.

## Containers and Volumes

The compose file will run the following containers:

* mysql
* rstudio1
* rstudio2

The compose file will create the following named volumes:

* var_libpostgres     	 ( -> /var/lib/postgres )
* home	 		 ( -> /home )
* var_lib_rstudio_server ( -> /var/lib/rstudio-server )


## Building the Docker Image

The setup uses one single docker image named `ha-docker-cluster`. You can build this directly via  `docker-compose`

```console
docker-compose build 
```
which will build the `ha-docker-cluster` using default values for the versions of RStudio Workbench (2022.07.2-576.pro12) and SLURM (22.05.4-1).

If you wanted to use a different RStudio Workbench and SLURM version, you can set the environment variables `RSWB_VERSION` and `SLURM_VERSION` to your desired Workbench and SLURM version. e.g. 

```console
export RSWB_VERSION="2022.11.0-daily-206.pro5"

```                                                  


## Starting the Cluster

Run `docker-compose` to instantiate the cluster:

```console
docker-compose up -d
```

Note: Make sure you have the environment variable `RSP_LICENSE` set to a valid license key for RStudio Workbench.  

## RStudio Workbench availability

Once the cluster is up and running, RSWB is available at http://localhost:8787 and http://localhost:8788

## Accessing the Cluster

Use `docker-compose exec` to run a bash shell on the rstudio1 container:

```console
docker compose exec rstudio1 bash
```
## Stopping and Restarting the Cluster

```console
docker-compose stop
docker-compose start
```

or for restarting simply

```console
docker-compose restart
```

## Deleting the Cluster

To remove all containers and volumes, run:

```console
docker-compose down
docker volume ls  | grep ha-docker-cluster | \
	awk '{print $2}' | xargs docker volume rm 
```
