# !/bin/bash
# bash cluster <root> <network_id> <number_of_nodes>  <runid> <local_IP> [[params]...]

# sets up a local 420coin network cluster of nodes
# - <number_of_nodes> is the number of nodes in cluster
# - <root> is the root directory for the cluster, the nodes are set up
#   with datadir `<root>/<network_id>/00`, `<root>/ <network_id>/01`, ...
# - new accounts are created for each node
# - they launch on port 13001, 13002, ...
# - they star rpc on port 6174, 6175, ...
# - by collecting the nodes nodeUrl, they get connected to each other
# - if enode has no IP, `<local_IP>` is substituted
# - if `<network_id>` is not 2020, they will not connect to the default client,
#   resulting in a private isolated network
# - the nodes log into `<root>/00.<runid>.log`, `<root>/01.<runid>.log`, ...
# - The nodes launch in mining mode
# - the cluster can be killed with `killall g420` 
#   and restarted from the same state
# - if you want to interact with the nodes, use rpc
# - you can supply additional params on the command line which will be passed
#   to each node, for instance `-mine`


root=$1
shift
network_id=$1
dir=$root/$network_id
mkdir -p $dir/data
mkdir -p $dir/log
shift
N=$1
shift
ip_addr=$1
shift

# G420=g420

if [ ! -f "$dir/nodes"  ]; then

  echo "[" >> $dir/nodes
  for ((i=0;i<N;++i)); do
    id=`printf "%02d" $i`
    if [ ! $ip_addr="" ]; then
      ip_addr="[::]"
    fi

    echo "getting enode for instance $id ($i/$N)"
    fourtwenty="$G420 --datadir $dir/data/$id --port 130$id --networkid $network_id"
    cmd="$fourtwenty js <(echo 'console.log(admin.nodeInfo.enode); exit();') "
    echo $cmd
    bash -c "$cmd" 2>/dev/null |grep enode | perl -pe "s/\[\:\:\]/$ip_addr/g" | perl -pe "s/^/\"/; s/\s*$/\"/;" | tee >> $dir/nodes
    if ((i<N-1)); then
      echo "," >> $dir/nodes
    fi
  done
  echo "]" >> $dir/nodes
fi

for ((i=0;i<N;++i)); do
  id=`printf "%02d" $i`
  # echo "copy $dir/data/$id/static-nodes.json"
  mkdir -p $dir/data/$id
  # cp $dir/nodes $dir/data/$id/static-nodes.json
  echo "launching node $i/$N ---> tail-f $dir/log/$id.log"
  echo G420=$G420 bash ./g420up.sh $dir $id --networkid $network_id $*
  G420=$G420 bash ./g420up.sh $dir $id --networkid $network_id $*
done
