## fourtwenty-utils

420coin utilities, dev tools, scripts, etc

* `g420up.sh`: primitive wrapper to [g420](https://github.com/420integrated/go-420coin)
* `g420cluster.sh`: launch local clusters non-interactively (https://github.com/420integrated/go-420coin/wiki/Setting-up-private-network-or-local-cluster)
* `netstatconf.sh`: auto-generate the json config of your local cluster for netstat (https://github.com/420integrated/go-420coin/wiki/Setting-up-monitoring-on-local-cluster)

##  Usage

### Launch an instance 

```
G420=./g420 bash /path/to/fourtwenty-utils/g420up.sh <rootdir> <dd> <run> <params>...
```

This will
- if it does not exist yet, then create an account with password _dd_ [NEVER USE THIS LIVE]
- bring up a node with instance id _dd_ (double digit)
- using _rootdir/dd_ as data directory (where blockchain etc. are stored)
- listening on port _130dd_, (like 13000, 13001, ...)
- with the account unlocked
- launching json-rpc server on port _61dd_ (like 6100, 6101, 6102, ...)
- extra params are passed to `g420` 

```
$ G420=./g420 bash ~/fourtwenty-utils/g420up.sh ~/tmp/fourtwenty/ 04 09 --mine console 
Welcome to the FRONTIER
> fourtwenty.getBalance(fourtwenty.coinbase)
'198400000000001'
>
```

### Launch a cluster 
Running a cluster of 8 instances under dir `tmp/fourtwenty/` isolated on local 420coin network (id 13001), launch 05. Give external IP and pass extra param `--mine`.

```
G420=./g420 bash g420cluster.sh <root> <n> <network_id> <runid> <IP> [[params]...]
```

This will set up a local cluster of nodes
- `<n>` is the number of clusters
- `<root>` is the root directory for the cluster, the nodes are set up 
  with datadir `<root>/00`, `<root>/01`, ...
- new accounts are created for each node
- they listening on port _130dd_ (like 13000, 13001, ...)
- json-rpc server is launched on port _61dd_ (like 6100, 6101, ...)
- by collecting the nodes' node-urls, they get connected to each other
- if enode has no IP, `<IP>` is substituted
- if `<network_id>` is not 0, they will not connect to a default client,
  resulting in a private isolated network
- the nodes log into `<root>/00.<runid>.log`, `<root>/01.<runid>.log`, ...
- `<runid>` is just an arbitrary tag or index you can use to log multiple 
  subsequent launches of the same cluster, I recommend sequential double digit ids
- the cluster can be killed with `killall -QUIT g420` 
- the nodes can be restarted from the same state individually using the `g420up.sh` script
- if you want to interact with the nodes, use a json-rpc client
- you can supply additional params on the command line which will be passed 
  to `g420up.sh` and eventually to `g420` for each node, for instance `-vmodule=http=6 -mine -minerthreads=8` is a good one.

```
G420=./g420 bash g420cluster.sh ./leagues/1300/cicada 2 1300 05 77.160.58.3 -mine 
launching node 0/2 ---> tail -f ./leagues/1300/cicada/00.05.log
Welcome to the FRONTIER
launching node 1/2 ---> tail -f ./leagues/1300/cicada/01.05.log
Welcome to the FRONTIER
```

fill create:
```
./leagues/1300/cicada/
./leagues/1300/cicada/1300/
./leagues/1300/cicada/1300/00/
./leagues/1300/cicada/1300/00.05.log
./leagues/1300/cicada/1300/00.05.glog
./leagues/1300/cicada/1300/01/
./leagues/1300/cicada/1300/01.05.log
./leagues/1300/cicada/1300/01.05.glog
./leagues/1300/cicada/1300/
```

You can kill and restart individual nodes or the entire cluster safely, by using different runid you can separate logs for the individual runs in a neat way.

```
killall -QUIT g420
```

Using the `-QUIT` signal is very useful because it dumps the stacktrace into the glog file which you can attach to any bugreport or issue. 

### Monitor your local cluster:


#### Installing the eth-netstats monitor

```
git clone https://github.com/420integrated/fourtwenty-netstats
cd fourtwenty-netstats
npm install
```

####Configuring netstat for your cluster

```
bash /path/to/fourtwenty-utils/netstatconf.sh <number_of_clusters> <name_prefix> <ws_server> <ws_secret> 
```

- will output resulting app.json to stdout
- `number_of_clusters` is the number of nodes in the cluster.
- `name_prefix` is a prefix for the node names as will appear in the listing.
- `ws_server` is the fourtwenty-netstats server. Make sure you write the full URL, for example: http://localhost:3100.
- `ws_secret` is the fourtwenty-netstats secret.

For example:

```
git clone https://github.com/420integrated/fourtwenty-utils
cd fourtwenty-utils
bash ./netstatconfig.sh 8 cicada http://localhost:3100 kscc > ~/leagues/1300/cicada.json
```

####Installing fourtwenty-net-intelligence-api

```
git clone https://github.com/420integrated/fourtwenty-net-intelligence-api
cd fourtwenty-net-intelligence-api
npm install
sudo npm install -g pm2
```

#### Starting the fourtwenty-net-intelligence-api

to start the fourtwenty-net-intelligence-api client for your cluster

```
cd fourtwenty-net-intelligence-api
pm2 start ~/leagues/1300/cicada.json
[PM2] Process launched
[PM2] Process launched
┌──────────┬────┬──────┬───────┬────────┬─────────┬────────┬─────────────┬──────────┐
│ App name │ id │ mode │ pid   │ status │ restart │ uptime │ memory      │ watching │
├──────────┼────┼──────┼───────┼────────┼─────────┼────────┼─────────────┼──────────┤
│ cicada-0 │ 1  │ fork │ 93855 │ online │ 0       │ 0s     │ 10.289 MB   │ disabled │
│ cicada-1 │ 2  │ fork │ 93858 │ online │ 0       │ 0s     │ 10.563 MB   │ disabled │
└──────────┴────┴──────┴───────┴────────┴─────────┴────────┴─────────────┴──────────┘
 Use `pm2 show <id|name>` to get more details about an app
```


####Starting the monitor 

Use your own fourtwenty-netstat server to monitor a league on a port corresponding to a league

```
cd fourtwenty-netstat
PORT=3100 WS_SECRET=kscc npm start &
```

and enjoy:
```
open http://localhost:3100
```
