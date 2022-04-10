# Minotaur

Experimental libbpf code without CORE for runtime ebpf compilation inside the container

Build
```sh
docker build -t daemon1024/minotaur-init --target init .
docker build -t daemon1024/minotaur --target main .
```

Use the following command to start pod:
```sh
kubectl apply -f pod.yaml
```

OR

Build
```sh
docker build -t daemon1024/minotaur --target full .
```

Use the following command to start container:
```sh
docker run --rm -it \
    --pid=host --privileged \
    -v /usr/src:/usr/src:ro \
    -v /lib/modules:/lib/modules:ro \
    -v /sys/kernel/debug:/sys/kernel/debug:ro \
    daemon1024/minotaur:latest
```