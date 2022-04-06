//go:build linux
// +build linux

package main

import (
	"log"
	"time"

	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/rlimit"
)

const mapKey uint32 = 1

func main() {
	// Allow the current process to lock memory for eBPF resources.
	if err := rlimit.RemoveMemlock(); err != nil {
		log.Fatal(err)
	}

	// Load pre-compiled programs and maps into the kernel.
	objs, err := ebpf.LoadCollection("minotaur.bpf.o")
	if err != nil {
		log.Fatalf("loading objects: %v", err)
	}
	defer objs.Close()

	fn := "sys_execve"

	kp, err := link.Kprobe(fn, objs.Programs["kprobe_execve"])
	if err != nil {
		log.Fatalf("opening kprobe: %s", err)
	}
	defer kp.Close()

	// Read loop reporting the total amount of times the kernel
	// function was entered, once per second.
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	log.Println("Waiting for events..")

	for range ticker.C {
		var value uint32
		if err := objs.Maps["kprobe_map"].Lookup(mapKey, &value); err != nil {
			log.Fatalf("reading map: %v", err)
		}
		log.Printf("%s called in ns pid %d\n", fn, value)
	}
}
