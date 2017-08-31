#!/bin/bash

cat >> /tmp/bashrc  << EOF

        export http_proxy="http://9.21.53.14:3128"
        export https_proxy=$http_proxy
        export ftp_proxy=$http_proxy
        export rsync_proxy=$http_proxy
        export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
EOF


for  arg in `seq  $1 $2` 

 do  scp /tmp/bashrc  172.29.211.$arg:/root/.bashrc


done
