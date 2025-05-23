const std = @import("std");

const TlsEngine = enum { none, mbed, wolf };

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const advanced = b.option(
        bool,
        "advanced",
        "show advanced options",
    ) orelse false;

    const link = b.option(
        std.builtin.LinkMode,
        "link",
        "link mode of library",
    ) orelse .static;

    const elide_deprecated = b.option(
        bool,
        "NNG_ELIDE_DEPRECATED",
        "Elide deprecated functionality.",
    ) orelse false;

    const enable_stats = if (advanced) b.option(
        bool,
        "NNG_ENABLE_STATS",
        "Enable statistics.",
    ) orelse true else true;

    // Protocols.
    const proto_bus0 = if (advanced) b.option(
        bool,
        "NNG_PROTO_BUS0",
        "Enable BUSv0 protocol.",
    ) orelse true else true;
    const proto_pair0 = if (advanced) b.option(
        bool,
        "NNG_PROTO_PAIR0",
        "Enable PAIRv0 protocol.",
    ) orelse true else true;
    const proto_pair1 = if (advanced) b.option(
        bool,
        "NNG_PROTO_PAIR1",
        "Enable PAIRv1 protocol.",
    ) orelse true else true;
    const proto_push0 = if (advanced) b.option(
        bool,
        "NNG_PROTO_PUSH0",
        "Enable PUSHv0 protocol.",
    ) orelse true else true;
    const proto_pull0 = if (advanced) b.option(
        bool,
        "NNG_PROTO_PULL0",
        "Enable PULLv0 protocol.",
    ) orelse true else true;
    const proto_pub0 = if (advanced) b.option(
        bool,
        "NNG_PROTO_PUB0",
        "Enable PUBv0 protocol.",
    ) orelse true else true;
    const proto_sub0 = if (advanced) b.option(
        bool,
        "NNG_PROTO_SUB0",
        "Enable SUBv0 protocol",
    ) orelse true else true;
    const proto_req0 = if (advanced) b.option(
        bool,
        "NNG_PROTO_REQ0",
        "Enable REQv0 protocol.",
    ) orelse true else true;
    const proto_rep0 = if (advanced) b.option(
        bool,
        "NNG_PROTO_REP0",
        "Enable REPv0 protocol.",
    ) orelse true else true;
    const proto_respondent0 = if (advanced) b.option(
        bool,
        "NNG_PROTO_RESPONDENT0",
        "Enable RESPONDENTv0 protocol.",
    ) orelse true else true;
    const proto_surveyor0 = if (advanced) b.option(
        bool,
        "NNG_PROTO_SURVEYOR0",
        "Enable SURVEYOR0 protocol.",
    ) orelse true else true;

    // TLS support.
    const enable_tls = b.option(
        bool,
        "NNG_ENABLE_TLS",
        "Enable TLS support.",
    ) orelse false;
    const tls_engine: TlsEngine = b.option(
        TlsEngine,
        "NNG_TLS_ENGINE",
        "TLS engine to use.",
    ) orelse if (enable_tls) .mbed else .none;

    // HTTP API support.
    const enable_http = if (advanced) b.option(
        bool,
        "NNG_ENABLE_HTTP",
        "Enable HTTP API.",
    ) orelse true else true;
    const enable_ipv6 = if (advanced) b.option(
        bool,
        "NNG_ENABLE_IPV6",
        "Enable IPv6.",
    ) orelse true else true;

    // Transport Options.
    const transport_inproc = if (advanced) b.option(
        bool,
        "NNG_TRANSPORT_INPROC",
        "Enable inproc transport.",
    ) orelse true else true;
    const transport_ipc = if (advanced) b.option(
        bool,
        "NNG_TRANSPORT_IPC",
        "Enable IPC transport.",
    ) orelse true else true;
    const transport_tcp = if (advanced) b.option(
        bool,
        "NNG_TRANSPORT_TCP",
        "Enable TCP transport.",
    ) orelse true else true;
    const transport_tls = if (advanced) b.option(
        bool,
        "NNG_TRANSPORT_TLS",
        "Enable TLS transport.",
    ) orelse true else true;
    const transport_ws = if (advanced) b.option(
        bool,
        "NNG_TRANSPORT_WS",
        "Enable WebSocket transport.",
    ) orelse true else true;
    const transport_wss = if (advanced) (if (enable_tls) b.option(
        bool,
        "NNG_TRANSPORT_WSS",
        "Enable WSS transport.",
    ) orelse true else false) else enable_tls;
    const transport_fdc = if (advanced) b.option(
        bool,
        "NNG_TRANSPORT_FDC",
        "Enable File Descriptor transport (EXPERIMENTAL)",
    ) orelse true else true;
    const transport_udp = if (advanced) b.option(
        bool,
        "NNG_TRANSPORT_UDP",
        "Enable UDP transport (EXPERIMENTAL)",
    ) orelse true else true;

    const setstacksize = if (target.result.os.tag != .windows)
        (if (advanced) b.option(
            bool,
            "NNG_SETSTACKSIZE",
            "Use rlimit for thread stack size",
        ) orelse false else false)
    else
        false;

    const resolv_concurrency = if (advanced) b.option(
        u16,
        "NNG_RESOLV_CONCURRENCY",
        "Resolver (DNS) concurrency.",
    ) orelse 4 else 4;

    const num_taskq_threads = if (advanced) b.option(
        u16,
        "NNG_NUM_TASKQ_THREADS",
        "Fixed number of task threads, 0 for automatic",
    ) orelse 0 else 0;

    const max_taskq_threads = if (advanced) b.option(
        u16,
        "NNG_MAX_TASKQ_THREADS",
        "Upper bound on task threads, 0 for no limit",
    ) orelse 16 else 16;

    // Expire threads. This runs the timeout handling, and having more of them
    // reduces contention on the common locks used for aio expiration.
    const num_expire_threads = if (advanced) b.option(
        u16,
        "NNG_NUM_EXPIRE_THREADS",
        "Fixed number of expire threads, 0 for automatic",
    ) orelse 0 else 0;

    const max_expire_threads = if (advanced) b.option(
        u16,
        "NNG_MAX_EXPIRE_THREADS",
        "Upper bound on expire threads, 0 for no limit",
    ) orelse 8 else 8;

    // Poller threads. These threads run the pollers. This is mostly used on
    // Windows right now, as the POSIX platforms use a single threaded poller.
    const num_poller_threads = if (advanced) b.option(
        u16,
        "NNG_NUM_POLLER_THREADS",
        "Fixed number of I/O poller threads, 0 for automatic",
    ) orelse 0 else 0;

    const max_poller_threads = if (advanced) b.option(
        u16,
        "NNG_MAX_POLLER_THREADS",
        "Upper bound on I/O poller threads, 0 for no limit",
    ) orelse 8 else 8;

    const PollQPoller = enum { auto, ports, kqueue, epoll, poll, select };
    var pollq_poller: PollQPoller = if (target.result.os.tag != .windows)
        (if (advanced) b.option(
            PollQPoller,
            "NNG_POLLQ_POLLER",
            "Poller used for multiplexing I/O",
        ) orelse .auto else .auto)
    else
        undefined;
    if (pollq_poller == .auto) {
        // TODO: Properly auto-detect poller
        pollq_poller = .ports;
    }

    const nng_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const cflags = [_][]const u8{
        "-DNNG_PRIVATE",                                                     if (elide_deprecated) "-DNNG_ELIDE_DEPRECATED" else "",               if (enable_stats) "-DNNG_ENABLE_STATS" else "",                       if (enable_ipv6) "-DNNG_ENABLE_IPV6" else "",                   if (setstacksize) "-DNNG_SETSTACKSIZE" else "",
        try std.fmt.allocPrint(
            allocator,
            "-DNNG_RESOLV_CONCURRENCY={d}",
            .{resolv_concurrency},
        ),
        if (num_taskq_threads > 0) try std.fmt.allocPrint(
            allocator,
            "-DNNG_NUM_TASKQ_THREADS={d}",
            .{num_taskq_threads},
        ) else "",
        if (max_taskq_threads > 0) try std.fmt.allocPrint(
            allocator,
            "-DNNG_MAX_TASKQ_THREADS={d}",
            .{max_taskq_threads},
        ) else "",
        if (num_expire_threads > 0) try std.fmt.allocPrint(
            allocator,
            "-DNNG_NUM_EXPIRE_THREADS={d}",
            .{num_expire_threads},
        ) else "",
        if (max_expire_threads > 0) try std.fmt.allocPrint(
            allocator,
            "-DNNG_MAX_EXPIRE_THREADS={d}",
            .{max_expire_threads},
        ) else "",
        if (num_poller_threads > 0) try std.fmt.allocPrint(
            allocator,
            "-DNNG_NUM_POLLER_THREADS={d}",
            .{num_poller_threads},
        ) else "",
        if (max_poller_threads > 0) try std.fmt.allocPrint(
            allocator,
            "-DNNG_MAX_POLLER_THREADS={d}",
            .{max_poller_threads},
        ) else "",
        if (target.result.cpu.arch.endian() == .big)
            "-DNNG_BIG_ENDIAN=1"
        else
            "-DNNG_LITTLE_ENDIAN=1",
        if (target.result.os.tag == .linux) "-DNNG_PLATFORM_POSIX" else "",  if (target.result.os.tag == .linux) "-DNNG_PLATFORM_LINUX" else "",   if (target.result.os.tag == .linux) "-DNNG_USE_EVENTFD" else "",
        if (target.result.os.tag == .linux)
            "-DNNG_HAVE_ABSTRACT_SOCKETS"
        else
            "",
        if (target.result.os.tag.isDarwin()) "-DNNG_PLATFORM_POSIX" else "", if (target.result.os.tag.isDarwin()) "-DNNG_PLATFORM_DARWIN" else "", if (target.result.os.tag == .freebsd) "-DNNG_PLATFORM_POSIX" else "",
        if (target.result.os.tag == .freebsd)
            "-DNNG_PLATFORM_FREEBSD"
        else
            "",
        if (target.result.os.tag == .netbsd) "-DNNG_PLATFORM_POSIX" else "", if (target.result.os.tag == .netbsd) "-DNNG_PLATFORM_NETBSD" else "", if (target.result.os.tag == .openbsd) "-DNNG_PLATFORM_POSIX" else "",
        if (target.result.os.tag == .openbsd)
            "-DNNG_PLATFORM_OPENBSD"
        else
            "",
        if (target.result.os.tag == .windows)
            "-DNNG_PLATFORM_WINDOWS"
        else
            "",
        if (target.result.os.tag == .windows)
            "-D_CRT_SECURE_NO_WARNINGS"
        else
            "",
        if (target.result.os.tag == .windows)
            "-D_CRT_RAND_S"
        else
            "",
        if (target.result.os.tag == .windows)
            "-D_WIN32_WINNT=0x0600"
        else
            "",
        if (enable_tls) "-DNNG_SUPP_TLS" else "",                            if (target.result.os.tag != .windows) "-D_GNU_SOURCE" else "",        if (target.result.os.tag != .windows) "-D_REENTRANT" else "",         if (target.result.os.tag != .windows) "-D_THREAD_SAFE" else "",
        if (target.result.os.tag != .windows)
            "-D_POSIX_PTHREAD_SEMANTICS"
        else
            "",
        if (target.result.os.tag != .windows) switch (pollq_poller) {
            .ports => "-DNNG_POLLQ_PORTS",
            .kqueue => "-DNNG_POLLQ_KQUEUE",
            .epoll => "-DNNG_POLLQ_EPOLL",
            .poll => "-DNNG_POLLQ_POLL",
            .select => "-DNNG_POLLQ_SELECT",
            .auto => unreachable,
        } else "",

        if (proto_bus0) "-DNNG_HAVE_BUS0" else "",                           if (proto_pair0) "-DNNG_HAVE_PAIR0" else "",                          if (proto_pair1) "-DNNG_HAVE_PAIR1" else "",                          if (proto_push0) "-DNNG_HAVE_PUSH0" else "",                    if (proto_pull0) "-DNNG_HAVE_PULL0" else "",
        if (proto_pub0) "-DNNG_HAVE_PUB0" else "",                           if (proto_sub0) "-DNNG_HAVE_SUB0" else "",                            if (proto_req0) "-DNNG_HAVE_REQ0" else "",                            if (proto_rep0) "-DNNG_HAVE_REP0" else "",                      if (proto_surveyor0) "-DNNG_HAVE_SURVEYOR0" else "",
        if (proto_respondent0) "-DNNG_HAVE_RESPONDENT0" else "",             if (transport_fdc) "-DNNG_TRANSPORT_FDC" else "",                     if (transport_inproc) "-DNNG_TRANSPORT_INPROC" else "",               if (transport_ipc) "-DNNG_TRANSPORT_IPC" else "",               if (transport_tcp) "-DNNG_TRANSPORT_TCP" else "",
        if (transport_tls) "-DNNG_TRANSPORT_TLS" else "",                    if (transport_udp) "-DNNG_TRANSPORT_UDP" else "",                     if (transport_ws) "-DNNG_TRANSPORT_WS" else "",                       if (transport_wss) "-DNNG_TRANSPORT_WSS" else "",               if (enable_http) "-DNNG_SUPP_HTTP" else "",
        if (tls_engine == .mbed)
            "-DNNG_TLS_ENGINE_INIT=nng_tls_engine_init_mbed"
        else
            "",
        if (tls_engine == .mbed)
            "-DNNG_TLS_ENGINE_FINI=nng_tls_engine_fini_mbed"
        else
            "",
        if (tls_engine == .mbed) "-DNNG_SUPP_TLS" else "",                   if (tls_engine == .mbed) "-DNNG_SUPP_TLS_PSK" else "",
        if (tls_engine == .mbed) "-DNNG_TLS_ENGINE_MBEDTLS" else "",
    };

    nng_mod.addCSourceFile(.{
        .file = b.path("src/nng.c"),
        .flags = &cflags,
    });
    nng_mod.addCSourceFile(.{
        .file = b.path("src/nng_legacy.c"),
        .flags = &cflags,
    });

    nng_mod.addIncludePath(b.path("include"));
    nng_mod.addIncludePath(b.path("src"));

    nng_mod.addCSourceFiles(.{
        .files = &.{
            "defs.h",
            "aio.c",
            "aio.h",
            "device.c",
            "device.h",
            "dialer.c",
            "dialer.h",
            "sockfd.c",
            "sockfd.h",
            "file.c",
            "file.h",
            "idhash.c",
            "idhash.h",
            "init.c",
            "init.h",
            "list.c",
            "list.h",
            "listener.c",
            "listener.h",
            "lmq.c",
            "lmq.h",
            "log.c",
            "message.c",
            "message.h",
            "msgqueue.c",
            "msgqueue.h",
            "nng_impl.h",
            "options.c",
            "options.h",
            "pollable.c",
            "pollable.h",
            "panic.c",
            "panic.h",
            "pipe.c",
            "pipe.h",
            "platform.h",
            "protocol.h",
            "reap.c",
            "reap.h",
            "refcnt.c",
            "refcnt.h",
            "sockaddr.c",
            "socket.c",
            "socket.h",
            "sockimpl.h",
            "stats.c",
            "stats.h",
            "stream.c",
            "stream.h",
            "strs.c",
            "strs.h",
            "taskq.c",
            "taskq.h",
            "tcp.c",
            "tcp.h",
            "thread.c",
            "thread.h",
            "url.c",
            "url.h",
        },
        .language = .c,
        .root = b.path("src/core"),
        .flags = &cflags,
    });

    if (target.result.os.tag == .windows) {
        nng_mod.addCSourceFiles(.{
            .files = &.{
                "win_impl.h",
                "win_ipc.h",
                "win_tcp.h",
                "win_clock.c",
                "win_debug.c",
                "win_file.c",
                "win_io.c",
                "win_ipcconn.c",
                "win_ipcdial.c",
                "win_ipclisten.c",
                "win_pipe.c",
                "win_rand.c",
                "win_resolv.c",
                "win_sockaddr.c",
                "win_socketpair.c",
                "win_tcp.c",
                "win_tcpconn.c",
                "win_tcpdial.c",
                "win_tcplisten.c",
                "win_thread.c",
                "win_udp.c",
            },
            .language = .c,
            .root = b.path("src/platform/windows/"),
            .flags = &cflags,
        });
        nng_mod.linkSystemLibrary("ws2_32", .{});
        nng_mod.linkSystemLibrary("mswsock", .{});
        nng_mod.linkSystemLibrary("advapi32", .{});
    } else {
        nng_mod.addCSourceFiles(.{
            .files = &.{
                "posix_impl.h",
                "posix_aio.h",
                "posix_ipc.h",
                "posix_config.h",
                "posix_pollq.h",
                "posix_tcp.h",

                "posix_alloc.c",
                "posix_atomic.c",
                "posix_clock.c",
                "posix_debug.c",
                "posix_file.c",
                "posix_ipcconn.c",
                "posix_ipcdial.c",
                "posix_ipclisten.c",
                "posix_peerid.c",
                "posix_pipe.c",
                "posix_resolv_gai.c",
                "posix_sockaddr.c",
                "posix_socketpair.c",
                "posix_sockfd.c",
                "posix_tcpconn.c",
                "posix_tcpdial.c",
                "posix_tcplisten.c",
                "posix_thread.c",
                "posix_udp.c",
                switch (pollq_poller) {
                    .ports => "posix_pollq_port.c",
                    .kqueue => "posix_pollq_kqueue.c",
                    .epoll => "posix_pollq_epoll.c",
                    .poll => "posix_pollq_poll.c",
                    .select => "posix_pollq_select.c",
                    .auto => unreachable,
                },
                switch (target.result.os.tag) {
                    .linux => "posix_rand_arc4random.c",
                    // TODO: Properly check for random symbols
                    else => "posix_rand_urandom.c",
                },
            },
            .language = .c,
            .root = b.path("src/platform/posix"),
            .flags = &cflags,
        });
        nng_mod.linkSystemLibrary("pthread", .{ .needed = true });
    }

    nng_mod.addCSourceFiles(.{
        .files = &.{
            "protocol.c",
            "transport.c",
            "transport.h",
        },
        .language = .c,
        .root = b.path("src/sp"),
        .flags = &cflags,
    });

    if (proto_bus0) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/protocol/bus0/bus.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (proto_pair0) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/protocol/pair0/pair.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (proto_pair1) {
        nng_mod.addCSourceFiles(.{
            .files = &.{
                "pair.c",
                "pair1_poly.c",
            },
            .language = .c,
            .root = b.path("src/sp/protocol/pair1"),
            .flags = &cflags,
        });
    }
    if (proto_push0) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/protocol/pipeline0/push.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (proto_pull0) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/protocol/pipeline0/pull.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (proto_pub0) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/protocol/pubsub0/pub.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (proto_sub0) {
        nng_mod.addCSourceFiles(.{
            .files = &.{ "sub.c", "xsub.c" },
            .language = .c,
            .root = b.path("src/sp/protocol/pubsub0"),
            .flags = &cflags,
        });
    }
    if (proto_req0) {
        nng_mod.addCSourceFiles(.{
            .files = &.{ "req.c", "xreq.c" },
            .language = .c,
            .root = b.path("src/sp/protocol/reqrep0"),
            .flags = &cflags,
        });
    }
    if (proto_rep0) {
        nng_mod.addCSourceFiles(.{
            .files = &.{ "rep.c", "xrep.c" },
            .language = .c,
            .root = b.path("src/sp/protocol/reqrep0"),
            .flags = &cflags,
        });
    }
    if (proto_surveyor0) {
        nng_mod.addCSourceFiles(.{
            .files = &.{ "survey.c", "xsurvey.c" },
            .language = .c,
            .root = b.path("src/sp/protocol/survey0"),
            .flags = &cflags,
        });
    }
    if (proto_respondent0) {
        nng_mod.addCSourceFiles(.{
            .files = &.{ "respond.c", "xrespond.c" },
            .language = .c,
            .root = b.path("src/sp/protocol/survey0"),
            .flags = &cflags,
        });
    }
    if (transport_fdc) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/transport/socket/sockfd.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (transport_inproc) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/transport/inproc/inproc.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (transport_ipc) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/transport/ipc/ipc.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (transport_tcp) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/transport/tcp/tcp.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (transport_tls) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/transport/tls/tls.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (transport_udp) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/transport/udp/udp.c"),
            .language = .c,
            .flags = &cflags,
        });
    }
    if (transport_ws or transport_wss) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/sp/transport/ws/websocket.c"),
            .language = .c,
            .flags = &cflags,
        });
    }

    if (enable_http) {
        nng_mod.addCSourceFiles(.{
            .files = &.{
                "http_client.c",
                "http_chunk.c",
                "http_conn.c",
                "http_msg.c",
                "http_public.c",
                "http_schemes.c",
                "http_server.c",
            },
            .language = .c,
            .root = b.path("src/supplemental/http"),
            .flags = &cflags,
        });
    }
    if (enable_tls) {
        nng_mod.addCSourceFiles(.{
            .files = &.{
                "tls_common.c",
                "tls_dialer.c",
                "tls_listener.c",
                "tls_stream.c",
                "tls_api.h",
                "tls_engine.h",
            },
            .language = .c,
            .root = b.path("src/supplemental/tls"),
            .flags = &cflags,
        });
    } else {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/supplemental/tls/tls_stubs.c"),
            .language = .c,
            .flags = &cflags,
        });
    }

    if (tls_engine == .mbed) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/supplemental/tls/mbedtls/tls.c"),
            .language = .c,
            .flags = &cflags,
        });
        nng_mod.linkSystemLibrary("mbedtls", .{});
        nng_mod.linkSystemLibrary("mbedcrypto", .{});
        nng_mod.linkSystemLibrary("mbedx509", .{});
    } else if (tls_engine == .wolf) {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/supplemental/tls/wolfssl/wolfssl.c"),
            .language = .c,
            .flags = &cflags,
        });
        nng_mod.linkSystemLibrary("wolfssl", .{});
        // TODO: Check wolfSSL feature support for defines
    }

    if (transport_ws or transport_wss) {
        nng_mod.addCSourceFiles(.{
            .files = &.{
                "base64.c",
                "base64.h",
                "sha1.c",
                "sha1.h",
                "websocket.c",
                "websocket.h",
            },
            .language = .c,
            .root = b.path("src/supplemental/websocket"),
            .flags = &cflags,
        });
    } else {
        nng_mod.addCSourceFile(.{
            .file = b.path("src/supplemental/websocket/stub.c"),
            .language = .c,
            .flags = &cflags,
        });
    }

    const nng_lib = b.addLibrary(.{
        .name = "nng",
        .linkage = link,
        .root_module = nng_mod,
    });
    nng_lib.installHeadersDirectory(b.path("include"), ".", .{});
    b.installArtifact(nng_lib);
}
