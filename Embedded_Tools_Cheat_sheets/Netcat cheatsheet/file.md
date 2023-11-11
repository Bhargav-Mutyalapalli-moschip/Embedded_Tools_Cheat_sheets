# Netcat cheatsheet

* Netcat listening on port 567/TCP:

```bash
$ nc -l 567
```

* Connecting to that port from another machine:

```bash
$ nc 1.2.3.4 5676
```

* To pipe a text file to the listener:

```bash
$ cat infile | nc 1.2.3.4 567 -q 10
```

* To have the listener save a received text file:

```bash
$ nc -l -p 567 > textfile
```

* To transfer a directory, first at the receiving end set up:

```bash
$ nc -l -p 678 | tar xvfpz
```

* Then send the directory:

```bash
$ tar zcfp - /path/to/directory | nc -w 3 1.2.3.4 678
```

* To send a message to your syslog server (the <0> means emerg):

```bash
$ echo '<0>message' | nc -w 1 -u syslogger 514
```

* Setting up a remote shell listener:

```bash
$ nc -v -e '/bin/bash' -l -p 1234 -t
```

or

```bash
$ nc l p 1234 e "c:\windows\system32\cmd.exe"
```

Then telnet to port 1234 from elsewhere to get the shell.

* Using netcat to make an HTTP request:

```bash
$ echo -e "GET http://www.google.com HTTP/1.0nn" | nc -w 5 www.google.com 80
```

* Making a one-page webserver; this will feed homepage.txt to all comers:

```bash
$ cat homepage.txt | nc -v -l -p 80
```
