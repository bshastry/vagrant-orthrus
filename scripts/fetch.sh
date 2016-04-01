#!/usr/bin/env bash
echo -e "\t[+] Installing Joern core"
wget https://github.com/fabsx00/joern/archive/0.3.1.tar.gz &> /dev/null
tar xfz 0.3.1.tar.gz && rm 0.3.1.tar.gz
cd joern-0.3.1 && wget http://mlsec.org/joern/lib/lib.tar.gz &> /dev/null
tar xfz lib.tar.gz && rm lib.tar.gz
ant &> /dev/null && ant tools &> /dev/null
echo "alias joern='java -jar `pwd`/bin/joern.jar'" > ~/.bash_aliases
source ~/.bashrc

echo -e "\t[+] Installing Neo4J 2.1.8"
cd .. && wget http://neo4j.com/artifact.php?name=neo4j-community-2.1.8-unix.tar.gz -O neo4j-community-2.1.8-unix.tar.gz &> /dev/null
tar xzf neo4j-community-2.1.8-unix.tar.gz && rm neo4j-community-2.1.8-unix.tar.gz
echo "export Neo4jDir=`pwd`/neo4j-community-2.1.8" >> ~/.bash_aliases
source ~/.bashrc

echo -e "\t[+] Installing prebuilt Gremlin"
wget http://mlsec.org/joern/lib/neo4j-gremlin-plugin-2.1-SNAPSHOT-server-plugin.zip &> /dev/null
unzip neo4j-gremlin-plugin-2.1-SNAPSHOT-server-plugin.zip -d $Neo4jDir/plugins/gremlin-plugin &> /dev/null
rm neo4j-gremlin-plugin-2.1-SNAPSHOT-server-plugin.zip

echo -e "\t[+] Install python-joern"
sudo pip install py2neo &> /dev/null
wget https://github.com/fabsx00/python-joern/archive/0.3.1.tar.gz &> /dev/null
tar xfz 0.3.1.tar.gz && rm 0.3.1.tar.gz && cd python-joern-0.3.1
sudo python2 setup.py install &> /dev/null
cd ..

echo -e "\t[+] Adding SecT gitlab public key to known hosts"
HOST="gitlab.sec.t-labs.tu-berlin.de"
touch ~/.ssh/known_hosts
ssh-keyscan -t rsa,dsa $HOST 2>&1 | sort -u - ~/.ssh/known_hosts > ~/.ssh/tmp_hosts
cat ~/.ssh/tmp_hosts >> ~/.ssh/known_hosts

echo -e "\t[+] Installing joern tools"
git clone git@gitlab.sec.t-labs.tu-berlin.de:mleutner/joern-tools.git &> /dev/null
cd joern-tools && sudo python2 setup.py install &> /dev/null
cd ..

echo -e "\t[+] Installing afl-fuzz latest"
wget http://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz &> /dev/null
tar xzf afl-latest.tgz && rm afl-latest.tgz && cd afl*
make -j &> /dev/null && sudo make install &> /dev/null && cd ..

echo -e "\t[+] Setting up .gdbinit"
cat <<EOF >> ~/.gdbinit
set auto-load safe-path /

define hook-quit
    set confirm off
end

define printfault
    printf "Faulting mem location is %#lx, pc is %#lx, esp is %#x, ebp is %#x\n", \$_siginfo._sifields._sigfault.si_addr, \$pc, \$esp, \$ebp
end
EOF

echo -e "\t[+] Creating workspace and fetching a couple of production codebases"
mkdir -p workspace && cd workspace
echo -e "\t[+] Fetching (buggy) OpenvSwitch 2.3.2"
wget http://openvswitch.org/releases/openvswitch-2.3.2.tar.gz &> /dev/null
tar xzf openvswitch-2.3.2.tar.gz && rm openvswitch-2.3.2.tar.gz && cd openvswitch-2.3.2

echo -e "\t[+] Fetching crashing inputs for test-flows"
cd tests && wget --no-check-certificate "https://owncloud.sec.t-labs.tu-berlin.de/owncloud/public.php?service=files&t=43e3207d49afe11ab0923b20a80bbff9&download" -O afl-crashes.tar.gz &> /dev/null
tar -xzf afl-crashes.tar.gz && rm afl-crashes.tar.gz
echo -e "\t[+] Patching test-flows.c so it reads from file instead of stdin"
patch -p1 test-flows.c < patch-testflows &> /dev/null
echo -e "\t[+] Building OVS 2.3.2"
cd .. && ./configure &> /dev/null && make &> /dev/null

echo -e "\t[+] Creating crash.log for OVS 2.3.2."
echo -e "\t\t[+] This reads over 13000 crashing inputs, so it is going to take a while..."
echo -e "\t\t[+] Abort mid way to see sample output"

cat <<EOF >> getcrashlog.sh
#!/usr/bin/env bash
let "count = 0"
for crashing_input in \$(ls tests/SESSION*/crashes/id*); do
        let "count += 1"
        echo -e "--------- Crashing input no. \$count ----------"
        gdb --silent -ex=r -ex=printfault -ex=bt -ex=quit --args \
	./tests/ovstest test-flows tests/flows \$crashing_input
        echo -e "----------------------------------------------"
        echo -e ""
done
EOF
chmod +x getcrashlog.sh
./getcrashlog.sh &>> crash.log
