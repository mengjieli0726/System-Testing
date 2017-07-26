#_Tools or Scripts of Performance Testing_

## Performance Testing

_Configure the SSH passwordless_

		#!/bin/bash
		for a in $(seq 1 3)
		do
		       sshpass -p 'Letmein123' ssh-copy-id -o StrictHostKeyChecking=no  root@cfc1m${a}p.ma.platformlab.ibm.com
		
		done


_**Remote enable docker service on all nodes**_

   1. Create the docker repo and dependency package repo
		
		cat << EOF >> /etc/yum.repos.d/docker.repo
		
		[dockerrepo]
		name=Docker Repository
		baseurl=http://ftp.unicamp.br/pub/ppc64el/rhel/7_1/docker-ppc64el/
		proxy=http://9.21.53.14:3128
		enabled=1
		gpgcheck=0
		#gpgkey=https://yum.dockerproject.org/gpg
		
		EOF
		
		cat << EOF >> /etc/yum.repos.d/platformlab.repo
			
		[rhel-server-7.2-x86_64]
		name=Red Hat Enterprise Linux $releasever - $basearch
		gpgcheck=0
		enabled=1
		proxy=http://9.21.53.14:3128
		baseurl=http://yum.platformlab.ibm.com/deploy/yum/redhat/releases/rhel-server-7.2-ppc64le/		
		
		EOF

		
  2. Remote install docker engine and start docker service, check docker version.

			#/bin/bash
			
			for a in $(seq 1001 1060)
			
			do
			
			
			ssh -t root@cfc${a}p.ma.platformlab.ibm.com  yum clean all;  yum install  docker-engine -y; systemctl restart docker; docker version
			
			
		   done
		   
_**Using the crudini tool to add batch host\_ip in hosts file**_

   1. install the crudini tool.

    		yum install crudini-0.9-1.el7.noarch

   
   2. Add host\_ip in to install\_path/cluster/hosts file.

      Master/Woker/Proxy node: 
        
	    #!/bin/bash
       
        for a in `seq 1 60`

         do 
          
           crudini --set hosts master/worker/proxy 172.29.216.$a

         done
      
      Note: Please replace the crudini items according requirements.

_**Restful api response time**_

1. Get kubernetes nodes restful api reposonse time:

		curl http://127.0.0.1:8888/api/v1/nodes ?  -o /dev/null -s -w "time_connect: %{time_connect}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n"|grep time_total|awk -F ":"  '{print $2}'|head -n 1 
	  
2. Get kubernetes pods restful api response time:	  
				
		curl http://127.0.0.1:8888/api/v1/pods ?  -o /dev/null -s -w "time_connect: %{time_connect}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n"|grep time_total|awk -F ":"  '{print $2}'|head -n 1
		
3. Get kubernetes deployment restful api response time

  1). Create authentication tokens
  
		export CMD=`curl -k -c mycookie -d "{\"uid\":\"admin\",\"password\":\"admin\"}" https://master.cfc:8443/acs/api/v1/auth/login`
		
		export IM_TOKEN=$(echo $CMD | python -c 'import sys,json; print json.load(sys.stdin)["token"]' )
		
  2). Get deployments api response time from ICp GUI
  
  		curl -k -s -H "Authorization:Bearer $IM_TOKEN" https://9.21.53.15:8443/kubernetes/apis/extensions/v1beta1//deployments? -o /dev/null -s -w "time_connect: %{time_connect}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n"

  3). Get deployments api response time from kubernetes CLI
  
  		curl -k -s  -H "Authorization:Bearer $IM_TOKEN"  https://9.21.53.15:8001/apis/extensions/v1beta1/namespaces/default/deployments -o /dev/null -s -w "time_connect: %{time_connect}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n"

_**Create Mutiple Deployment**_

1. Draft the deployment yaml file

		apiVersion: extensions/v1beta1
		kind: Deployment
		metadata:
		  name: default-nginx-ppc64le-ng
		  namespace: default
		  annotations:
		    deployment.kubernetes.io/revision: '1'
		spec:
		  replicas: 1
		  selector:
		    matchLabels:
		      app: default-nginx-ppc64le-ng
		  template:
		    metadata:
		      labels:
		        app: default-nginx-ppc64le-ng
		    spec:
		      containers:
		      - name: nginx-ppc64le
		        image: private.reg:5000/redos/nginx-ppc64le:latest
		        ports:
		        - containerPort: 80
		          protocol: TCP
		        imagePullPolicy: IfNotPresent
		        
2. Using the kubectl CLI to create multiple deployment

		#!/bin/bash
		
		for a in `seq 1000 1060`
		
		 do
		
		echo $a; cp -f /root/deployment.yaml /root/deployment_tmp.yaml; sed -i "s/default-nginx-ppc64le-ng/default-nginx-ppc64le-ng"$a"/g" /root/deployment_tmp.yaml; kubectl create -f /root/deployment_tmp.yaml
		
		
		 done
		 
_**Measure Pod/User/ Operation time**_

1. Measure the 2000 pods start up time: 

		#!/bin/bash
		
		start=`date +%s.%4N`; echo $start;
				
		kubectl create -f deployment.yaml;
		
		while true
		
		 do a=`kubectl get pods |tail -n +2|grep Running |wc -l`
		
		      if  [[ "$a" -eq 2000  ]]; then
		      
		       end=`date +%s.%4N`; echo  $end - $start | bc ; break
		
		     fi
		
		 done

2. Measure the 2000 pods terminate time:

		#!/bin/bash
		
		start=`date +%s.%4N`; echo $start;
		
		kubectl delete -f deployment.yaml;
		
		end=`date +%s.%4N`; echo $end ; echo  $end - $start | bc
		
		
3. Measure 1000 users creation time

		#!/bin/bash
		
		for a in `seq 1002 2000`
		
		 do
		
		curl -k -b mycookie -X POST https://master.cfc:8443/acs/api/v1/users -d "{\"email\":\"a@\",\"password\":\"Letmein123\",\"name\":\"b$a\",\"project\":\"84a297fdf0d04c79bca68776950260e7\"}"  -o /dev/null -s -w "time_connect: %{time_connect}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n"|grep "time_total"
		
		
		 done
		 
4. Measure 1000 users delete time

		#!/bin/bash
		curl -k -b mycookie https://master.cfc:8443/acs/api/v1/users|jq . |grep -v "aa7f0f1765bf4f3691958a8b7bba0bc3"|grep uid > uid.txt
		
		while read line  
		
		do 
		
		curl -k -b mycookie -X DELETE https://master.cfc:8443/acs/api/v1/users/$line  -o /dev/null -s -w "time_connect: %{time_connect}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n"|grep time_total
		
		 done  < uid.txt


5. Measure 1000 projects creation time

		#!/bin/bash
		
		for a in `seq 1 1000`
		
		 do
		
		 curl -k -b mycookie -X POST https://master.cfc:8443/acs/api/v1/namespaces -d "{\"name\":\"mjli$a\",\"description\":\"mjlinamespace\"}" -o /dev/null -s -w "time_connect: %{time_connect}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n"|grep time_total
		
		done
6. Measure 1000 deployment creation time

   1). create deployment yaml file
   
		apiVersion: extensions/v1beta1
		kind: Deployment
		metadata:
		  name: default-nginx
		  namespace: default
		  annotations:
		    deployment.kubernetes.io/revision: '1'
		spec:
		  replicas: 10
		  selector:
		    matchLabels:
		      app: default-nginx
		  template:
		    metadata:
		      labels:
		        app: default-nginx
		    spec:
		      containers:
		      - name: nginx
		        image: nginx:latest
		        ports:
		        - containerPort: 80
		          protocol: TCP
		        imagePullPolicy: IfNotPresent
		        volumeMounts:
		        - mountPath: "/opt/nfs/"
		          name: mypd
		      volumes:
		      - name: mypd
		        persistentVolumeClaim:
		          claimName: pvc-test
      2) Using kubernetes CLI to create deployment
      
		#!/bin/bash
		
		start=`date +%s.%4N`
		
		for a in `seq 1000 2001`
		
		   do		
		         echo $a; cp -f /root/deployment.yaml /root/deployment_tmp.yaml; sed -i "s/default-nginx-ppc64le-ng/default-nginx-ppc64le-ng"$a"/g" /root/deployment_tmp.yaml; kubectl create -f /root/deployment_tmp.yaml
		
		   done
		
	    while true
		
		do		
		        b=`kubectl get pods |tail -n +2|grep Running |wc -l`
		
		
		        if  [[ "$b" -eq 1000  ]] ; then
		
		           end=`date +%s.%4N` ; echo $end - $start | bc ; break;
		
		        fi	
	    done
	    
7. Measure 1000 deployment deletion time

		#!/bin/bash
		
		start=`date +%s.%4N`
		
		kubectl delete deployment $(kubectl get deployments|awk '{print $1}'|tail -n +2|xargs echo -n)
		
		end=`date +%s.%4N`
		
		echo $end - $start | bc
		
		