// +build ignore

#include <linux/version.h>
#include <linux/nsproxy.h>
#include <linux/pid_namespace.h>
#include <linux/bpf.h>
#include <bpf_helpers.h>

char LICENSE[] SEC("license") = "Dual BSD/GPL";

struct bpf_map_def SEC("maps") kprobe_map = {
	.type        = BPF_MAP_TYPE_HASH,
	.key_size    = sizeof(u32),
	.value_size  = sizeof(u32),
	.max_entries = 10240,
};

#define READ_KERN(ptr)                                                  \
    ({                                                                  \
        typeof(ptr) _val;                                               \
        __builtin_memset((void *)&_val, 0, sizeof(_val));               \
        bpf_probe_read((void *)&_val, sizeof(_val), &ptr);              \
        _val;                                                           \
    })

static __always_inline u32 get_task_ns_pid(struct task_struct *task)
{
    struct nsproxy *namespaceproxy = READ_KERN(task->nsproxy);
    struct pid_namespace *pid_ns_children = READ_KERN(namespaceproxy->pid_ns_for_children);
    unsigned int level = READ_KERN(pid_ns_children->level);

#if LINUX_VERSION_CODE < KERNEL_VERSION(4, 19, 0)
    struct pid *tpid = READ_KERN(task->pids[PIDTYPE_PID].pid);
#else
    struct pid *tpid = READ_KERN(task->thread_pid);
#endif
    return READ_KERN(tpid->numbers[level].nr);
}

SEC("kprobe/sys_execve")
int kprobe_execve() {

  struct task_struct *task = (struct task_struct *)bpf_get_current_task();

  // u32 key = get_task_pid_ns_id(task);
  u32 key = 1;
  u32 val = get_task_ns_pid(task);
  // u32 val = 1;



	bpf_map_update_elem(&kprobe_map, &key, &val, BPF_ANY);


	return 0;
}