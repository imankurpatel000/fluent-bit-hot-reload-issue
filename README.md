# Overview
This repository contains the required files to replicate the issue that happens when hot reloading fluent-bit while using external Go output plugin.

# Steps to reproduce
1. Clone this repository
2. Run `make` to build the Go output plugin. This will generate `bin/out_multiinstance.so` and `bin/out_multiinstance.h` file. The code for the Go output plugin in `out.go` is a straight up copy of https://github.com/fluent/fluent-bit-go/blob/master/examples/out_multiinstance/out.go with the actual flush processing commented to keep the stdout cleaner.
3. Run `docker-compose up` to start fluent-bit with the Go output plugin along with a log generating container.
4. Wait for some time to let fluent-bit start processing logs and you will see output like below:
    ```log
    fluent-bit-1     | 2024/12/16 15:30:17 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:30:18 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:30:18 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:30:18 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:30:19 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:30:19 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:30:19 [multiinstance] Flush called for id: dummy_metrics
    ```
5. In another terminal, run the following command to Hot reload fluent-bit:
    ```bash
    curl -X POST -d '{}' localhost:2020/api/v2/reload
    ```
6. Once you run the above command, you will start seeing the following output in the fluent-bit logs:
    ```log
    fluent-bit-1     | 2024/12/16 15:31:29 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:31:29 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:31:29 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | [2024/12/16 15:31:30] [engine] caught signal (SIGHUP)
    fluent-bit-1     | [2024/12/16 15:31:30] [ info] reloading instance pid=1 tid=0xffffbea19020
    fluent-bit-1     | [2024/12/16 15:31:30] [ info] [reload] slist externals /etc/out_multiinstance.so
    fluent-bit-1     | 2024/12/16 15:31:30 [multiinstance] Register called
    fluent-bit-1     | [2024/12/16 15:31:30] [ info] [reload] stop everything of the old context
    fluent-bit-1     | [2024/12/16 15:31:30] [ warn] [engine] service will shutdown when all remaining tasks are flushed
    fluent-bit-1     | [2024/12/16 15:31:30] [ info] [input] pausing fluent-tail-input
    fluent-bit-1     | [2024/12/16 15:31:30] [ warn] [engine] failed to flush chunk '1-1734363089.485089671.flb', retry in 1 seconds: task_id=0, input=fluent-tail-input > output=new_alias (out_id=0)
    fluent-bit-1     | [2024/12/16 15:31:30] [ warn] [engine] failed to flush chunk '1-1734363089.485089671.flb', retry in 1 seconds: task_id=0, input=fluent-tail-input > output=new_alias_2 (out_id=1)
    fluent-bit-1     | [2024/12/16 15:31:30] [ warn] [engine] failed to flush chunk '1-1734363089.485089671.flb', retry in 1 seconds: task_id=0, input=fluent-tail-input > output=new_alias_3 (out_id=2)
    fluent-bit-1     | [2024/12/16 15:31:30] [ info] [task] tail/fluent-tail-input has 1 pending task(s):
    fluent-bit-1     | [2024/12/16 15:31:30] [ info] [task]   task_id=0 still running on route(s): multiinstance/new_alias multiinstance/new_alias_2 multiinstance/new_alias_3 
    fluent-bit-1     | [2024/12/16 15:31:30] [ info] [input] pausing fluent-tail-input
    fluent-bit-1     | [2024/12/16 15:31:30] [ warn] [engine] failed to flush chunk '1-1734363089.485089671.flb', retry in 1 seconds: task_id=0, input=fluent-tail-input > output=new_alias (out_id=0)
    ```
7. After a few minutes, once the retries are exhausted you will see the following in the logs:
    ```log  
    fluent-bit-1     | [2024/12/16 15:33:02] [ info] [input] pausing fluent-tail-input
    fluent-bit-1     | [2024/12/16 15:33:02] [error] [engine] chunk '1-1734363172.486514292.flb' cannot be retried: task_id=0, input=fluent-tail-input > output=new_alias
    fluent-bit-1     | [2024/12/16 15:33:02] [error] [engine] chunk '1-1734363172.486514292.flb' cannot be retried: task_id=0, input=fluent-tail-input > output=new_alias_2
    fluent-bit-1     | [2024/12/16 15:33:02] [error] [engine] chunk '1-1734363172.486514292.flb' cannot be retried: task_id=0, input=fluent-tail-input > output=new_alias_3
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [engine] service has stopped (0 pending tasks)
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [input] pausing fluent-tail-input
    fluent-bit-1     | 2024/12/16 15:33:03 [multiinstance] Exit called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:33:03 [multiinstance] Exit called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:33:03 [multiinstance] Exit called for id: dummy_metrics
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [input:tail:fluent-tail-input] inotify_fs_remove(): inode=58 watch_fd=1
    fluent-bit-1     | 2024/12/16 15:33:03 [multiinstance] Unregister called
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [reload] start everything
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [fluent bit] version=3.2.2, commit=a59c867924, pid=1
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [storage] ver=1.5.2, type=memory, sync=normal, checksum=off, max_chunks_up=128
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [simd    ] disabled
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [cmetrics] version=0.9.9
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [ctraces ] version=0.5.7
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [input:tail:fluent-tail-input] initializing
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [input:tail:fluent-tail-input] storage_strategy='memory' (memory only)
    fluent-bit-1     | [2024/12/16 15:33:03] [error] [input:tail:fluent-tail-input] parser 'docker' is not registered
    fluent-bit-1     | 2024/12/16 15:33:03 [multiinstance] id = "dummy_metrics"
    fluent-bit-1     | 2024/12/16 15:33:03 [multiinstance] id = "dummy_metrics"
    fluent-bit-1     | 2024/12/16 15:33:03 [multiinstance] id = "dummy_metrics"
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [http_server] listen iface=0.0.0.0 tcp_port=2020
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [sp] stream processor started
    fluent-bit-1     | [2024/12/16 15:33:03] [ info] [input:tail:fluent-tail-input] inotify_fs_add(): inode=58 watch_fd=1 name=/var/log/test.log
    fluent-bit-1     | 2024/12/16 15:33:04 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:33:04 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:33:04 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:33:05 [multiinstance] Flush called for id: dummy_metrics
    fluent-bit-1     | 2024/12/16 15:33:05 [multiinstance] Flush called for id: dummy_metrics
    ```
8. You will see that the Go output plugin is not flushing the data after the hot reload. Chunks/tasks that were pending during hot reload are completely lost.
9. If you don't see the `failed to flush chunk` errors then repeat step 5 a few times to reload the fluent-bit again as sometimes it can happen that during a hot reload there were no pending chunks/tasks waiting to be flushed.