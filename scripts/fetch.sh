#!/usr/bin/env bash

if [ ! -e ~/.ssh/id_rsa ]; then
echo -e "\t[+] Installing SecT gitlab deploy keys"
tar xf /vagrant/deploy.tar -C ~/.ssh/
fi

if [ ! -e joern-0.3.1 ]; then
echo -e "\t[+] Installing Joern"
echo -e "\t\t[+] Installing Joern core"
wget https://github.com/fabsx00/joern/archive/0.3.1.tar.gz &> /dev/null
tar xfz 0.3.1.tar.gz && rm 0.3.1.tar.gz
cd joern-0.3.1 && wget http://mlsec.org/joern/lib/lib.tar.gz &> /dev/null
tar xfz lib.tar.gz && rm lib.tar.gz
ant &> /dev/null && ant tools &> /dev/null
echo "alias joern='java -jar `pwd`/bin/joern.jar'" > ~/.bash_aliases
source ~/.bashrc
fi

if [ ! -e neo4j-community-2.1.8 ]; then
echo -e "\t\t[+] Installing Neo4J 2.1.8"
cd .. && wget http://neo4j.com/artifact.php?name=neo4j-community-2.1.8-unix.tar.gz -O neo4j-community-2.1.8-unix.tar.gz &> /dev/null
tar xzf neo4j-community-2.1.8-unix.tar.gz && rm neo4j-community-2.1.8-unix.tar.gz
echo "export Neo4jDir=`pwd`/neo4j-community-2.1.8" >> ~/.bash_aliases
source ~/.bashrc

echo -e "\t\t[+] Installing prebuilt Gremlin"
wget http://mlsec.org/joern/lib/neo4j-gremlin-plugin-2.1-SNAPSHOT-server-plugin.zip &> /dev/null
unzip neo4j-gremlin-plugin-2.1-SNAPSHOT-server-plugin.zip -d $Neo4jDir/plugins/gremlin-plugin &> /dev/null
rm neo4j-gremlin-plugin-2.1-SNAPSHOT-server-plugin.zip
fi

if [ ! -e python-joern-0.3.1 ]; then
echo -e "\t\t[+] Install python-joern"
sudo pip install py2neo &> /dev/null
wget https://github.com/fabsx00/python-joern/archive/0.3.1.tar.gz &> /dev/null
tar xfz 0.3.1.tar.gz && rm 0.3.1.tar.gz && cd python-joern-0.3.1
sudo python2 setup.py install &> /dev/null
cd ..
fi

echo -e "\t\t[+] Adding SecT gitlab public key to known hosts"
HOST="gitlab.sec.t-labs.tu-berlin.de"
touch ~/.ssh/known_hosts
ssh-keyscan -t rsa,dsa $HOST 2>&1 | sort -u - ~/.ssh/known_hosts > ~/.ssh/tmp_hosts
cat ~/.ssh/tmp_hosts >> ~/.ssh/known_hosts

if [ ! -e joern-tools ]; then
echo -e "\t\t[+] Installing joern tools"
git clone git@gitlab.sec.t-labs.tu-berlin.de:mleutner/joern-tools.git &> /dev/null
cd joern-tools && sudo python2 setup.py install &> /dev/null
cd ..
fi

if [ ! -e orthrus ]; then
echo -e "\t\t[+] Installing orthrus"
git clone git@gitlab.sec.t-labs.tu-berlin.de:mleutner/orthrus.git &> /dev/null
echo -e "\t\t[+] Install gdb orthrus plugin"
cd orthrus &> /dev/null
sudo cp -r ./gdb-orthrus /usr/share/gdb/python/ &> /dev/null
cd ..
fi

if [ ! -d afl-cov ]; then
echo -e "\t[+] Installing afl-fuzz latest"
wget http://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz &> /dev/null
tar xzf afl-latest.tgz && rm afl-latest.tgz && cd afl*
make -j &> /dev/null && sudo make install &> /dev/null && cd ..
echo -e "\t\t[+] Installing afl-cov"
git clone https://github.com/mrash/afl-cov.git &> /dev/null
sudo update-alternatives --install /usr/local/bin/afl-cov afl-cov $HOME/afl-cov/afl-cov 50 &> /dev/null
echo -e "\t\t[+] Install pysancov-3.8"
wget -q https://raw.githubusercontent.com/llvm-mirror/compiler-rt/release_38/lib/sanitizer_common/scripts/sancov.py &> /dev/null
chmod +x sancov.py &> /dev/null
sudo mv sancov.py /usr/local/bin/pysancov &> /dev/null
echo -e "\t\t[+] Installing afl-sancov"
git clone git@gitlab.sec.t-labs.tu-berlin.de:collaboration/afl-sancov.git --branch mindiff-mod &> /dev/null
sudo update-alternatives --install /usr/local/bin/afl-sancov afl-sancov $HOME/afl-sancov/afl-sancov.py 50 &> /dev/null
echo -e "\t\t[+] Installing prebuilt clang"
wget --no-check-certificate "https://owncloud.sec.t-labs.tu-berlin.de/owncloud/public.php?service=files&t=d43c249e3eb3cd908253009578a6a167&download" -O clang-prebuilt.tar.gz &> /dev/null
tar xzf clang-prebuilt.tar.gz &> /dev/null
rm clang-prebuilt.tar.gz
echo -e "\t\t[+] Installing pyl2c"
git clone git@gitlab.sec.t-labs.tu-berlin.de:static-analysis/pyl2c.git &> /dev/null
sudo update-alternatives --install /usr/local/bin/pyl2c pyl2c $HOME/pyl2c/pyl2c.py 50 &> /dev/null
fi

if [ ! -e exploitable ]; then
echo -e "\t[+] Install gdb exploitable plugin"
git clone https://github.com/bshastry/exploitable.git &> /dev/null
cd exploitable && python setup.py build &> /dev/null
sudo cp -r build/lib*/exploitable /usr/share/gdb/python/ &> /dev/null
cd ..
fi

echo -e "\t[+] Setting up gdb"
echo -e "\t\t[+] Setting up .gdbinit"
rm -f ~/.gdbinit
cat <<EOF >> ~/.gdbinit
source /usr/share/gdb/python/exploitable/exploitable.py
source /usr/share/gdb/python/gdb-orthrus/orthrus.py
set auto-load safe-path /

define hook-quit
    set confirm off
end

define printfault
    printf "Faulting mem location is %#lx, pc is %#lx, rsp is %#lx, rbp is %#lx\n", \$_siginfo._sifields._sigfault.si_addr, \$pc, \$rsp, \$rbp
end
EOF

if [ ! -e workspace ]; then
echo -e "\t[+] Creating workspace and fetching a couple of production codebases"
mkdir -p workspace && cd workspace
echo -e "\t\t[+] Fetching (buggy) OpenvSwitch 2.3.2"
wget http://openvswitch.org/releases/openvswitch-2.3.2.tar.gz &> /dev/null
tar xzf openvswitch-2.3.2.tar.gz && rm openvswitch-2.3.2.tar.gz && cd openvswitch-2.3.2

echo -e "\t\t[+] Fetching afl-out for test-flows"
cd tests && wget --no-check-certificate "https://owncloud.sec.t-labs.tu-berlin.de/owncloud/public.php?service=files&t=3327d562345a3c2cbb306d9781b55bd0&download" -O afl-out.tar.gz &> /dev/null
tar -xzf afl-out.tar.gz && rm afl-out.tar.gz
echo -e "\t\t[+] Patching test-flows.c so it reads from file instead of stdin"
patch -p1 test-flows.c < patch-testflows &> /dev/null
echo -e "\t\t[+] Building OVS 2.3.2"
cd .. && CFLAGS="-O0 -g" ./configure &> /dev/null && make &> /dev/null

echo -e "\t\t[+] Creating sample crash.log for OVS 2.3.2."
echo -e "\t\t\t[+] Please wait...This takes approximately 2 minutes"
echo -e "\t\t\t[+] To obtain a full crash.log, run getcrashlog.sh till it returns"

cat <<EOF >> getcrashlog.sh
#!/usr/bin/env bash
let "count = 0"
for crashing_input in \$(ls tests/afl-out/summary/crashes/id*); do
        let "count += 1"
        echo -e "--------- Crashing input no. \$count ----------"
        gdb -q -ex="set args test-flows tests/flows "\$crashing_input" &> /dev/null" -ex="run" -ex="orthrus" -ex="gcore core" -ex="quit" --args ./tests/ovstest
        echo -e "----------------------------------------------"
        echo -e ""
done
EOF
chmod +x getcrashlog.sh
(timeout 100 ./getcrashlog.sh &>> crash.log)

echo -e "\t\t[+] Fetching latest libosip (v4.1.0)"
cd .. && wget https://ftp.gnu.org/gnu/osip/libosip2-4.1.0.tar.gz &> /dev/null
tar -xzf libosip2-4.1.0.tar.gz && rm libosip2-4.1.0.tar.gz
echo -e "\t\t[+] Building libosip"
cd libosip2-4.1.0 && CFLAGS="-O0 -g" ./configure --enable-test &> /dev/null && make &> /dev/null
cd src/test && make check &> /dev/null
echo -e "\t\t[+] Fetching crashing inputs for torture_test"
wget --no-check-certificate "https://owncloud.sec.t-labs.tu-berlin.de/owncloud/public.php?service=files&t=6258589b8121c7c39c7d962189169f2f&download" -O afl-out.tar.gz &> /dev/null
tar -xzf afl-out.tar.gz && rm afl-out.tar.gz
echo -e "\t\t[+] Creating sample crash.log for libosip-4.1.0"
echo -e "\t\t\t[+] Please wait...This takes approximately 2 minutes"
echo -e "\t\t\t[+] To obtain a full crash.log, run getcrashlog.sh till it returns"

cat <<EOF >> getcrashlog.sh
#!/usr/bin/env bash
let "count = 0"
for crashing_input in \$(ls afl-out-clone/summary/crashes/id*); do
        let "count += 1"
        echo -e "--------- Crashing input no. \$count ----------"
        LD_PRELOAD="../osipparser2/.libs/libosipparser2.so" gdb -q -ex="set args "\$crashing_input" 0 -c &> /dev/null" -ex="run" -ex="orthrus" -ex="gcore core" -ex=quit --args .libs/torture_test
        echo -e "----------------------------------------------"
        echo -e ""
done
EOF
chmod +x getcrashlog.sh
(timeout 100 ./getcrashlog.sh &>> crash.log)
fi
