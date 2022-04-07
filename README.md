# Minotaur

Experimental libbpf code without CORE for runtime ebpf compilation inside the container

Build
```
docker build -t daemon1024/minotaur .
```

Use the following command to start container:
```
docker run --rm -it \
--pid=host --privileged \
-v /usr/src:/usr/src:ro \
-v /lib/modules:/lib/modules:ro \
-v /sys/kernel/debug:/sys/kernel/debug:ro \
daemon1024/minotaur:latest
```